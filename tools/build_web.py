#!/usr/bin/env python3
"""Rebuilds app/Resources/web/vendor.js and vendor.css (markdown-it + highlight.js + KaTeX, lowered to ES2018).

The generated files are committed, so the app build does NOT need this script. Run it only to update the libraries:
    NPM_MODULES=/path/to/node_modules python3 tools/build_web.py
Needs node_modules with: markdown-it, highlight.js, katex, esbuild.
"""
import base64, os, re, subprocess, sys, tempfile, pathlib

NM = pathlib.Path(os.environ.get('NPM_MODULES', '/opt/npm-tools/node_modules'))
OUT = pathlib.Path(__file__).resolve().parent.parent / 'app' / 'Resources' / 'web'
ESB = str(NM / 'esbuild' / 'bin' / 'esbuild')

# KaTeX fonts embedded in the CSS (the page is loaded from a string, so relative font URLs would not resolve).
KEEP_FONTS = ['Main-Regular', 'Main-Bold', 'Main-Italic', 'Main-BoldItalic', 'Math-Italic', 'Math-BoldItalic',
              'AMS-Regular', 'Size1-Regular', 'Size2-Regular', 'Size3-Regular', 'Size4-Regular',
              'SansSerif-Regular', 'Caligraphic-Regular', 'Typewriter-Regular']
EXTRA_LANGS = ['delphi', 'latex', 'matlab']   # delphi.js also answers to the aliases pascal, pas, dpr, dfm; LaTeX and MATLAB are not in highlight.js "common"

def esbuild(*args):
    r = subprocess.run([ESB, *args, '--log-level=error'], capture_output=True, text=True)
    if r.returncode: sys.exit('esbuild failed:\n' + r.stderr)

def lowered(path):
    with tempfile.NamedTemporaryFile(suffix='.js', delete=False) as t: out = t.name
    esbuild(str(path), '--target=es2018', '--outfile=' + out)
    s = open(out, encoding='utf-8').read(); os.unlink(out); return s

def hljs_bundle():
    entry = ["var hljs = require(%r);" % str(NM / 'highlight.js/lib/common.js')]
    for lang in EXTRA_LANGS:
        entry.append("hljs.registerLanguage(%r, require(%r));" % (lang, str(NM / ('highlight.js/lib/languages/%s.js' % lang))))
    entry.append("window.hljs = hljs;")
    with tempfile.TemporaryDirectory() as d:
        ep, out = os.path.join(d, 'entry.js'), os.path.join(d, 'out.js')
        open(ep, 'w').write('\n'.join(entry))
        esbuild(ep, '--bundle', '--minify', '--target=es2018', '--format=iife', '--outfile=' + out)
        return open(out, encoding='utf-8').read()

def strip_maps(s): return re.sub(r'//# sourceMappingURL=.*', '', s)

def make_js():
    parts = [lowered(NM / 'markdown-it/dist/markdown-it.min.js'), hljs_bundle(), lowered(NM / 'katex/dist/katex.min.js')]
    js = ';\n'.join(strip_maps(p).strip() for p in parts) + ';\n'
    # The libraries are inlined in a <script> element: these two sequences would end/alter it.
    js = js.replace('</script', '<\\/script').replace('<!--', '<\\!--')
    return js

def make_css():
    css = open(NM / 'katex/dist/katex.min.css', encoding='utf-8').read()
    blocks = re.findall(r'@font-face\{[^}]*\}', css)
    for b in blocks:
        m = re.search(r'url\(fonts/KaTeX_([A-Za-z0-9-]+)\.woff2\)', b)
        if m and m.group(1) in KEEP_FONTS:
            data = base64.b64encode((NM / 'katex/dist/fonts' / ('KaTeX_%s.woff2' % m.group(1))).read_bytes()).decode()
            head = re.match(r'(@font-face\{.*?)src:', b, re.S).group(1)
            css = css.replace(b, head + 'src:url(data:font/woff2;base64,%s) format("woff2")}' % data)
        else:
            css = css.replace(b, '')
    assert 'url(fonts/' not in css, 'a font URL was left behind'
    return css

if __name__ == '__main__':
    js, css = make_js(), make_css()
    (OUT / 'vendor.js').write_text(js, encoding='utf-8'); (OUT / 'vendor.css').write_text(css, encoding='utf-8')
    print('vendor.js  %7.1f KB' % (len(js.encode()) / 1024)); print('vendor.css %7.1f KB' % (len(css.encode()) / 1024))
