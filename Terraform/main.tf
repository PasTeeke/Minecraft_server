resource "aws_vpc" "VPC_minecraft" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "terraform_vpc"
    build_by = "terraform"
  }
}

resource "aws_subnet" "public_subnet_minecraft" {
  vpc_id            = aws_vpc.VPC_minecraft.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = ""
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
    build_by = "terraform"
  }
}

resource "aws_subnet" "private_subnet_minecraft" {
  vpc_id            = aws_vpc.VPC_minecraft.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = ""
  map_public_ip_on_launch = false

  tags = {
    Name = "private_subnet"
    build_by = "terraform"
  }
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

resource "aws_nat_gateway" "nat_gateway_minecraft" {
  allocation_id = aws_eip.eip_minecraft.id
  subnet_id     = aws_subnet.public_subnet_minecraft.id

  tags = {
      Name = "terraform_nat"
      build_by = "terraform"
  }
}

resource "aws_instance" "instance_minecraft" {
  ami           = "ami-0778521d914d23bc1" 
  instance_type = "t3.large"

  tags = {
      Name = "terraform_instance"
      build_by = "terraform"
  }
}

resource "aws_launch_configuration" "launch_configuration_minecraft" {
  name          = "launch_configuration_minecraft"
  image_id = aws_ami.instance.id
  instance_type = "t3.large"
}

resource "aws_autoscaling_group" "autoscaling_minecraft" {
  name                 = "autoscaling_minecraft"
  launch_configuration = aws_launch_configuration.autoscaling_minecraft.id
  min_size             = 1
  max_size             = 1
  desired_capacity     = 1
  vpc_zone_identifier  = [aws_subnet.public_subnet_minecraft.id, aws_subnet.private_subnet_minecraft.id]

  tags = {
      Name = "terraform_autoscaling"
      build_by = "terraform"
  }
}

resource "aws_elb" "elb_minecraft" {
  name               = "elb_minecraft"
  internal           = false
  subnets = [aws_subnet.public_subnet_minecraft.id]
  security_groups = [aws_security_group.security_group_elb_minecraft.id]
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

resource "aws_elb_attachment" "elb_attachment_minecraft" {
  elb      = aws_elb.elb_minecraft.id
  instance = aws_instance.instance_minecraft.id
}

resource "aws_security_group" "security_group_elb_minecraft" {
  name        = "security_group_elb_minecraft"
  description = "Security group_elb_minecraft"

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

resource "aws_security_group" "allow_ssh_minecraft" {
  name        = "allow_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.VPC_minecraft

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.VPC_minecraft.cidr_block]
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


resource "aws_s3_bucket" "s3_minecraft" {
  bucket = "s3_minecraft"

  tags = {
      Name = "terraform_s3"
      build_by = "terraform"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "bucket_lifecycle_minecraft" {
  bucket = aws_s3_bucket.s3_minecraft.id
  rule {
    id      = "bucket_lifecycle_minecraft"
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

resource "aws_cloudwatch_event_rule" "cloudwatch_bucket_rule_minecraft" {
  name = "cloudwatch_bucket_minecraft"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "cloudwatch_bucket_event_minecraft" {
  rule = aws_cloudwatch_event_rule.cloudwatch_bucket_rule_minecraft.name
  target_id = "cloudwatch_bucket_event_minecraft"
  arn = "arn:aws:s3:::s3_minecraft"
}

resource "aws_lambda_function" "lambda_minecraft" {
  filename      = "lambda_function.zip"
  function_name = "lambda_minecraft"
  role          = aws_iam_role.iam_minecraft.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.8"
}

resource "aws_iam_role" "iam_minecraft" {
  name = "iam_minecraft"

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

resource "aws_iam_role_policy" "iam_policy_minecraft" {
  name = "iam_policy_minecraft"
  role = aws_iam_role.iam_minecraft.id

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
                "arn:aws:s3:::s3_minecraft",
                "arn:aws:s3:::s3_minecraft/*"
            ]
        }
    ]
}
EOF
}

#resource "aws_key_pair" "keypair_minecraft" {
#  key_name   = "keypair_minecraft"
#  public_key = file("PATH")
#}

