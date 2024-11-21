import socket
import sys

# VSOCK constants
PORT = 8000
AF_VSOCK = 40


def start_server(port):
    # Create VSOCK socket
    server_socket = socket.socket(AF_VSOCK, socket.SOCK_STREAM)

    try:
        # Bind to port and listen for any CID
        server_socket.bind((socket.VMADDR_CID_ANY, port))
        server_socket.listen(1)
        print(f"[enclave] Server listening on VSOCK port {port}")

        while True:
            # Accept incoming connection
            client_socket, client_address = server_socket.accept()
            print(f"[enclave] Accepted connection from CID: {client_address[0]}")

            try:
                # Receive and print data
                while True:
                    data = client_socket.recv(4096)
                    if not data:
                        break

                    # Decode and print the received data
                    print(f"[enclave] Received: {data.decode('utf-8')}")

                    # Echo back to client
                    client_socket.sendall(b"Message received by enclave\n")

            except Exception as e:
                print(f"[enclave] Error handling client: {e}")
            finally:
                client_socket.close()
                print("[enclave] Client connection closed")

    except Exception as e:
        print(f"[enclave] Server error: {e}")
        sys.exit(1)
    finally:
        server_socket.close()


if __name__ == "__main__":
    try:
        start_server(PORT)
    except KeyboardInterrupt:
        print("[enclave] Server stopped")
    except Exception as e:
        print(f"[enclave] Failed to start server: {e}")
