output "subnet_public_info" {
  value = aws_subnet.public_subnet.arn
}
output "vpc_info" {
  value = aws_vpc.VPC_minecraft.arn
}
output "sg-id" {
  value = aws_security_group.allow_ssh.arn
}
output "sg-id" {
  value = aws_security_group.allow_minecraft.arn
}