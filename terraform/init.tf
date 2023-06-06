terraform { 
    backend "s3" {
        bucket = "opsschool-finalproject"
        key = "opsschool-finalproject-always.tfstate"
        region = "us-east-1"
        dynamodb_table = "tf_lock"
        profile = "default"
    }
}
