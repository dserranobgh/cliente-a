  # output "webserver_public_ip" {
  #   value = aws_instance.webserver.public_ip
  # }

  output "webserver_dns_name" {
    value = aws_instance.webserver.public_dns    
  }