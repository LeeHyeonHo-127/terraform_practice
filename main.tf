provider "aws" {
    region = "ap-northeast-2"
}


resource "aws_instance" "example" {
  ami           = "ami-0f3a440bbcff3d043" 
  instance_type = "t3.micro"
  subnet_id     = "subnet-02a6174ab45241360"
  vpc_security_group_ids = ["sg-070fcb547087c29fc"]

  tags = {
     Name = "terraform-test-ec2"
  } 
}


