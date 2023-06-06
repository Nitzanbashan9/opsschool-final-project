resource "aws_iam_role" "kandula_service_account" {
  name                 = "kandula-service-account"
  assume_role_policy   = data.aws_iam_policy_document.service_account_assume_role.json
}

resource "aws_iam_role_policy_attachment" "kandula_admin" {
  role       = aws_iam_role.kandula_service_account.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "aws_iam_policy_document" "service_account_assume_role" {
  statement {
    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    effect = "Allow"

    principals {
      type        = "Federated"
      identifiers = [format("arn:aws:iam::%s:oidc-provider/%s", var.aws_account_number, var.eks_cluster_oidc_issuer)]
    }

    condition {
      test     = "StringEquals"
      values   = ["sts.amazonaws.com"]
      variable = format("%s:aud", var.eks_cluster_oidc_issuer)
    }
  }
}
