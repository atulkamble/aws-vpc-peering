output "vm1_public_ip" {
  value = aws_instance.vm1.public_ip
}

output "vm2_public_ip" {
  value = aws_instance.vm2.public_ip
}

output "vm1_private_ip" {
  value = aws_instance.vm1.private_ip
}

output "vm2_private_ip" {
  value = aws_instance.vm2.private_ip
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
}
