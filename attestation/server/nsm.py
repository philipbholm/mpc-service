import Crypto
import libnsm


class NSMClient:
    def __init__(self):
        self._nsm_fd = libnsm.nsm_lib_init()
        self._nsm_random_function = lambda num_bytes: libnsm.nsm_get_random(
            self._nsm_fd, num_bytes
        )
        self._monkey_patch_crypto(self._nsm_random_function)
        self._rsa_key = Crypto.PublicKey.RSA.generate(2048)
        self._public_key = self._rsa_key.publickey().export_key("DER")
        print(f"Created rsa key pair: {self._rsa_key}")
        print(f"Created DER encoded public key: {self._public_key}")


    def get_attestation_document(self):
        # TODO: Add nonce
        # Can't use the forked nsm-api since it does not support nonce
        # Try to use aws-nitro-enclaves-nsm-api or nitrite from python
        # Or rewrite the nitrite library in python
        return libnsm.nsm_get_attestation_doc(
            self._nsm_fd,
            self._public_key,
            len(self._public_key),
        )

    def decrypt(self, ciphertext):
        cipher = Crypto.Cipher.PKCS1_OAEP.new(self._rsa_key)
        plaintext = cipher.decrypt(ciphertext)  # Add try/catch
        return plaintext.decode()

    @classmethod
    def _monkey_patch_crypto(cls, nsm_random_function):
        Crypto.Random.get_random_bytes = nsm_random_function

        def new_random_read(self, num_bytes):
            return nsm_random_function(num_bytes)

        Crypto.Random._UrandomRNG.read = new_random_read
