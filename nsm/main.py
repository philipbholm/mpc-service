from nsm import Session
from request import DescribeNSM


def main():
    try:
        # Try to open a session with the NSM device
        session = Session.open()
        print("Successfully opened NSM session")

        # Test 1: Get basic NSM information
        response = session.send(DescribeNSM())
        if response.describe_nsm:
            print(
                f"NSM Version: {response.describe_nsm.version_major}."
                f"{response.describe_nsm.version_minor}."
                f"{response.describe_nsm.version_patch}"
            )
            print(f"Module ID: {response.describe_nsm.module_id}")
            print(f"Max PCRs: {response.describe_nsm.max_pcrs}")
            print(f"Digest type: {response.describe_nsm.digest}")

        # Test 2: Try to get random bytes
        random_buffer = bytearray(64)  # Request 64 random bytes
        bytes_read = session.read(random_buffer)
        print(f"Successfully read {bytes_read} random bytes: {random_buffer.hex()}")

        # Clean up
        session.close()
        print("Successfully closed NSM session")

    except OSError as e:
        print(f"Failed to access NSM device: {e}")
        print("This might indicate we're not running inside a Nitro Enclave")
    except Exception as e:
        print(f"Error during NSM operations: {e}")


if __name__ == "__main__":
    main()
