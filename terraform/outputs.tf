output "ec2_a_private_ip" {
  value = aws_instance.ec2_a.private_ip
}

output "ec2_b_private_ip" {
  value = aws_instance.ec2_b.private_ip
}

output "ec2_a_public_ip" {
  value = aws_instance.ec2_a.public_ip
}

output "ec2_b_public_ip" {
  value = aws_instance.ec2_b.public_ip
}

output "vpc_peering_connection_id" {
  value = aws_vpc_peering_connection.peer.id
}
