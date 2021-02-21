provider "aws"{
    region = "ap-south-1"
    profile = "Kaizoku" // Replace it by your profile
} // AWS Profile Configuration

// < GitHub Repo URL >

variable "github_url"{
    type = string 
    default = "https://github.com/pewxh/animesite" // Replace it by your GitHub Repo link
}

// https://www.linkedin.com/pulse/automated-website-deployment-using-aws-terraform-github-piyush-mehta/

# ----------------------------------------------------------->


									    // Key Generation

resource "null_resource" "ssh-keygen"{
	provisioner "local-exec"{
	command = "ssh-keygen -f TerraKey -N Beast -N Beast" // Terrakey is filename , Beast is NewPassPhrase : you can choose accordingly
	}
} 
resource "tls_private_key" "keypair"{
	depends_on = [null_resource.ssh-keygen]
	algorithm = "RSA"
}
resource "aws_key_pair" "key"{
	depends_on = [ null_resource.ssh-keygen , tls_private_key.keypair ]
	key_name = "TerraKey" // Choose Accordingly
	public_key = tls_private_key.keypair.public_key_openssh
} 


									// Security Group Generation

resource "aws_security_group" "TerraSG"{
	name = "TerraSG" //choose accordingly
	description = "KeyEnabledWithSSHandHTTPViaTerraform"
	ingress{
		description = "SSH"
		from_port = 22
		to_port = 22
		protocol = "tcp"
		cidr_blocks = ["0.0.0.0/0"]
	}
	ingress{
		description = "HTTP"
		from_port = 80
		to_port = 80
		protocol = "tcp"
		cidr_blocks = [ "0.0.0.0/0" ]
	}
	egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    }
	tags = {
		Name = "newsgtf"
	}
}


										// OS/Instance LAUNCH

resource "aws_instance" "MyOS"{
	depends_on = [aws_key_pair.key ,
		     aws_security_group.TerraSG]
	ami = "ami-052c08d70def0ac62"  // choose accordingly
	instance_type = "t2.micro"
	key_name = aws_key_pair.key.key_name
	security_groups = [ aws_security_group.TerraSG.name ]
}


										// Creating an EBS Volume

resource "aws_ebs_volume" "Ebs_gen"{
	availability_zone = aws_instance.MyOS.availability_zone
	size = 1
	tags = {
		Name = "MyEBS"
	}
}


										// Attach EBS to our OS

resource "aws_volume_attachment" "ebs_att"{
	device_name = "/dev/sdh"
	volume_id = aws_ebs_volume.Ebs_gen.id
	instance_id = aws_instance.MyOS.id
	force_detach = true
}


									// Connecting to our Remote machine and Setting up WebServer

resource "null_resource" "connection"{
	depends_on = [aws_volume_attachment.ebs_att]
									// OS CONNECTION
	connection {
		type = "ssh"
		user = "ec2-user"
		private_key = tls_private_key.keypair.private_key_pem
		host = aws_instance.MyOS.public_ip
	}
									// Setting OS
	provisioner "remote-exec"{
		inline =[
					"sudo yum -y install httpd git", 
					"sudo systemctl start httpd",
					"sudo systemctl enable httpd",
					"sudo mkfs.ext4 /dev/xvdh",
					"sudo mount /dev/xvdh /var/www/html",
					"sudo rm -rf /var/www/html/*",
					"sudo git clone ${var.github_url} /var/www/html/",   // replace $ with your desired GitHub Repo
					"sudo sudo chcon -R -v -t httpd_sys_rw_content_t /var/www/html/*" ,  // Uncomment when Forbidden Error
					"sudo systemctl restart httpd",
				]
	}
}

								// Run your site in Chrome

resource "null_resource" "chrome"{
	depends_on = [ null_resource.connection]
	provisioner "local-exec"{
		command = "start chrome ${aws_instance.MyOS.public_ip}" 
	}
}

								//Display Address in CMD/Terminal

output "AddressOfSite" {
  value = aws_instance.MyOS.public_ip
}