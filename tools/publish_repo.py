#!/usr/bin/env python3
"""Publishes a .deb into an existing Sileo (APT) repository checkout.

It only touches what belongs to this package:
  * copies the .deb into <repo>/<debs-dir>/ (and prunes older versions of the SAME package)
  * replaces this package's entry in <repo>/Packages (every other entry is kept byte for byte)
  * rewrites Packages.gz / Packages.bz2 / Packages.xz
  * refreshes the checksum blocks of <repo>/Release (the other lines of Release are kept)

It refuses to run on a signed repository (InRelease / Release.gpg): changing Packages would break the signature.

    python3 tools/publish_repo.py --deb dist/x.deb --repo ./sileo-repo [--debs-dir debs] [--keep 3]
"""
import argparse, bz2, gzip, hashlib, lzma, os, re, subprocess, sys, datetime, shutil

CHECKSUM_FIELDS = ('MD5Sum', 'SHA1', 'SHA256', 'SHA512')
PACKAGES_FILES = ('Packages', 'Packages.gz', 'Packages.bz2', 'Packages.xz')


def die(message):
    print('ERROR: ' + message, file=sys.stderr)
    sys.exit(1)


def digests(path):
    h = {name: hashlib.new(name) for name in ('md5', 'sha1', 'sha256', 'sha512')}
    with open(path, 'rb') as f:
        for chunk in iter(lambda: f.read(1 << 20), b''):
            for x in h.values():
                x.update(chunk)
    return {k: v.hexdigest() for k, v in h.items()}


def control_of(deb):
    try:
        out = subprocess.run(['dpkg-deb', '-f', deb], capture_output=True, text=True, check=True).stdout
    except FileNotFoundError:
        die('dpkg-deb is not installed (apt-get install dpkg, or brew install dpkg)')
    except subprocess.CalledProcessError as e:
        die('cannot read the control file of %s: %s' % (deb, e.stderr.strip()))
    lines = [l for l in out.splitlines() if l.strip() != '']
    fields = {}
    for l in lines:
        if not l.startswith((' ', '\t')) and ':' in l:
            fields[l.split(':', 1)[0]] = l.split(':', 1)[1].strip()
    return lines, fields


def split_stanzas(text):
    """Splits a Packages file into stanzas, keeping each one exactly as written."""
    stanzas, cur = [], []
    for line in text.split('\n'):
        if line.strip() == '':
            if cur:
                stanzas.append('\n'.join(cur))
                cur = []
        else:
            cur.append(line)
    if cur:
        stanzas.append('\n'.join(cur))
    return stanzas


def package_name(stanza):
    m = re.search(r'^Package:\s*(\S+)', stanza, re.M)
    return m.group(1) if m else None


def version_key(version):
    """Rough dpkg-style ordering that is good enough to find the newest of our own versions."""
    return [int(p) if p.isdigit() else p for p in re.split(r'(\d+)', version) if p]


def write_compressed(repo, text):
    data = text.encode('utf-8')
    with open(os.path.join(repo, 'Packages'), 'wb') as f:
        f.write(data)
    with open(os.path.join(repo, 'Packages.gz'), 'wb') as raw:
        with gzip.GzipFile(filename='', mode='wb', fileobj=raw, mtime=0) as gz:
            gz.write(data)
    with open(os.path.join(repo, 'Packages.bz2'), 'wb') as f:
        f.write(bz2.compress(data, 9))
    with open(os.path.join(repo, 'Packages.xz'), 'wb') as f:
        f.write(lzma.compress(data))


