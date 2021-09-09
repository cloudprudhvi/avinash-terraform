variable "vpc-cidr"{
    type = string
    default = "10.0.0.0/16"
}
/*variable "public-subnet-cidr"{
    type = string
    default = ""
}*/
/*variable "private-subnet-cidr" {
    type = string
    default = ""
}*/
/*variable "example-count" {
    type = count
    default = 5
}*/
variable "subnet-cidr" {
    type = list(string)
    default = ["10.0.1.0/24", "10.0.2.0/24"]
    sensitive = true
}
variable "ec2ami" {
    type = string
    default = ""
}
variable "ec2type" {
    type = list(string)
    default = ["t2.micro", "m4.large", "t2.medium"]
}



