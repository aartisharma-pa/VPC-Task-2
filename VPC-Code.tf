provider "aws" {
  region     = "ap-south-1"
  profile    = "patask"
}
resource "aws_vpc" "vpc" {
	  cidr_block       = "192.168.0.0/16"
	  instance_tenancy = "default"
             enable_dns_support = true
             enable_dns_hostnames = true	
	  tags = {
	    Name = "MyVPCTask"
	          }
	     }
resource "aws_internet_gateway" "gateway" {
	  vpc_id = aws_vpc.vpc.id
	
	  tags = {
	    Name = "VPCTaskGateway"
	       }
	}
resource "aws_subnet" "public" {
	  vpc_id     = aws_vpc.vpc.id         
	  cidr_block = "192.168.0.0/24"
	  map_public_ip_on_launch =  “true”
	  availability_zone = "ap-south-1a"
	  tags = {
	    Name = "VPCTaskSubnet1"
	  }
	}
resource "aws_subnet" "private" {
	    vpc_id = aws_vpc.vpc.id
	    cidr_block = "192.168.1.0/24"
	   map_public_ip_on_launch =  “true”
	    availability_zone = "ap-south-1b"
	  tags = {
	    Name = "VPCTaskSubnet2"
	  }
	}

resource "aws_eip" "eip" {
 vpc = true
}
resource "aws_nat_gateway" "natgtwy" {
  allocation_id = "${aws_eip.eip.id}"
  subnet_id     = "${aws_subnet.public.id}"
  tags = {
    Name ="natgw"
  }
}

resource "aws_route_table" "routetab" {
	  vpc_id = aws_vpc.vpc.id
	  route {
	    cidr_block = "0.0.0.0/0"
	    gateway_id = aws_internet_gateway.gateway.id
	  }
	
	  tags = {
	    Name = "VPCTaskRouteTable"
	  }
	}

resource "aws_route_table" "natroute" {
 vpc_id = "${aws_vpc.vpc.id}"
 
 route {
  cidr_block = "0.0.0.0/0"
  nat_gateway_id = "${aws_nat_gateway.natgtwy.id}"
 }
 
 tags = {
  Name = "natroute"
 }
}
resource "aws_route_table_association" "routeasso" {
	  subnet_id      = aws_subnet.public.id
	  route_table_id = aws_route_table.routetab.id
	}

resource "aws_route_table_association" "natrouteasso" {
 subnet_id = "${aws_subnet.private.id}"
 route_table_id = "${aws_route_table.natroute.id}"
}






resource "aws_security_group" "websg" {
             name = "VPCTaskSecuritygrp"
             description = "Allows SSH,HTTP,PING"
             vpc_id = aws_vpc.vpc.id

    ingress {
         	 description = "SSH"
     	 from_port   = 22
     	 to_port     = 22
      	protocol    = "tcp"
      	cidr_blocks = ["0.0.0.0/0"]
      }
    ingress {
     	 description = "HTTP"
   	 protocol    = "tcp"
   	 from_port   = 80
    	to_port     = 80
    	cidr_blocks = ["0.0.0.0/0"]
      }
     ingress {
         	description = "ICMP-IPv4"
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
resource "aws_security_group" "mysqlsg" {
  name = "VPCTaskSecuritygrp2"
  description = "Allows MYSQL"
  vpc_id = aws_vpc.vpc.id
  ingress {
  	  protocol        = "tcp"
   	 from_port       = 3306
   	 to_port         = 3306
   	 security_groups = ["${aws_security_group.websg.id}"]
  }

 egress {
    	from_port   = 0
    	to_port     = 0
   	 protocol    = "-1"
   	 cidr_blocks = ["0.0.0.0/0"]
        }
}

resource "aws_security_group" "bastionhost_sec" {
             name = "VPCTaskBastion"
             description = "Allows SSH"
             vpc_id = aws_vpc.vpc.id

    ingress {
         	 description = "SSH"
     	 from_port   = 22
     	 to_port     = 22
      	protocol    = "tcp"
      	cidr_blocks = ["0.0.0.0/0"]
      }
   
egress {
   	 from_port   = 0
    	to_port     = 0
    	protocol    = "-1"
   	 cidr_blocks = ["0.0.0.0/0"]
       }
}


           resource "aws_instance" "wordpress" {
	  ami           = " ami-7e257211"
	  instance_type = "t2.micro"
	  associate_public_ip_address = true
	  subnet_id = aws_subnet.public.id
	  vpc_security_group_ids = ["${aws_security_group.websg.id}"]
	  key_name = "MyKey1"
	  availability_zone = "ap-south-1a"
	
	  tags = {
	    Name = "WORDPRESS"
	  }
	
	}

	resource "aws_instance" "mysql" {
	  ami           = "ami-08706cb5f68222d09"
	  instance_type = "t2.micro"
	  subnet_id = aws_subnet.private.id
	  vpc_security_group_ids = ["${aws_security_group.mysqlsg.id}"]
	  key_name = "MyKey1"
	  availability_zone = "ap-south-1b"
	
	 tags = {
	    Name = "MysqlOS"
	  }
	}



 resource "aws_instance" "bastionhost" {
	  ami           = " ami-0732b62d310b80e97"
	  instance_type = "t2.micro"
	  associate_public_ip_address = true
	  subnet_id = aws_subnet.public.id
	  vpc_security_group_ids = ["${aws_security_group.bastionhost_sec.id}"]
	  key_name = "MyKey1"
	  availability_zone = "ap-south-1a"
	
	  tags = {
	    Name = "BastionOS"
	  }
	
	}




