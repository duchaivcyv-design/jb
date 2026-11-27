#!/usr/bin/env python3
"""Encrypts a developer build so that only people who know the developer password can use it.

usage: DEV_UPDATE_PASSWORD=... encrypt_dev.py <input> <output.enc>

format: "CMDEV1" | salt(16) | iv(16) | AES-256-CBC(PKCS7) | HMAC-SHA256(32)
keys:   PBKDF2-HMAC-SHA256(password, salt, 250000) -> 64 bytes: AES key, MAC key
tag:    HMAC-SHA256(macKey, "CMDEV1" | salt | iv | ciphertext)      (encrypt-then-MAC)
The password is read from the environment only (never from argv, never printed). Must match src/DevAccess.m.
"""
import hashlib, hmac, os, subprocess, sys

ROUNDS = 250000
MAGIC = b"CMDEV1"

def main():
    if len(sys.argv) != 3:
        sys.exit(__doc__)
    password = os.environ.get("DEV_UPDATE_PASSWORD", "").encode("utf-8")
    if not password:
        sys.exit("DEV_UPDATE_PASSWORD is not set")
    salt, iv = os.urandom(16), os.urandom(16)
    keys = hashlib.pbkdf2_hmac("sha256", password, salt, ROUNDS, 64)
    enc_key, mac_key = keys[:32], keys[32:]
    with open(sys.argv[1], "rb") as f:
        data = f.read()
    # The AES key is handed to openssl on its command line; on a CI runner nobody else can read the process list.
    ct = subprocess.run(["openssl", "enc", "-aes-256-cbc", "-K", enc_key.hex(), "-iv", iv.hex()],
                        input=data, capture_output=True, check=True).stdout
    body = MAGIC + salt + iv + ct
    tag = hmac.new(mac_key, body, hashlib.sha256).digest()
    with open(sys.argv[2], "wb") as f:
        f.write(body + tag)

main()
