resource "aws_vpc" "my_vpc_terraform" {
  cidr_block = "192.168.0.0/16"

  tags = {
    Name = "my_vpc_terraform"
  }
}

resource "aws_subnet" "public_subnet_1_terraform" {
  vpc_id            = aws_vpc.my_vpc_terraform.id
  cidr_block        = "192.168.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_1_terraform"
  }
}

resource "aws_subnet" "public_subnet_2_terraform" {
  vpc_id            = aws_vpc.my_vpc_terraform.id
  cidr_block        = "192.168.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_2_terraform"
  }
}

resource "aws_internet_gateway" "my_igw_terraform" {
  vpc_id = aws_vpc.my_vpc_terraform.id

  tags = {
    Name = "my_igw_terraform"

}
}



resource "aws_route_table" "my_route_table_terraform" {
  vpc_id = aws_vpc.my_vpc_terraform.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw_terraform.id
  }

  

  tags = {
    Name = "my_route_table_terraform"
  }
}


resource "aws_route_table_association" "route_association_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1_terraform.id
  route_table_id = aws_route_table.my_route_table_terraform.id
}

resource "aws_route_table_association" "route_association_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2_terraform.id
  route_table_id = aws_route_table.my_route_table_terraform.id
}

resource "aws_instance" "my_ec2_instance_1_terraform"{
  ami = "ami-0ebfd941bbafe70c6"
  associate_public_ip_address = true
  availability_zone = "us-east-1a"
  subnet_id = aws_subnet.public_subnet_1_terraform.id
  instance_type = "t2.micro"
  key_name = "shaolin"
  vpc_security_group_ids = [aws_security_group.my_sg_terraform.id]
  user_data = base64encode(file("user_data.sh"))

  tags = {
    Name = "my_ec2_instance_1_terraform"
  }
}

resource "aws_instance" "my_ec2_instance_2_terraform"{
  ami = "ami-0ebfd941bbafe70c6"
  associate_public_ip_address = true
  availability_zone = "us-east-1b"
  subnet_id = aws_subnet.public_subnet_2_terraform.id
  instance_type = "t2.micro"
  key_name = "shaolin"
  vpc_security_group_ids = [aws_security_group.my_sg_terraform.id]
  user_data = base64encode(file("user_data.sh"))

  tags = {
    Name = "my_ec2_instance_2_terraform"
  }
  }




resource "aws_security_group" "my_sg_terraform" {
  name        = "my_sg_terraform"
  description = "Allow all traffic"
  vpc_id      = aws_vpc.my_vpc_terraform.id

  tags = {
    Name = "my_sg_terraform"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh_traffic_terraform" {
  security_group_id = aws_security_group.my_sg_terraform.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

  resource "aws_vpc_security_group_ingress_rule" "allow_http_traffic_terraform" {
  security_group_id = aws_security_group.my_sg_terraform.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}



resource "aws_vpc_security_group_egress_rule" "allow_outbound_traffic" {
  security_group_id = aws_security_group.my_sg_terraform.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}


# Create a Classic Load Balancer using Subnets
resource "aws_elb" "my_classic_load_balancer" {
  name            = "my-classic-lb-terraform"
  security_groups = [aws_security_group.my_sg_terraform.id]
  subnets         = [
    aws_subnet.public_subnet_1_terraform.id,
    aws_subnet.public_subnet_2_terraform.id,
  ]

  listener {
    instance_port     = 80
    instance_protocol = "HTTP"
    lb_port           = 80
    lb_protocol       = "HTTP"
  }

  health_check {
    target              = "HTTP:80/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "my-classic-lb-terraform"
  }
}

# Associate EC2 instances with the Classic Load Balancer
resource "aws_elb_attachment" "instance_1_attachment" {
  elb      = aws_elb.my_classic_load_balancer.id
  instance = aws_instance.my_ec2_instance_1_terraform.id
}

resource "aws_elb_attachment" "instance_2_attachment" {
  elb      = aws_elb.my_classic_load_balancer.id
  instance = aws_instance.my_ec2_instance_2_terraform.id
}
