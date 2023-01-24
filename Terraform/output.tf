output "subnet_public_info" {
  value = aws_subnet.public_subnet_minecraft.arn
}
output "vpc_info" {
  value = aws_vpc.VPC_minecraft.arn
}
output "sg-id_ssh" {
  value = aws_security_group.allow_ssh_minecraft.arn
}
output "sg-id_minecraft" {
  value = aws_security_group.allow_minecraft.arn
}