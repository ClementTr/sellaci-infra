provider "aws" {
  profile = local.profile
  region  = local.region
}

# Create a bucket
resource "aws_s3_bucket" "bucket_sellaci" {
  bucket = local.bucket_name
  tags = {
    Name        = "My bucket"
    Environment = "Prod"
  }
}

resource "aws_s3_bucket_acl" "bucket_acl" {
  bucket = aws_s3_bucket.bucket_sellaci.id
  acl    = "private"
}

# Upload an object
resource "aws_s3_bucket_object" "object" {
  bucket = aws_s3_bucket.bucket_sellaci.id
  key    = "Dockerrun.aws.json"
  source = "Dockerrun.aws.json"
  acl    = "private"
  etag   = filemd5("Dockerrun.aws.json")
}

resource "aws_iam_role" "ng_beanstalk_ec2" {
  name = "ng-beanstalk-ec2-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

# Beanstalk instance profile
resource "aws_iam_instance_profile" "ng_beanstalk_ec2" {
  name = "ng-beanstalk-ec2-user"
  role = aws_iam_role.ng_beanstalk_ec2.name
}

resource "aws_elastic_beanstalk_application" "app_sellaci" {
  name        = local.application_name
  description = "Sellaci app"
}

resource "aws_elastic_beanstalk_environment" "env_sellaci" {
  name                = local.environnement_name
  application         = aws_elastic_beanstalk_application.app_sellaci.name
  cname_prefix        = local.application_name
  solution_stack_name = "64bit Amazon Linux 2 v3.4.19 running Docker"
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.ng_beanstalk_ec2.name
  }

}

resource "aws_elastic_beanstalk_application_version" "latest" {
  name        = "latest"
  application = aws_elastic_beanstalk_application.app_sellaci.name
  description = "application version created by terraform"
  bucket      = aws_s3_bucket.bucket_sellaci.id
  key         = aws_s3_bucket_object.object.id
}
