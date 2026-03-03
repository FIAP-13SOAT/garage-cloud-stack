########################################
# NETWORK - VPC & INTERNET ACCESS
########################################

# VPC principal da aplicação
# Responsável por isolar toda a infraestrutura
# CIDR definido para permitir expansão futura
resource "aws_vpc" "main" {
    cidr_block           = "10.0.0.0/16"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags = {
        name = "${local.projectName}-main-vpc"
    }
}

# Internet Gateway
# Permite comunicação entre recursos da VPC
# e a internet pública
resource "aws_internet_gateway" "main" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "${local.projectName}-igw"
    }
}

// subnet pública
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "${local.awsRegion}a"
    map_public_ip_on_launch = true
    tags = {
        Name = "${local.projectName}-public-subnet"
        "kubernetes.io/role/elb" = "1"
    }
}

// Segunda subnet pública para EKS (diferentes AZs)
// EKS exige subnets em pelo # Segunda subnet pública em AZ diferente (obrigatório para EKS - mínimo 2 AZs)
resource "aws_subnet" "public_subnet_b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.4.0/24"
    availability_zone = "${local.awsRegion}b"
    map_public_ip_on_launch = true
    tags = {
        Name = "${local.projectName}-public-subnet-b"
        "kubernetes.io/role/elb" = "1"
    }
}


########################################
# PUBLIC ROUTING
########################################

# Permite que recursos em subnets públicas tenham acesso direto à internet
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main.id
    }

    tags = {
        Name = "${local.projectName}-public-rt"
    }
}

# Associação da route table com subnet pública A
resource "aws_route_table_association" "public_a" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public.id
}

# Associação da route table com subnet pública B
resource "aws_route_table_association" "public_b" {
    subnet_id      = aws_subnet.public_subnet_b.id
    route_table_id = aws_route_table.public.id
}

# Subnet Privada para banco de dados
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "${local.awsRegion}a"
    map_public_ip_on_launch = false
    tags = {
        Name = "${local.projectName}-private-subnet"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

# Segunda subnet privada para RDS (obrigatório)
resource "aws_subnet" "private_subnet_b" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.3.0/24"
    availability_zone = "${local.awsRegion}b"
    map_public_ip_on_launch = false
    tags = {
        Name = "${local.projectName}-private-subnet-b"
        "kubernetes.io/role/internal-elb" = "1"
    }
}

# DB Subnet Group para RDS (requer subnets em pelo menos 2 AZs)
resource "aws_db_subnet_group" "main" {
    name       = "${local.projectName}-db-subnet-group"
    subnet_ids = [aws_subnet.private_subnet.id, aws_subnet.private_subnet_b.id]

    tags = {
        Name = "${local.projectName}-db-subnet-group"
    }
}

########################################
# NAT GATEWAY
########################################

# Elastic IP para o NAT Gateway
resource "aws_eip" "nat" {
    domain = "vpc"
}

resource "aws_nat_gateway" "main" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public_subnet.id
}

resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id

    route {
        cidr_block     = "0.0.0.0/0"
        nat_gateway_id = aws_nat_gateway.main.id
    }

    tags = {
        Name = "${local.projectName}-private-rt"
    }
}

resource "aws_route_table_association" "private_a" {
    subnet_id      = aws_subnet.private_subnet.id
    route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_b" {
    subnet_id      = aws_subnet.private_subnet_b.id
    route_table_id = aws_route_table.private.id
}
