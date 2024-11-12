output "public_ip" {
  description = "Public IP of MPC server"
  value = aws_instance.mpc_server.public_ip
}