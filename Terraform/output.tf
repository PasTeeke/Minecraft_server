output "vpc_info" {
  value = aws_vpc.VPC_minecraft.arn
}
output "load_balancer_info" {
  value = aws_lb.lb_minecraft.arn
}