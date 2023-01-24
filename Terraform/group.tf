resource "aws_instance" "instance" {
  ami           = "ami-0778521d914d23bc1" 
  instance_type = "t3.large"
  subnet_id = aws_subnet.public_subnet_minecraft.id
  availability_zone = "us-east-1a"
  key_name = 
  security_groups = [aws_security_group.allow_ssh_minecraft.id]

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