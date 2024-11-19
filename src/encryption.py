import io
import os
import tarfile

from cryptography.hazmat.primitives.ciphers.aead import AESGCM

# Might have to encrypt the data key and add it to the package
def encrypt_directory(path):
    buffer = io.BytesIO()
    with tarfile.open(fileobj=buffer, mode="w:gz") as tar:
        tar.add(path, arcname="")
    data = buffer.getvalue()

    nonce = os.urandom(12)
    key = AESGCM.generate_key(bit_length=256)
    aesgcm = AESGCM(key)

    encrypted_data = aesgcm.encrypt(nonce, data, None)

    return nonce + encrypted_data, key


def decrypt_directory(encrypted_package, key, output_path="tmp"):
    nonce = encrypted_package[:16]
    encrypted_data = encrypted_package[16:]
    aesgcm = AESGCM(key)

    try:
        decrypted_data = aesgcm.decrypt(nonce, encrypted_data, None)
        buffer = io.BytesIO(decrypted_data)
        with tarfile.open(fileobj=buffer, mode="r:gz") as tar:
            tar.extractall(path=output_path)
    except Exception:
        raise ValueError("Unable to decrypt")
