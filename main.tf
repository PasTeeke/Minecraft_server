resource "aws_vpc" "VPC_Minecraft" {
  cidr_block = "10.0.0.0/16"
  enable_network_address_usage_metrics = false
  enable_dns_support  = true
  enable_dns_hostnames = true

  tags = {
    Name = "terraform_vpc"
    build_by = "terraform"
  }
}

resource "aws_subnet" "public_subnet_Minecraft" {
  vpc_id            = aws_vpc.VPC_Minecraft.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = ""
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
    build_by = "terraform"
  }
}

resource "aws_subnet" "private_subnet_Minecraft" {
  vpc_id            = aws_vpc.VPC_Minecraft.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = ""
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet"
    build_by = "terraform"
  }
}

resource "aws_internet_gateway" "internet_gateway_Minecraft" {
  vpc_id = aws_vpc.VPC_Minecraft.id

  tags = {
      Name = "terraform_igw"
      build_by = "terraform"
  }
}

resource "aws_eip" "eip_Minecraft" {
    instance = aws_instance.instance_Minecraft.id
    vpc = true

    tags = {
      Name = "terraform_eip"
      build_by = "terraform"
  }
}

resource "aws_nat_gateway" "nat_gateway_Minecraft" {
  allocation_id = aws_eip.eip_Minecraft.id
  subnet_id     = aws_subnet.public_subnet_Minecraft.id

  tags = {
      Name = "terraform_nat"
      build_by = "terraform"
  }
}

resource "aws_instance" "instance_Minecraft" {
  ami           = "ami-0f948dba952971c71" 
  instance_type = "t3.large"

  tags = {
      Name = "terraform_instance"
      build_by = "terraform"
  }
}

resource "aws_autoscaling_group" "autoscaling_Minecraft" {
  name                 = "autoscaling_Minecraft"
  launch_configuration = aws_launch_configuration.autoscaling_Minecraft.name
  min_size             = 1
  max_size             = 2
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet_Minecraft.id, aws_subnet.private_subnet_Minecraft.id]

  tags = {
      Name = "terraform_autoscaling"
      build_by = "terraform"
  }
}

resource "aws_elb" "elb_Minecraft" {
  subnets = [aws_subnet.public_subnet_Minecraft.id]
  security_groups = [aws_security_group.elb_Minecraft.id]

  tags = {
      Name = "terraform_elb"
      build_by = "terraform"
  }
}

resource "aws_security_group" "security_group_elb_Minecraft" {
  name        = "security_group_elb_Minecraft"
  description = "Security group_elb_Minecraft"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
      Name = "terraform_security_elb"
      build_by = "terraform"
  }
}

resource "aws_security_group" "allow_ssh_Minecraft" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.VPC_Minecraft

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.VPC_Minecraft.cidr_block]
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

resource "aws_cloudwatch_metric_alarm" "cloudwatch_CPU_Minecraft" {
  alarm_name          = "alarme_CPU_Minecraft"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "CPU>70%"
  alarm_actions       = [aws_sns_topic.sns_Minecraft.arn]
  dimensions = {
    InstanceId = aws_instance.instance_Minecraft.id
  }

  tags = {
      Name = "terraform_CPU"
      build_by = "terraform"
  }
}

resource "aws_cloudwatch_metric_alarm" "cloudwatch_RAM_Minecraft" {
  alarm_name          = "alarme_RAM_Minecraft"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "MemoryUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "RAM>70%"
  alarm_actions       = [aws_sns_topic.sns_Minecraft.arn]
  dimensions = {
    InstanceId = aws_instance.instance_Minecraft.id
  }

  tags = {
      Name = "terraform_RAM"
      build_by = "terraform"
  }
}

resource "aws_sns_topic" "sns_Minecraft" {
  name = "sns_Minecraft"

  tags = {
      Name = "terraform_sns"
      build_by = "terraform"
  }
}

resource "aws_sns_topic_subscription" "sns_mail_Minecraft" {
  topic_arn = aws_sns_topic.sns_Minecraft.arn
  protocol = "email"
  endpoint = "loic.ferment@viacesi.fr"

  tags = {
      Name = "terraform_sns_mail"
      build_by = "terraform"
  }
}


resource "aws_s3_bucket" "s3_Minecraft" {
  bucket = "s3_Minecraft"

  tags = {
      Name = "terraform_s3"
      build_by = "terraform"
  }
}

resource "aws_key_pair" "keypair_Minecraft" {
  key_name   = "keypair_Minecraft"
  public_key = file("PATH")
}

