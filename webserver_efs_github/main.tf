provider "aws"{
    region = "ap-south-1"
    profile = "Kaizoku" // Replace it by your profile
} // AWS Profile Configuration

// < GitHub Repo URL >
# Detailed Explanation -> https://pewxh.medium.com/launching-web-server-using-aws-efs-terraform-and-github-77f1b561eefa
# ----------------------------------------------------->
variable "github_url"{
    type = string 
    default = "https://github.com/kaiz-O/animesite" // Replace it by your GitHub Repo link
}

// < /GitHub Repo URL >
// < Key-Pair >

resource "tls_private_key" "KeyGen" {
 algorithm = "RSA"
 rsa_bits = 4096
} // Key Generation Using RSA Algorithm
resource "local_file" "KeyFile" {
 content = tls_private_key.KeyGen.private_key_pem
 filename = "key_pair.pem"
 file_permission = 0400
} // Copying the Key Content to a local file  
resource "aws_key_pair" "KeyAWS" {
 key_name = "TerraKey"
 public_key = tls_private_key.KeyGen.public_key_openssh
} // Uploading the key in AWS to create a new Key Pair

// < /Key-Pair >

// < Security-Group >

resource "aws_security_group" "SecurityGroupGen"{
    name = "TerraSG"
    description = "security_group_with_SSH_and_HTTP_access"
    ingress{
        description = "SSH"
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    } // Inbound rule which allows connection from ALL the IPs using port 22
    ingress{
        description = "HTTP"
        from_port = 80
        to_port = 80
        protocol =  "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    } // Inbound rule which allows connection from ALL the IPs using port 80
    ingress{
        description = "NFS"
        from_port = 2049
        to_port = 2049
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    } // Inbound rule which allows connection from ALL the IPs using port 2049
    egress{
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    } // Outbound rule which allows connection to ALL the IPs using multiple  ports
    tags = {
        Name = "TerraSG"
    }
}

// < /Security-Group >


// < Instance-Launch >

resource "aws_instance" "MyOS"{
    depends_on = [
        aws_security_group.SecurityGroupGen,
        aws_key_pair.KeyAWS
    ]
    ami = "ami-052c08d70def0ac62" // RedHat AMI
    instance_type = "t2.micro"
    key_name = aws_key_pair.KeyAWS.key_name
    security_groups = [
        aws_security_group.SecurityGroupGen.name
    ]
    tags = {
        Name = "MyInstance"
    }
}

// < /Instance-Launch >

// < EFS >

resource "aws_efs_file_system" "efs"{
    depends_on = [
        aws_instance.MyOS
    ]
    creation_token = "volume"
    tags = {
        Name = "StorageEFS"
    }
} // EFS Creation

resource "aws_efs_mount_target" "alpha"{
    depends_on = [
        aws_efs_file_system.efs
    ]
    file_system_id = aws_efs_file_system.efs.id 
    subnet_id = aws_instance.MyOS.subnet_id
    security_groups = [
        aws_security_group.SecurityGroupGen.id 
    ]
}
    resource "null_resource" "copyIP"{
        provisioner "local-exec" {
            command = "echo ${aws_instance.MyOS.private_ip} > ip.txt"
        }
    }
resource "null_resource"  "connectSSH"{
    depends_on = [
        aws_efs_mount_target.alpha
    ]
    connection{
        type = "ssh"
        user = "ec2-user"
        private_key = tls_private_key.KeyGen.private_key_pem
        host = aws_instance.MyOS.public_ip
    }
    provisioner "remote-exec" {
        inline = [
            "sudo yum install httpd git -y",
            "sudo mount -t ${aws_efs_file_system.efs.id}:/ /var/www/html",
            "sudo rm -rf /var/www/html/*",
            "sudo git clone ${var.github_url} /var/www/html/",
            "sudo systemcl start httpd",
            "sudo systemctl enable httpd"
        ]
    }
}

// < /EFS >

// < S3 >

resource "aws_s3_bucket" "bucket"{
    bucket = "bucketanimesite"
    acl = "public-read"
    force_destroy = true
} // Bucket Creation
resource "null_resource" "gclone"{
    depends_on = [aws_s3_bucket.bucket]
    provisioner "local-exec" {
        command = "git clone ${var.github_url} "
    }
} // Cloning Repo in our local computer
resource "aws_s3_bucket_object" "update_bucket"{
	depends_on = [aws_s3_bucket.bucket,null_resource.gclone]
	bucket = "${aws_s3_bucket.bucket.id}"
	source = "animesite/onepiecebg.jpg" //Source of the file
	key = "onepiecebg.jpg" // Name of the file to be saved as 
	acl = "public-read"
}

// < /S3 >

// < CloudFront >

resource "aws_cloudfront_distribution" "cfront"{
	depends_on = [
        aws_s3_bucket.bucket ,
        null_resource.gclone ,
        aws_s3_bucket_object.update_bucket
    ]
	origin{
		domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
		origin_id = "newImage"
		custom_origin_config{
			http_port = 80
			https_port = 80
			origin_protocol_policy = "match-viewer"
			origin_ssl_protocols = ["TLSv1","TLSv1.1","TLSv1.2"]
		}
	}
	enabled = "true"
	default_cache_behavior{
		allowed_methods = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
		cached_methods = ["GET","HEAD"]
		target_origin_id = "newImage"
		forwarded_values{
			query_string = "false"
			cookies{
				forward = "none"
			}
		}
		viewer_protocol_policy = "allow-all"
		min_ttl = 0
		default_ttl = 3600
		max_ttl = 86400
	}
	restrictions{
		geo_restriction{
			restriction_type = "none"
		}
	}
	viewer_certificate{
		cloudfront_default_certificate = "true"
	}
}


// < /CloudFront >

// <<  Updating the Cloudfront URL in the Code >

resource "null_resource" "code_update" {
  depends_on = [
        aws_cloudfront_distribution.cfront,
        null_resource.connectSSH
    ]
  connection {
        type = "ssh"
        user = "ec2-user"
        private_key = tls_private_key.KeyGen.private_key_pem
        host = aws_instance.MyOS.public_ip
  }
  provisioner "remote-exec" {
    inline = [
        "sudo chown ec2-user /var/www/html/onepiece.css",
        "sudo echo '''< body{ background-image: url(${aws_cloudfront_distribution.cfront.domain_name});} >'''  >>/var/www/html/onepiece.css",
        "sudo systemctl restart httpd"
    ]
  }
}
// <<  /Updating the Cloudfront URL in the Code >
 
// << Runnning our new updated website in Chrome browser >>

resource "null_resource" "chrome"{
	depends_on = [ null_resource.code_update ]
	provisioner "local-exec"{
		command = "chrome ${aws_instance.MyOS.public_ip}" 
	}
}
output "AddressOfSite" {
  value = aws_instance.MyOS.public_ip
} // Displays the public IP of our webserver instance in our Terminal

// << /Runnning our new updated website in Chrome browser >>