resource "aws_vpc" "VPC_Minecraft" {
  cidr_block = "10.0.0.0/16"

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
  ami           = "ami-0de3167fef21b4c0d" 
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
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet_Minecraft.id, aws_subnet.private_subnet_Minecraft.id]

  tags = {
      Name = "terraform_autoscaling"
      build_by = "terraform"
  }
}

resource "aws_elb" "elb_Minecraft" {
  name               = "elb_Minecraft"
  internal           = false
  subnets = [aws_subnet.public_subnet_Minecraft.id]
  security_groups = [aws_security_group.elb_Minecraft.id]
  enable_deletion_protection = false

  listener {
    instance_port     = 25565
    instance_protocol = "tcp"
    lb_port           = 25565
    lb_protocol       = "tcp"
  }

  tags = {
      Name = "terraform_elb"
      build_by = "terraform"
  }
}

resource "aws_elb_attachment" "elb_attachment_Minecraft" {
  elb      = aws_elb.elb_Minecraft.id
  instance = aws_instance.instance_Minecraft.id
}

resource "aws_security_group" "security_group_elb_Minecraft" {
  name        = "security_group_elb_Minecraft"
  description = "Security group_elb_Minecraft"

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
  namespace           = "AWS/Autoscaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "CPU>70%"
  alarm_actions       = [aws_sns_topic.sns_Minecraft.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_Minecraft.name
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
  namespace           = "AWS/Autoscaling"
  period              = "120"
  statistic           = "Average"
  threshold           = "70"
  alarm_description   = "RAM>70%"
  alarm_actions       = [aws_sns_topic.sns_Minecraft.arn]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.autoscaling_Minecraft.name
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

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_Minecraft" {
  rule {
    id      = "bucket_lifecycle_Minecraft"
    status  = "Enabled"
    filter {
      prefix = "logs/"
    }
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    expiration {
      days = 60
    }
  }
}

resource "aws_cloudwatch_event_rule" "cloudwatch_bucket_rule_Minecraft" {
  name = "cloudwatch_bucket_Minecraft"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "cloudwatch_bucket_event_Minecraft" {
  rule = aws_cloudwatch_event_rule.cloudwatch_bucket_rule_Minecraft.name
  target_id = "cloudwatch_bucket_event_Minecraft"
  arn = "arn:aws:s3:::s3_Minecraft"
}

resource "aws_lambda_function" "lambda_Minecraft" {
  filename      = "lambda_function.zip"
  function_name = "lambda_Minecraft"
  role          = aws_iam_role.iam_Minecraft.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_iam_role" "iam_Minecraft" {
  name = "iam_Minecraft"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "iam_policy_Minecraft" {
  name = "iam_policy_Minecraft"
  role = aws_iam_role.iam_Minecraft.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "s3:PutObject",
                "s3:GetBucketLocation"
            ],
            "Resource": [
                "arn:aws:s3:::s3_Minecraft",
                "arn:aws:s3:::s3_Minecraft/*"
            ]
        }
    ]
}
EOF
}

resource "aws_key_pair" "keypair_Minecraft" {
  key_name   = "keypair_Minecraft"
  public_key = file("PATH")
}

