# VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags       = { Name = "my-vpc" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "my-igw" }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags                    = { Name = "public-subnet" }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group
resource "aws_security_group" "ec2_sg" {
  vpc_id = aws_vpc.main.id
  name   = "ec2-sg"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "ec2-sg" }
}

# Key Pair (directly using your SSH public key)
resource "aws_key_pair" "terraform_key" {
  key_name   = "terraform" 
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC2wP7O4DlZZhA8LE5u5BfQ7ORMe5RR93rwZKxRLIeOj28CpRAzS2WSDNUqRsrXSt2/5Uo46Vi/H5ydqtVGjWSkTkV63bLUMz0xhs23BLpqg+tlF6wJOK4lv20NC8D5VK4S8ZpPuy502odzfX5DR1IFOS+tEiPywMCMPgjqtGiudPn5v1rXkMD3k5kUbb2NDYYqgXtKV7fHFjW6HCQTR9YFyv42mBujPqZ3J2wQUsGIo2QbFwV5vzoqmdk+lexT+fOPXbcdCD8pnelM05XqW/FXjMFcGM6DJUlDPMaxQLmDXje5FZHugwmW4gG6NbNK0admyj9gNuBf0BKmDHrlGSZ5"
}

# EC2 Instance
resource "aws_instance" "web" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1)
  instance_type          = var.instance_type
  key_name               = aws_key_pair.terraform_key.key_name
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]

  tags = { Name = "web-server" }
}

# S3 Bucket (without ACLs, as AWS blocks them now)
resource "aws_s3_bucket" "bucket" {
  bucket        = "my-bucket-${random_id.rand.hex}"
  force_destroy = true

  tags = {
    Name = "my-s3-bucket"
  }
}

# Random ID for unique bucket name
resource "random_id" "rand" {
  byte_length = 4
}

# Output EC2 Public IP
output "ec2_public_ip" {
  value = aws_instance.web.public_ip
}
