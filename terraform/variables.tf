
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
variable "aws_account_number" {
        default = "388840466175"
}
variable "eks_cluster_oidc_issuer" {
        default = "oidc.eks.us-east-1.amazonaws.com/id/DD840A8805478EA9C83920C7B4EADFC0"
}
