resource "aws_instance" "instance_minecraft_group1" {
  ami           = "ami-0778521d914d23bc1" 
  instance_type = "t3.large"
  subnet_id = aws_subnet.public_subnet_minecraft.id
  availability_zone = "us-east-1a"
  key_name = aws_key_pair.keypair_minecraft.key_name
  security_groups = [aws_security_group.allow_ssh_minecraft.id]

}