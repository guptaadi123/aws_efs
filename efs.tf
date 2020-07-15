provider "aws" {
  region = "ap-south-1"
  profile = "default"
}


resource "aws_vpc" "foo" {
  cidr_block = "192.168.0.0/16"
  enable_dns_hostnames = "true"
    tags = {
    Name = "terra"
  }
}

resource "aws_subnet" "alpha" {
  vpc_id            = "${aws_vpc.foo.id}"
  availability_zone = "ap-south-1a"
  cidr_block        = "192.168.0.0/24"
  map_public_ip_on_launch = "true"
  tags = {
    Name = "public"
  }

}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.foo.id}"


  tags = {
    Name = "main"
  }
}
resource "aws_route_table" "r" {
  vpc_id = "${aws_vpc.foo.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "newgateway"
  }
}

resource "aws_route_table_association" "a1" {
  subnet_id      = aws_subnet.alpha.id
  route_table_id = aws_route_table.r.id
}

resource "aws_efs_file_system" "foo1" {
  creation_token   = "EFS Shared Data"
  performance_mode = "generalPurpose"
tags = {
    Name = "EFS Shared "
  }
}



resource "aws_efs_mount_target" "alpha" {
  file_system_id = "${aws_efs_file_system.foo1.id}"
  subnet_id      = "${aws_subnet.alpha.id}"
  security_groups = ["${aws_security_group.ServiceSG.id}"]
}

resource "aws_security_group" "ServiceSG" {
  name        = "ServiceSG"
  description = "Security for allowing ssh and 80"
  vpc_id      = "${aws_vpc.foo.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }



  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "aws_instance" "myin" {
 ami            ="ami-0447a12f28fddb066"
 instance_type  = "t2.micro"
 availability_zone = "ap-south-1a"
 key_name       = "webserver"
 vpc_security_group_ids = ["${aws_security_group.ServiceSG.id}"]
 subnet_id= "${aws_subnet.alpha.id}"
 user_data = <<-EOF
         #! /bin/bash
         sudo yum install httpd -y
         sudo yum install git -y
         sudo yum install java -y
         sudo systemctl start httpd
         sudo systemctl enable httpd
         sudo yum install -y amazon-efs-utils
         sudo su - root


 EOF
 tags = {
    Name = "adityaos"
 }
}



resource "null_resource" "nulllocal1"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_instance.myin.public_ip} > publicipinsctance.txt"
  	}
}

resource "null_resource" "nulllocal2"  {
	provisioner "local-exec" {
	    command = "echo  ${aws_efs_file_system.foo1.id} > efsid.txt"
  	}
}

