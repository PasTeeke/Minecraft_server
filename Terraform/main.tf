resource "aws_vpc" "VPC_minecraft" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support  = true
  enable_dns_hostnames = true

 

  tags = {
    Name = "terraform_vpc"
    build_by = "terraform"
  }
}

 

resource "aws_subnet" "public_subnet_minecraft" { #route table
  vpc_id            = aws_vpc.VPC_minecraft.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

 

  tags = {
    Name = "public_subnet"
    build_by = "terraform"
  }
}

resource "aws_subnet" "public_subnet_2_minecraft_LB" { #route table
  vpc_id            = aws_vpc.VPC_minecraft.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

 

  tags = {
    Name = "public_subnet_2"
    build_by = "terraform"
  }
}

 

resource "aws_subnet" "private_subnet_minecraft" {
  vpc_id            = aws_vpc.VPC_minecraft.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = ""
  map_public_ip_on_launch = false

 

  tags = {
    Name = "private_subnet"
    build_by = "terraform"
  }
}

resource "aws_route" "route_minecraft"{
    route_table_id  = aws_vpc.VPC_minecraft.default_route_table_id
    destination_cidr_block  = "0.0.0.0/0"
    gateway_id  = aws_internet_gateway.internet_gateway_minecraft.id
}

 

resource "aws_internet_gateway" "internet_gateway_minecraft" {
  vpc_id = aws_vpc.VPC_minecraft.id

 

  tags = {
      Name = "terraform_igw"
      build_by = "terraform"
  }
}

 

resource "aws_eip" "eip_minecraft" {
    instance = aws_instance.instance_minecraft.id
    vpc = true
    
 

    tags = {
      Name = "terraform_eip"
      build_by = "terraform"
  }
}
/*
resource "aws_nat_gateway" "nat_gateway_minecraft" {
  allocation_id = aws_eip.eip_minecraft.id
  subnet_id     = aws_subnet.public_subnet_minecraft.id

 

  tags = {
      Name = "terraform_nat"
      build_by = "terraform"
  }
}
*/
resource "aws_instance" "instance_minecraft" {
  ami           = "ami-0778521d914d23bc1" 
  instance_type = "t3.large"
  subnet_id = aws_subnet.public_subnet_minecraft.id
  availability_zone = "us-east-1a"
  key_name = aws_key_pair.keypair_minecraft.key_name
  security_groups = [aws_security_group.allow_ssh_minecraft.id]

 

  tags = {
      Name = "terraform_instance"
      build_by = "terraform"
  }
}

 

resource "aws_launch_configuration" "launch_configuration_minecraft" {
  name          = "launch_configuration_minecraft"
  image_id = "ami-0778521d914d23bc1"
  instance_type = "t3.large"
}


 

resource "aws_autoscaling_group" "autoscaling_minecraft" {
  name                 = "autoscaling_minecraft"
  launch_configuration = aws_launch_configuration.launch_configuration_minecraft.id
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet_minecraft.id, aws_subnet.private_subnet_minecraft.id]
}

 

resource "aws_lb" "lb_minecraft" {
  name               = "lbminecraft"
  internal           = false
  load_balancer_type = "network"
  // security_groups    = [aws_security_group.security_group_elb_minecraft.id]
  subnets            = [aws_subnet.public_subnet_minecraft.id, aws_subnet.public_subnet_2_minecraft_LB.id]

  enable_deletion_protection = true
}

resource "aws_lb_target_group" "targetgroup" {
  name = "test"
  port = 25565
  protocol = "TCP"
  vpc_id = aws_vpc.VPC_minecraft.id
}

resource "aws_lb_target_group_attachment" "tg-attachment" {
    target_group_arn = aws_lb_target_group.targetgroup.arn
    target_id = aws_instance.instance_minecraft.id
}

 

/*resource "aws_security_group" "security_group_elb_minecraft" {
  name        = "security_group_elb_minecraft"
  description = "Security group_elb_minecraft"
  vpc_id = aws_vpc.VPC_minecraft.id

 

  ingress {
    from_port   = 25565
    to_port     = 25565
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 

  tags = {
      Name = "terraform_security_elb"
      build_by = "terraform"
  }
}*/

 

resource "aws_security_group" "allow_ssh_minecraft" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.VPC_minecraft.id

 

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

 

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 

  tags = {
    Name = "allow_ssh"
    build_by = "terraform"
  }
}

 

resource "aws_cloudwatch_metric_alarm" "cloudwatch_CPU_minecraft" {
  alarm_name          = "alarme_CPU_minecraft"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/Autoscaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "CPU>70%"
  alarm_actions       = [aws_sns_topic.sns_minecraft.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_minecraft.name
  }

 

  tags = {
      Name = "terraform_CPU"
      build_by = "terraform"
  }
}

 

resource "aws_cloudwatch_metric_alarm" "cloudwatch_RAM_minecraft" {
  alarm_name          = "alarme_RAM_minecraft"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/Autoscaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "RAM>70%"
  alarm_actions       = [aws_sns_topic.sns_minecraft.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_minecraft.name
  }

 

  tags = {
      Name = "terraform_RAM"
      build_by = "terraform"
  }
}

 

resource "aws_sns_topic" "sns_minecraft" {
  name = "sns_minecraft"

 

  tags = {
      Name = "terraform_sns"
      build_by = "terraform"
  }
}

 

resource "aws_sns_topic_subscription" "sns_mail_minecraft" {
  topic_arn = aws_sns_topic.sns_minecraft.arn
  protocol = "email"
  endpoint = "loic.ferment@viacesi.fr"
}

 


resource "aws_s3_bucket" "s3minecraft" {
  bucket = "s3minecraft"

 

  tags = {
      Name = "terraform_s3"
      build_by = "terraform"
  }
}

 
resource "aws_key_pair" "keypair_minecraft" {
  key_name   = "id_rsa.pub"
  public_key = file("~/.ssh/id_rsa.pub")
}

 