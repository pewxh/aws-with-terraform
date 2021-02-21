// <Providers>
provider "kubernetes" {
    config_context_cluster = "minikube"
}
provider "aws" {
    profile = "Kaizoku"
    region = "ap-south-1"
}
// </Providers>

# Detailed Explanation -> https://pewxh.medium.com/yet-another-wordpress-a57cee4bd9e4
# ----------------------------------------------->
// < Front End >
resource "null_resource" "start_minikube"{
    provisioner "local-exec" {
        command = "minikube start"
    }
}
resource "kubernetes_deployment" "wordpress" {
    metadata {
        name= "wordpress"
    }
   spec {
    replicas = 1
    selector {
        match_labels = {
            env      = "frontend"
            region   = "IN"
            app      = "wordpress-kube"
        }
        match_expressions {
        key      = "env"
        operator = "In"
        values   = ["frontend", "webserver"]
        }
    }
    template {
        metadata {
          labels = {
            env    = "frontend"
            region = "IN"
            app    = "wordpress-kube"
                }
            }
    spec {
        container {
            image = "wordpress:5.1.1-php7.3-apache"
            name  = "wordpress-kube"
        }
      }
    }
  }
}
resource "kubernetes_service" "kube_" {
 metadata {
 name = "service"
 }
 spec {
     selector = {
          app = kubernetes_deployment.wordpress.spec.0.template.0.metadata[0].labels.app
       }
    port {
       node_port   = 32123
       port        = 80
       target_port = 80
      }
      type = "NodePort"
   }
}
// < /Front End >

// < Back End >
resource "aws_security_group" "SG_DB" {
  	name        = "Tf_SG_MySql"
  	description = "allows inbound port 3306"
  	ingress {
    		from_port   = 3306
    		to_port     = 3306
    		protocol    = "tcp"
            cidr_blocks = ["0.0.0.0/0"]
  	    }
    egress {
    		from_port       = 0
    		to_port         = 0
    		protocol        = "-1"
    		cidr_blocks     = ["0.0.0.0/0"]
  	    }
	tags = {
		Name = "SG_DB"
	}
} 
resource "aws_db_instance" "RDS" {
    tags = {
 	    Name = "Tf_DB"
	}
    name                   = "wordpress_db"
	username               = "Kaizoku"
	password               = "redhatpass"
	allocated_storage      = 25
    vpc_security_group_ids = [aws_security_group.SG_DB.id]
	storage_type           = "gp2"
	identifier             = "mysql"
	engine                 = "mysql"
    engine_version         = "5.7"
	instance_class         = "db.t2.micro"
	publicly_accessible    = true
	port                   = 3306
	parameter_group_name   = "default.mysql5.7"
	skip_final_snapshot    = true
}
output "display_dns" {
  value = aws_db_instance.RDS.address
}
// < /Back End >