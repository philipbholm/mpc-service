import select
import socket
import sys
import threading


class Proxy:
    def __init__(self, listen_port: int, forward_cid: int, forward_port: int):
        self._listen_port = listen_port
        self._forward_cid = forward_cid
        self._forward_port = forward_port
        self.server_socket = None

    def start(self):
        try:
            self.server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            self.server_socket.bind(("0.0.0.0", self._listen_port))
            self.server_socket.listen(50)
            while True:
                try:
                    client_socket, client_address = self.server_socket.accept()
                    client_handler = threading.Thread(
                        target=self._handle_client, args=(client_socket, client_address)
                    )
                    client_handler.daemon = True
                    client_handler.start()
                except socket.error as e:
                    print(f"[proxy] Failed to accept client: {e}")
        except Exception as e:
            print(f"[proxy] Failed to start server: {e}")
            sys.exit(1)

    def _handle_client(
        self, client_socket: socket.socket, client_address: tuple[str, int]
    ):
        forward_socket = None
        try:
            forward_socket = socket.socket(socket.AF_VSOCK, socket.SOCK_STREAM)
            forward_socket.connect((self._forward_cid, self._forward_port))
            client_to_server = threading.Thread(
                target=self._forward_data, args=(client_socket, forward_socket)
            )
            server_to_client = threading.Thread(
                target=self._forward_data, args=(forward_socket, client_socket)
            )
            client_to_server.start()
            server_to_client.start()
            client_to_server.join()
            server_to_client.join()
        except Exception as e:
            print(f"[proxy] Failed to connect to forward host: {e}")
        finally:
            try:
                client_socket.close()
            except Exception as e:
                print(f"[proxy] Failed to close client socket: {e}")
            try:
                if forward_socket:
                    forward_socket.close()
            except Exception as e:
                print(f"[proxy] Failed to close forward socket: {e}")

    def _forward_data(self, source: socket.socket, destination: socket.socket):
        try:
            while True:
                readable, _, _ = select.select([source], [], [], 1)
                if not readable:
                    break
                data = source.recv(4096)
                if not data:
                    break
                destination.sendall(data)
        except Exception as e:
            print(f"[proxy] Failed to forward data from {source} to {destination}: {e}")


if __name__ == "__main__":
    proxy = Proxy(8080, 4, 8000)
    try:
        print(f"[proxy] Proxy listening on port {proxy._listen_port}")
        proxy.start()
    except KeyboardInterrupt:
        print("[proxy] Proxy stopped")
    except Exception as e:
        print(f"[proxy] Failed to start proxy: {e}")