def update_release(repo):
    path = os.path.join(repo, 'Release')
    kept, skipping = [], False
    if os.path.exists(path):
        for line in open(path, encoding='utf-8').read().split('\n'):
            name = line.split(':', 1)[0]
            if not line.startswith((' ', '\t')) and name in CHECKSUM_FIELDS:
                skipping = True          # an old checksum block: it is rebuilt below
                continue
            if skipping and line.startswith((' ', '\t')):
                continue
            skipping = False
            if line.strip() != '' and name != 'Date':
                kept.append(line)
    else:
        kept = ['Origin: ClaudeMini repo', 'Label: ClaudeMini repo', 'Suite: stable', 'Version: 1.0',
                'Codename: ios', 'Architectures: iphoneos-arm', 'Components: main',
                'Description: Packages for jailbroken iOS 12']
    kept.append('Date: ' + datetime.datetime.now(datetime.timezone.utc).strftime('%a, %d %b %Y %H:%M:%S UTC'))
    files = [n for n in PACKAGES_FILES if os.path.exists(os.path.join(repo, n))]
    for field, algo in (('MD5Sum', 'md5'), ('SHA1', 'sha1'), ('SHA256', 'sha256'), ('SHA512', 'sha512')):
        kept.append(field + ':')
        for n in files:
            p = os.path.join(repo, n)
            kept.append(' %s %d %s' % (digests(p)[algo], os.path.getsize(p), n))
    open(path, 'w', encoding='utf-8').write('\n'.join(kept) + '\n')


def prune(debs_path, package, keep, current_name):
    pattern = re.compile(r'^' + re.escape(package) + r'_(.+?)_[^_]+\.deb$')
    found = []
    for name in os.listdir(debs_path):
        m = pattern.match(name)
        if m:
            found.append((version_key(m.group(1)), name))
    found.sort()
    removed = []
    for _, name in found[:-keep] if keep > 0 else []:
        if name != current_name:
            os.remove(os.path.join(debs_path, name))
            removed.append(name)
    return removed


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--deb', required=True)
    ap.add_argument('--repo', required=True, help='checkout of the Sileo repository')
    ap.add_argument('--debs-dir', default='debs', help='folder inside the repo that holds the .deb files')
    ap.add_argument('--keep', type=int, default=3, help='how many versions of this package to keep (0 = keep all)')
    args = ap.parse_args()

    if not os.path.isfile(args.deb):
        die('no such file: ' + args.deb)
    if not os.path.isdir(args.repo):
        die('no such folder: ' + args.repo)
    for signed in ('InRelease', 'Release.gpg'):
        if os.path.exists(os.path.join(args.repo, signed)):
            die('this repository is signed (%s found). Updating Packages would break the signature, so nothing was changed.' % signed)
    debs_dir = args.debs_dir.strip('/')
    if debs_dir.startswith('..') or os.path.isabs(args.debs_dir):
        die('--debs-dir must be a folder inside the repository')

    control_lines, fields = control_of(args.deb)
    package, version = fields.get('Package'), fields.get('Version')
    if not package or not version:
        die('the .deb has no Package/Version field')

    target_dir = os.path.join(args.repo, debs_dir) if debs_dir else args.repo
    os.makedirs(target_dir, exist_ok=True)
    deb_name = os.path.basename(args.deb)
    target_deb = os.path.join(target_dir, deb_name)
    shutil.copyfile(args.deb, target_deb)

    d = digests(target_deb)
    filename = (debs_dir + '/' + deb_name) if debs_dir else deb_name
    new_stanza = '\n'.join(control_lines + ['Filename: ' + filename, 'Size: %d' % os.path.getsize(target_deb),
                                            'MD5sum: ' + d['md5'], 'SHA1: ' + d['sha1'], 'SHA256: ' + d['sha256']])

    packages_path = os.path.join(args.repo, 'Packages')
    existing = open(packages_path, encoding='utf-8').read() if os.path.exists(packages_path) else ''
    stanzas = split_stanzas(existing)
    others = [s for s in stanzas if package_name(s) != package]
    replaced = len(stanzas) - len(others)
    new_text = '\n\n'.join(others + [new_stanza]) + '\n\n'

    write_compressed(args.repo, new_text)
    update_release(args.repo)
    removed = prune(target_dir, package, args.keep, deb_name)

    print('published %s %s -> %s/%s' % (package, version, args.repo, filename))
    print('  other packages kept untouched: %d | entries of this package replaced: %d' % (len(others), replaced))
    if removed:
        print('  pruned old versions: ' + ', '.join(removed))


if __name__ == '__main__':
    main()
