module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.5.1"

  cluster_name    = "finalproject"
  cluster_version = "1.24"

  vpc_id                         = aws_vpc.main.id
  subnet_ids                     = [aws_subnet.eks_private_subnet[0].id,aws_subnet.eks_private_subnet[1].id]
  cluster_endpoint_public_access = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"

  }
  cluster_addons = {
//    coredns = {
//      resolve_conflicts = "OVERWRITE"
//    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts        = "OVERWRITE"
      service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    }
  }


  eks_managed_node_groups = {
    az1 = {
      name = "node-group-az1"
      subnet_ids = [aws_subnet.eks_private_subnet[0].id]
      instance_types = ["t3.small"]

      labels = {
          node_az = "az1"
        }

      min_size     = 0
      max_size     = 1
      desired_size = 1
    }
    az2 = {
      name = "node-group-az2"
      subnet_ids = [aws_subnet.eks_private_subnet[1].id]
      instance_types = ["t3.small"]

      labels = {
          node_az = "az2"
        }

      min_size     = 0
      max_size     = 1
      desired_size = 1
    }
  }
}
    

# https://aws.amazon.com/blogs/containers/amazon-ebs-csi-driver-is-now-generally-available-in-amazon-eks-add-ons/ 
data "aws_iam_policy" "ebs_csi_policy" {
  arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

module "irsa-ebs-csi" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version = "4.7.0"

  create_role                   = true
  role_name                     = "AmazonEKSTFEBSCSIRole-${module.eks.cluster_name}"
  provider_url                  = module.eks.oidc_provider
  role_policy_arns              = [data.aws_iam_policy.ebs_csi_policy.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
}

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix      = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true # NOTE: This was what needed to be added

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }
}
