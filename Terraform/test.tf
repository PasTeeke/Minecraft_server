resource "aws_lb" "lb_minecraft" {
  name               = "lbminecraft"
  internal           = false
  load_balancer_type = "application"
  security_groups    = aws_security_group.security_group_elb_minecraft.id
  subnets            = aws_subnet.public_subnet_minecraft.id

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "targetgroup" {
  name = "test"
  port = 80
  protocol = "TCP"
  vpc_id = aws_vpc.VPC_minecraft.id
}

resource "aws_lb_target_group_attachment" "tg-attachment" {
    target_group_arn = aws_lb_target_group.targetgroup.arn
    target_id = aws_instance.instance_minecraft.id
}