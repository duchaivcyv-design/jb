#!/usr/bin/env python3
"""Decrypts a file made by encrypt_dev.py (developer builds and the source archive).

usage: python decrypt_dev.py <input.enc> [output]
The password is asked for on the keyboard (or taken from DEV_UPDATE_PASSWORD). It is never written anywhere.
Needs either `openssl` on the PATH or the Python package `cryptography` (pip install cryptography).
format: "CMDEV1" | salt(16) | iv(16) | AES-256-CBC(PKCS7) | HMAC-SHA256(32)   (see encrypt_dev.py)
"""
import getpass, hashlib, hmac, os, subprocess, sys

ROUNDS = 250000
MAGIC = b"CMDEV1"

def aes_cbc_decrypt(key, iv, data):
    try:
        return subprocess.run(["openssl", "enc", "-d", "-aes-256-cbc", "-K", key.hex(), "-iv", iv.hex()],
                              input=data, capture_output=True, check=True).stdout
    except (FileNotFoundError, subprocess.CalledProcessError):
        pass
    try:
        from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
        from cryptography.hazmat.primitives import padding
    except ImportError:
        sys.exit("Install openssl or run: pip install cryptography")
    dec = Cipher(algorithms.AES(key), modes.CBC(iv)).decryptor()
    padded = dec.update(data) + dec.finalize()
    unpad = padding.PKCS7(128).unpadder()
    return unpad.update(padded) + unpad.finalize()

def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    src = sys.argv[1]
    dst = sys.argv[2] if len(sys.argv) == 3 else (src[:-4] if src.endswith(".enc") else src + ".out")
    password = (os.environ.get("DEV_UPDATE_PASSWORD") or getpass.getpass("Developer password: ")).encode("utf-8")
    blob = open(src, "rb").read()
    if len(blob) < len(MAGIC) + 16 + 16 + 16 + 32 or not blob.startswith(MAGIC):
        sys.exit("Not an encrypted developer file.")
    salt, iv = blob[6:22], blob[22:38]
    body, tag = blob[:-32], blob[-32:]
    keys = hashlib.pbkdf2_hmac("sha256", password, salt, ROUNDS, 64)
    if not hmac.compare_digest(hmac.new(keys[32:], body, hashlib.sha256).digest(), tag):
        sys.exit("Wrong password or the file was modified.")
    open(dst, "wb").write(aes_cbc_decrypt(keys[:32], iv, body[38:]))
    print("Saved", dst)

main()
