terraform {
  backend "s3" {
    bucket = "secure-upload-system07042025"
    key    = "terraform/state.tfstate"
    region = "us-east-1"
  }
}