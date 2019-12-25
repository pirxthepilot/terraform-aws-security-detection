# Create the test VPC and use the default security group
resource "aws_vpc" "security_test" {
  cidr_block = var.cidr_block

  tags = {
    Name = "security_test"
  }
}
