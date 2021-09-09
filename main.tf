resource "aws_iam_policy" "policy1" {
  name        = "test_policy_3"
  path        = "/"
  description = "My test policy"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  //policy = ("$file(s3policy.json)")
  policy = "${file("s3policy.json")}"
}

locals {
  common_tags = {
    "Application" = "web"
    "type"  = "service"
    "COST_CENTRE_ID" = "52458"
    "Backup" = "true"
  }
  ec2_public = {
    "type" = "public"
    "instance" = "compute"
    "size" = "4gb"
    "instance_type" = "${var.ec2type[0]}"
  }
  ec2_private = {
    "type" = "private"
    "instanc" = "compute"
    "size" = "8gb"
  }
}
resource "aws_vpc" "terraform-vpc" {
  cidr_block = "${var.vpc-cidr}"
  tags = {
    Name = "terraform-vpc"
  }
}
resource "aws_subnet" "terraform-public" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "${var.subnet-cidr[0]}"
  tags = {
    Name = "public"
  }
}
resource "aws_subnet" "terraform-private" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  cidr_block = "${var.subnet-cidr[1]}"
  tags = {
    Name = "private"
  }
}
resource "aws_internet_gateway" "terraform-igw" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    "Name" = "Teeraform_igw"
  }
}
resource "aws_route_table" "terraform-pub-route" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  tags = {
    "name" = "public-route-table"
  }
}

resource "aws_route" "terraform_public_route" {
  route_table_id = "${aws_route_table.terraform-pub-route.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = "${aws_internet_gateway.terraform-igw.id}"
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.terraform-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = [aws_vpc.terraform-vpc.cidr_block]
    //ipv6_cidr_blocks = [aws_vpc.m.ipv6_cidr_block]
  }
}

resource "aws_security_group" "ec2-sg" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
  ingress {
      description      = "TLS from VPC"
      from_port        = "22"
      to_port          = "22"
      protocol         = "tcp"
      cidr_blocks      = ["0.0.0.0/0"]
    } 
  egress {
      from_port        = 0
      to_port          = 0
      protocol         = "-1"
      cidr_blocks      = ["0.0.0.0/0"]
      #ipv6_cidr_blocks = ["::/0"]
    }
}

data "aws_ami" "amz2-lin" {
  owners = ["amazon"]
  most_recent = true
  filter {
    name = "name"
    values = [ "amzn2-ami-hvm-*-gp2"]
  }
}
data "aws_subnet_ids" "terraform-sub-vpc" {
  vpc_id = "${aws_vpc.terraform-vpc.id}"
}
data "aws_subnet" "terraform-subid" {
  for_each = data.aws_subnet_ids.terraform-sub-vpc.ids
  id = each.value
}

/*resource "aws_instance" "tf-ec2" {
  ami = data.aws_ami.amz2-lin.id
  instance_type = var.ec2type[0]
  subnet_id = aws_subnet.terraform-public.id
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
  key_name = "Avinash-Training"
  user_data = "${file("userdata.sh")}"
  tags = merge(
    local.common_tags,
    local.ec2_public,
    {
      "new" = "false"
    }
  )
}*/

resource "aws_launch_template" "terraform-template" {
  name = "Terraform-template"
  image_id = data.aws_ami.amz2-lin.id
  instance_type = var.ec2type[0]
  vpc_security_group_ids = [aws_security_group.ec2-sg.id]
}

resource "aws_autoscaling_group" "terraform-asg" {
  name = "terraform-asg"
  launch_template {
    id      = aws_launch_template.terraform-template.id
    version = "$Latest"
  }
  min_size = 1
  max_size = 5
  desired_capacity = 2
  vpc_zone_identifier = [ for i in data.aws_subnet.terraform-subid: i.id]
}