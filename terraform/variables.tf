
variable "az" {
        default = ["us-east-1a", "us-east-1b"]
}

variable "public_cidr" {
        default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_cidr" {
        default = ["10.0.100.0/24", "10.0.200.0/24"]
}

variable "eks_private_cidr" {
        default = ["10.0.10.0/24", "10.0.20.0/24"]
}


