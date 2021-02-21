// < User Credentials >

provider "aws" {
  region = "ap-south-1"
  profile = "Kaizoku"
}

// < /User Credentials >

# Detailed Explanation -> https://pewxh.medium.com/vpc-infrastructure-using-terraform-along-with-nat-gateway-3da47459ecb
# ------------------------------------------------->



// < Key-Pair Generation >

resource "tls_private_key" "KeyGen" {
 algorithm = "RSA"
 rsa_bits = 4096
} // Key Generation Using RSA Algorithm
resource "local_file" "KeyFile" {
 content = tls_private_key.KeyGen.private_key_pem
 filename = "TerraKey.pem"
 file_permission = 0400
} // Copying the Key Content to a local file  
resource "aws_key_pair" "KeyAWS" {
 key_name = "TerraKey"
 public_key = tls_private_key.KeyGen.public_key_openssh
} // Uploading the key in AWS to create a new Key Pair

// < /Key-Pair Generation >
// < VPC Creation >

resource "aws_vpc" "TerraVPC" {
  tags = {
    Name = "myVPC"
  }
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames  = true
}

// < /VPC Creation >
// < SUBNET >

// < Public Subnet >

resource "aws_subnet" "publicSN" {
  tags = {
    Name = "subnet_public"
  }
  vpc_id     = aws_vpc.TerraVPC.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"

  map_public_ip_on_launch = true

}

// < /Public Subnet >
// < Private Subnet >

resource "aws_subnet" "privateSN" {
  tags = {
    Name = "subnet_private"
  }
  vpc_id     = aws_vpc.TerraVPC.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
}

// < /Private Subnet >

// < /SUBNET >
// < Internet Gateway >

resource "aws_internet_gateway" "gateway" {
  tags = {
    Name = "iGateWay"
  }
  vpc_id = aws_vpc.TerraVPC.id
}

// < /Internet Gateway >
// < Routing Table >

resource "aws_route_table" "ig_rt" {
  vpc_id = aws_vpc.TerraVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags = {
    Name = "igRouteTable"
  }
}
resource "aws_route_table_association" "publicAssociation" {
  subnet_id      = aws_subnet.publicSN.id
  route_table_id = aws_route_table.ig_rt.id
}

// < /Routing Table >

// < Elastic IP >

resource "aws_eip" "Eip"{
    depends_on = [ "aws_internet_gateway.gateway"]
    vpc        = true
}

// < /Elastic IP >

// < NAT  Gateway >

resource "aws_nat_gateway" "NATgatway" {
    tags = {
        Name = "gatewayNAT"
    }
    depends_on = [ "aws_internet_gateway.gateway"]
    allocation_id = aws_eip.Eip.id
    subnet_id = aws_subnet.publicSN.id    
}

// < /NAT Gateway >

// < RouteTable NAT >

resource "aws_route_table" "NAT_rt" {
    tags = {
        Name = "NAT_Route"
    }
    vpc_id = aws_vpc.TerraVPC.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_nat_gateway.NATgatway.id
    }
}

// < /RouteTable NAT >

//< NAT RouteTable Association >

resource "aws_route_table_association" "NAT_asso" {
    subnet_id = aws_subnet.privateSN.id
    route_table_id = aws_route_table.NAT_rt.id
}

//< /NAT RouteTable Association>


// < Security Groups >

// < Database >

resource "aws_security_group" "database" {
  name        = "mysql"
  description = "Allow SSH and MYSQL"
  vpc_id      = aws_vpc.TerraVPC.id

  ingress {
    description = "MYSQL"
    protocol    = "tcp"
    from_port   = 3306
    to_port     = 3306
    security_groups = [aws_security_group.webserver.id]
    
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "DatabaseSG"
  }
}
// < /Database >
// < Webserver >

resource "aws_security_group" "webserver" {
  name        = "for_wordpress"
  description = "Allow HTTPS n SSH"
  vpc_id      = aws_vpc.TerraVPC.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
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

  tags = {
    Name = "mywebserver_sg"
  }
}

// < /Webserver >

// < /Security Groups >

// < Instance Launch >

// < MySql >
resource "aws_instance" "mysql" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.privateSN.id
  vpc_security_group_ids = [aws_security_group.database.id]
  key_name = "TerraKey"
  

 tags = {
    Name = "MySql_os"
  }

}
// < /MySql>
// < WordPress >
resource "aws_instance" "wordpress" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.publicSN.id
  vpc_security_group_ids = [aws_security_group.webserver.id]
  key_name = "TerraKey"
  

  tags = {
    Name = "wordpress_os"
  }

}
// < /WordPress >

// < /Instance Launch >