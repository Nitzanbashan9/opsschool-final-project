terraform { 
    backend "s3" {
        bucket = "opsschool-midproject"
        key = "opsschool-midproject.tfstate"
        region = "us-east-1"
        dynamodb_table = "tf_lock"
        profile = "default"
    }
}