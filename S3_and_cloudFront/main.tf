								// Connecting Terraform to AWS using my profile  
provider "aws"{
	region = " " //Your Region
	profile = " " // Your Profile
} 
	

								// S3 Bucket Generation

resource "aws_s3_bucket" "bucket"{
	bucket = " " //Bucket Name, should be Unique in a region
	acl = "private"
	force_destroy = "true"
	versioning {
		enabled = "true"
	}
}


								// GitHub Cloning

resource "null_resource" "gclone"{
	depends_on = [aws_s3_bucket.bucket]
	provisioner "local-exec"{
		//git should be installed in your local machine
		command = "git clone $" //Replace $ with your GitHub Repo
	}
}


								//Bucket updatation 

resource "aws_s3_bucket_object" "update_bucket"{
	depends_on = [aws_s3_bucket.bucket,null_resource.gclone]
	bucket = "${aws_s3_bucket.bucket.id}"
	source = " " //Source of the file
	key = " " // Name of the file to be saved as 
	acl = "public-read"
}


								//Using Cloud Front

resource "aws_cloudfront_distribution" "cfront"{
	depends_on = [aws_s3_bucket.bucket , null_resource.gclone , aws_s3_bucket_object.update_bucket]
	origin{
		domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
		origin_id = "newImage" //Choose accordingly
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

										//Display The new URL for the bucket item 

output "domain-name"{
	value = aws_cloudfront_distribution.cfront.domain_name
}


