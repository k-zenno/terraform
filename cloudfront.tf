#----------------------------------------------------------
#Cloudfront
#----------------------------------------------------------
#静的コンテンツ用オリジン
resource "aws_cloudfront_distribution" "Cloudfront_Childcare" {
    origin {
        domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
        origin_id = aws_s3_bucket.bucket.id
        s3_origin_config {
          origin_access_identity = aws_cloudfront_origin_access_identity.static-content.cloudfront_access_identity_path
        }
    }
    origin {
      custom_origin_config {
        http_port = "8080"
        https_port               = "443"
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
      }

      domain_name = aws_lb.ALB_Childcare.dns_name
      origin_id = aws_lb.ALB_Childcare.dns_name
     
      custom_header {
        name  = "alb-header"
        value = "bft"
      }
    }

    enabled =  true


    default_cache_behavior {
        allowed_methods = [ "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
        cached_methods = [ "GET", "HEAD" ]
        target_origin_id = aws_s3_bucket.bucket.id
        
        forwarded_values {
            query_string = false
             
            cookies {
              forward = "none"
            }
        }

        viewer_protocol_policy = "https-only"
        min_ttl = 0
        default_ttl = 86400
        max_ttl = 31536000
    }

    ordered_cache_behavior {
        path_pattern     = "/api/*"
        allowed_methods  = [ "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = aws_lb.ALB_Childcare.dns_name

        forwarded_values {
            query_string = false

            cookies {
              forward = "none"
            }
        }

        viewer_protocol_policy = "https-only"
        min_ttl                = 0
        default_ttl            = 86400
        max_ttl                = 31536000
    }

    restrictions {
      geo_restriction {
          restriction_type = "whitelist"
          locations = [ "JP" ]
      }
    }
    viewer_certificate {
        cloudfront_default_certificate = true
    }
}

resource "aws_cloudfront_origin_access_identity" "static-content" {}