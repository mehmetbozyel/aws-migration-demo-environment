terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Create a VPC
resource "aws_vpc" "SourceVPC" {
  cidr_block       = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  instance_tenancy = "default"

  tags = {
    Name = "SourceVPC"
  }
}

resource "aws_subnet" "SourceVPC-public-a" {
  vpc_id     = aws_vpc.SourceVPC.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "SourceVPC-public-a"
  }
}

resource "aws_route_table" "SourceVPC-public-route-table" {
  vpc_id = aws_vpc.SourceVPC.id
  tags = {
      Name = "SourceVPC-public-route-table"
    }
}

resource "aws_security_group" "DBServerSG" {
  description = "DB Server SG"
  name = "DBServerSG"
  tags = {
      Name = "DBServerSG"
  }
  vpc_id = aws_vpc.SourceVPC.id
  ingress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      from_port = 22
      protocol = "tcp"
      to_port = 22
  }
  ingress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      from_port = 3306
      protocol = "tcp"
      to_port = 3306
  }
  ingress {
      security_groups = [
          "${aws_security_group.WebServerSG.id}"
      ]
      from_port = 3306
      protocol = "tcp"
      to_port = 3306
  }
  egress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      protocol = "-1"
      from_port = 0
      to_port = 0
  }
}

resource "aws_security_group" "WebServerSG" {
  description = "Web Server SG"
  name = "WebServerSG"
  tags = {
      Name = "WebServerSG"
  }
  vpc_id = aws_vpc.SourceVPC.id
  ingress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      from_port = 80
      protocol = "tcp"
      to_port = 80
  }
  ingress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      from_port = 22
      protocol = "tcp"
      to_port = 22
  }
  ingress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      from_port = 443
      protocol = "tcp"
      to_port = 443
  }
  egress {
      cidr_blocks = [
          "0.0.0.0/0"
      ]
      protocol = "-1"
      from_port = 0
      to_port = 0
  }
}

#Internet Gateway
resource "aws_internet_gateway" "SourceVPC-IGW" {
    tags = {
        Name = "SourceVPC-IGW"
    }
    vpc_id = aws_vpc.SourceVPC.id
}

resource "aws_route" "Route" {
    destination_cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.SourceVPC-IGW.id
    route_table_id = aws_route_table.SourceVPC-public-route-table.id
}

resource "aws_route_table_association" "SubnetRouteTableAssociation" {
    route_table_id = aws_route_table.SourceVPC-public-route-table.id
    subnet_id = aws_subnet.SourceVPC-public-a.id
}

resource "aws_instance" "Source-Webserver" {
    ami = "ami-0279c3b3186e54acd" # "ami-00d5e377dd7fad751"
    instance_type = "t2.micro"
    key_name = "migrationkeypair"
    availability_zone = "us-east-1a"
    tenancy = "default"
    subnet_id = aws_subnet.SourceVPC-public-a.id
    ebs_optimized = false
    vpc_security_group_ids = [
        "${aws_security_group.WebServerSG.id}"
    ]
    source_dest_check = true
    root_block_device {
        volume_size = 16
        volume_type = "gp2"
        delete_on_termination = true
    }
    user_data = "IyEvYmluL2Jhc2ggLXgKaWYgWy1mICIuL2RvbnRfcnVuX2FnYWluIl0KdGhlbgogIGVjaG8gIkluaXRpYWxpemF0aW9uIHdhcyBkb25lIGFscmVhZHkgZWFybGllciIKZWxzZQogIGFwdC1nZXQgdXBkYXRlCiAgYXB0LWdldCBpbnN0YWxsIGRvczJ1bml4IHdnZXQgLXkKICBjZCB+ICYmIHdnZXQgaHR0cHM6Ly9hcHBsaWNhdGlvbi1taWdyYXRpb24td2l0aC1hd3Mtd29ya3Nob3AuczMtdXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vc2NyaXB0cy93ZWJzZXJ2ZXJfdWJ1bnR1LnNoCiAgY2htb2QgK3ggLi93ZWJzZXJ2ZXJfdWJ1bnR1LnNoCiAgZG9zMnVuaXggKi5zaAogIGV4cG9ydCBEQl9JUD0xMC4wLjAuOTQKICBleHBvcnQgV0VCU0VSVkVSX0RPTUFJTl9OQU1FPSQoY3VybCBodHRwOi8vMTY5LjI1NC4xNjkuMjU0L2xhdGVzdC9tZXRhLWRhdGEvcHVibGljLWhvc3RuYW1lKQogIHN1IC1jICcvYmluL2Jhc2ggd2Vic2VydmVyX3VidW50dS5zaCcKICBybSAuL3dlYnNlcnZlcl91YnVudHUuc2gKICB0b3VjaCAuL2RvbnRfcnVuX2FnYWluCmZpCg=="
    # iam_instance_profile = "migration-demo-EC2InstanceProfile-KA213ICPZ66X"
    monitoring = true
    tags = {
        Name = "Source-Webserver"
    }
}

resource "aws_instance" "Source-DBServer" {
    ami = "ami-0279c3b3186e54acd" # "ami-00d5e377dd7fad751"
    instance_type = "t2.micro"
    key_name = "migrationkeypair"
    availability_zone = "us-east-1a"
    tenancy = "default"
    private_ip = "10.0.0.94"
    subnet_id = aws_subnet.SourceVPC-public-a.id
    ebs_optimized = false
    vpc_security_group_ids = [
        "${aws_security_group.DBServerSG.id}"
    ]
    source_dest_check = true
    root_block_device {
        volume_size = 8
        volume_type = "gp2"
        delete_on_termination = true
    }
    user_data = "IyEvYmluL2Jhc2ggLXgKaWYgWy1mICIuL2RvbnRfcnVuX2FnYWluIl0KdGhlbgogIGVjaG8gIkluaXRpYWxpemF0aW9uIHdhcyBkb25lIGFscmVhZHkgZWFybGllciIKZWxzZQogIGFwdC1nZXQgdXBkYXRlCiAgYXB0LWdldCBpbnN0YWxsIGRvczJ1bml4IHdnZXQgLXkKICBjZCB+ICYmIHdnZXQgaHR0cHM6Ly9hcHBsaWNhdGlvbi1taWdyYXRpb24td2l0aC1hd3Mtd29ya3Nob3AuczMtdXMtd2VzdC0yLmFtYXpvbmF3cy5jb20vc2NyaXB0cy9kYXRhYmFzZV91YnVudHUuc2gKICBjaG1vZCAreCAuL2RhdGFiYXNlX3VidW50dS5zaAogIGRvczJ1bml4ICouc2gKICBzdSAtYyAnL2Jpbi9iYXNoIGRhdGFiYXNlX3VidW50dS5zaCcKICBybSAuL2RhdGFiYXNlX3VidW50dS5zaAogIHRvdWNoIC4vZG9udF9ydW5fYWdhaW4KZmkK"
    # iam_instance_profile = "migration-demo-EC2InstanceProfile-KA213ICPZ66X"
    monitoring = true
    tags = {
        Name = "Source-DBServer"
    }
}