# ce_cherbao_module2.5/main.tf

provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = var.enable_dns_hostnames
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  count = var.create_igw ? 1 : 0

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.azs[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.azs[1]

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "database_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidr[0]
  availability_zone = var.azs[1]

  tags = {
    Name = "database-subnet-a"
  }
}

resource "aws_subnet" "database_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidr[1]
  availability_zone = var.azs[2]

  tags = {
    Name = "database-subnet-b"
  }
}

resource "aws_nat_gateway" "nat" {
  count = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "main-nat-gateway"
  }
}

resource "aws_eip" "nat" {
  count = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  
  depends_on = [aws_internet_gateway.igw]
}

# Creating Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw[0].id
  }

  tags = {
    Name = "public-rt"
  }
}

# resource "aws_route_table_association" "public" {
#   subnet_id      = aws_subnet.public.id
#   route_table_id = aws_route_table.public.id
# }

resource "aws_route_table_association" "database_a" {
  count          = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.database_a.id
  route_table_id = aws_route_table.private[0].id
}

resource "aws_route_table_association" "database_b" {
  count          = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.database_b.id
  route_table_id = aws_route_table.private[0].id
}

# Creating Private Route Table (if using NAT gateway):
resource "aws_route_table" "private" {
  count  = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat[0].id
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = var.enable_nat_gateway && var.single_nat_gateway ? 1 : 0
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private[0].id
}

# Retrieve latest Amazon Linux 2 AMI ID
data "aws_ssm_parameter" "amzn2_ami" {
  name            = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

# Security Group to allow SSH
resource "aws_security_group" "ssh_sg" {
  name        = "ce10-laoniu-sgp"      # Change the security group name
  description = "Allow SSH access"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH from allowed CIDRs"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_ssh_cidr
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ce10-laoniu-sgp"      # Change the security group name
  }
}

# Create EC2 Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.amzn2_ami.value
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  key_name                    = var.ssh_key_name
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id]
  associate_public_ip_address = true

  tags = {
    Name = "ce10-laoniu-ec2instance"
  }
}

# Create RDS Database
resource "aws_security_group" "rds_sg" {
  name        = "ce10-laoniu-rds-sg"
  description = "Allow access from EC2 to RDS"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.ssh_sg.id] # allow from EC2 SG
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ce10-laoniu-rds-sg"
  }
}

# Add subnet for the database
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "ce10-laoniu-db-subnet-group"
  subnet_ids = [
    aws_subnet.database_a.id,
    aws_subnet.database_b.id,
  ]

  tags = {
    Name = "ce10-laoniu-db-subnet-group"
  }
}

# Add RDS Instance
resource "aws_db_instance" "db_instance" {
  identifier              = var.db_instance_identifier
  allocated_storage       = var.db_allocated_storage
  engine                  = "mysql"
  engine_version          = "8.0"
  instance_class          = "db.t3.micro"
  db_name                 = var.db_name
  username                = var.db_username
  password                = var.db_password
  db_subnet_group_name    = aws_db_subnet_group.db_subnet_group.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  skip_final_snapshot     = true
  publicly_accessible     = false
  multi_az                = false

  tags = {
    Name = "ce10-laoniu-db"
  }
}
