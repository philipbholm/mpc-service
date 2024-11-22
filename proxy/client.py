import ssl
import socket

EC2_IP = "3.66.27.135"
EC2_PORT = 8443


def create_secure_connection(host, port):
    ssl_context = ssl.create_default_context(ssl.Purpose.CLIENT_AUTH)
    ssl_context.check_hostname = False
    ssl_context.verify_mode = ssl.CERT_NONE
    try:
        with socket.socket(
            socket.AF_INET, socket.SOCK_STREAM
        ) as client_socket, ssl_context.wrap_socket(
            client_socket, server_hostname=host
        ) as secure_socket:
            secure_socket.connect((host, port))
            message = "Hello Secure Server!"
            secure_socket.send(message.encode("utf-8"))
            response = secure_socket.recv(1024).decode("utf-8")
            print(f"Server response: {response}")

    except ConnectionRefusedError:
        print(f"Connection refused by {host}:{port}")
    except socket.timeout:
        print("Connection timed out")
    except socket.gaierror:
        print(f"Could not resolve hostname: {host}")
    except ConnectionResetError:
        print("Connection was reset by the server")
    except ssl.SSLError as ssl_err:
        print(f"SSL error occurred: {ssl_err}")
    except ssl.CertificateError as cert_err:
        print(f"Certificate verification failed: {cert_err}")
    except Exception as e:
        print(f"An unexpected error occurred: {e}")


if __name__ == "__main__":
    create_secure_connection(EC2_IP, EC2_PORT)
