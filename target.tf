resource "aws_vpc" "TargetVPC" {
    cidr_block = "10.0.0.0/16"
    enable_dns_support = true
    enable_dns_hostnames = true
    instance_tenancy = "default"
    tags = {
        Name = "TargetVPC"
    }
}

resource "aws_internet_gateway" "TargetVPC-IGW" {
    tags = {
        Name = "TargetVPC-IGW"
    }
    vpc_id = aws_vpc.TargetVPC.id
}

resource "aws_subnet" "TargetVPC-public-a" {
    availability_zone = "us-east-1a"
    cidr_block = "10.0.0.0/24"
    vpc_id = aws_vpc.TargetVPC.id
    map_public_ip_on_launch = true
    tags = {
        Name = "TargetVPC-public-a"
    }
}

resource "aws_subnet" "TargetVPC-public-b" {
    availability_zone = "us-east-1b"
    cidr_block = "10.0.1.0/24"
    vpc_id = aws_vpc.TargetVPC.id
    map_public_ip_on_launch = true
    tags = {
        Name = "TargetVPC-public-b"
    }
}

resource "aws_subnet" "TargetVPC-private-a-web" {
    availability_zone = "us-east-1a"
    cidr_block = "10.0.100.0/24"
    vpc_id = aws_vpc.TargetVPC.id
    map_public_ip_on_launch = false
    tags = {
        Name = "TargetVPC-private-a-web"
    }
}

resource "aws_subnet" "TargetVPC-private-b-web" {
    availability_zone = "us-east-1b"
    cidr_block = "10.0.101.0/24"
    vpc_id = aws_vpc.TargetVPC.id
    map_public_ip_on_launch = false
    tags = {
        Name = "TargetVPC-private-b-web"
    }
}

resource "aws_subnet" "TargetVPC-private-a-db" {
    availability_zone = "us-east-1a"
    cidr_block = "10.0.200.0/24"
    vpc_id = aws_vpc.TargetVPC.id
    map_public_ip_on_launch = false
    tags = {
        Name = "TargetVPC-private-a-db"
    }
}

resource "aws_subnet" "TargetVPC-private-b-db" {
    availability_zone = "us-east-1b"
    cidr_block = "10.0.201.0/24"
    vpc_id = aws_vpc.TargetVPC.id
    map_public_ip_on_launch = false
    tags = {
        Name = "TargetVPC-private-b-db"
    }
}

# resource "aws_network_acl" "TargetVPC-public-nacl" {
#     vpc_id = aws_vpc.TargetVPC.id
#     subnet_ids = [aws_subnet.TargetVPC-public-a.id, aws_subnet.TargetVPC-public-b.id]
#     egress {
#         protocol   = "-1"
#         rule_no    = 200
#         action     = "allow"
#         cidr_block = "0.0.0.0/0"
#         from_port  = 0
#         to_port    = 0
#     }

#     ingress {
#         protocol   = "-1"
#         rule_no    = 100
#         action     = "allow"
#         cidr_block = "0.0.0.0/0"
#         from_port  = 0
#         to_port    = 0
#     }
#     tags = {
#         Network = "Public"
#         Name = "TargetVPC-public-nacl"
#     }
# }

resource "aws_route_table" "TargetVPC-public-route-table" {
    vpc_id = aws_vpc.TargetVPC.id
    route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.TargetVPC-IGW.id
    }
    tags = {
        Network = "Public"
        Name = "TargetVPC-public-route-table"
    }
}

resource "aws_route_table" "TargetVPC-private-route-table-1" {
    vpc_id = aws_vpc.TargetVPC.id
    tags = {
        Name = "TargetVPC-private-route-table-1"
    }
}

resource "aws_route_table" "TargetVPC-private-route-table-0" {
    vpc_id = aws_vpc.TargetVPC.id
    tags = {
        Name = "TargetVPC-private-route-table-0"
    }
}

resource "aws_route_table_association" "TargetVPC-public-route-table-Association" {
    route_table_id = aws_route_table.TargetVPC-public-route-table.id
    subnet_id = aws_subnet.TargetVPC-public-a.id
}

resource "aws_route_table_association" "TargetVPC-public-route-table-Association1" {
    route_table_id = aws_route_table.TargetVPC-public-route-table.id
    subnet_id = aws_subnet.TargetVPC-public-b.id
}

resource "aws_route_table_association" "TargetVPC-private-route-table-0-Association" {
    route_table_id = aws_route_table.TargetVPC-private-route-table-0.id
    subnet_id = aws_subnet.TargetVPC-private-a-web.id
}

# resource "aws_route_table_association" "TargetVPC-private-route-table-0-Association1" {
#     route_table_id = aws_route_table.TargetVPC-private-route-table-0.id
#     subnet_id = aws_subnet.TargetVPC-private-a-db.id
# }

resource "aws_route_table_association" "TargetVPC-private-route-table-1-Association" {
    route_table_id = aws_route_table.TargetVPC-private-route-table-1.id
    subnet_id = aws_subnet.TargetVPC-private-b-web.id
}

# resource "aws_route_table_association" "TargetVPC-private-route-table-1-Association1" {
#     route_table_id = aws_route_table.TargetVPC-private-route-table-1.id
#     subnet_id = aws_subnet.TargetVPC-private-b-db.id
# }


# comment below resources

resource "aws_security_group" "RI-SG" {
    description = "Security Group for Replication Instance"
    name = "RI-SG"
    tags = {
        Name = "RI-SG"
    }
    vpc_id = aws_vpc.TargetVPC.id
    egress {
        cidr_blocks = [
            "0.0.0.0/0"
        ]
        protocol = "-1"
        from_port = 0
        to_port = 0
    }
}

resource "aws_security_group" "DB-SG" {
    description = "Security Group for the target database"
    name = "DB-SG"
    tags = {
        Name = "DB-SG"
    }
    vpc_id = aws_vpc.TargetVPC.id
    ingress {
        security_groups = [
            "${aws_security_group.RI-SG.id}"
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

resource "aws_db_subnet_group" "RDSDBSubnetGroup" {
    description = "Subnets where RDS will be deployed"
    name = "database-subnet-group"
    subnet_ids = [
        aws_subnet.TargetVPC-private-a-db.id,
        aws_subnet.TargetVPC-private-b-db.id
    ]
}

