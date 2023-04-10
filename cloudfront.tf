#----------------------------------------------------------
#Cloudfront
#----------------------------------------------------------
#コンテンツ配信用Cloudfront
resource "aws_cloudfront_distribution" "Cloudfront_Childcare" {
    #静的コンテンツ用オリジン
    origin {
        domain_name = aws_s3_bucket.static-content.bucket_regional_domain_name
        origin_id = aws_s3_bucket.static-content.id
        s3_origin_config {
          origin_access_identity = aws_cloudfront_origin_access_identity.static-content.cloudfront_access_identity_path
        }
    }
    #API用オリジン
    origin {
      custom_origin_config {
        http_port = "80"
        https_port               = "443"
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
      }

      domain_name = aws_alb.ALB_Childcare.dns_name
      origin_id = aws_alb.ALB_Childcare.dns_name
     
      custom_header {
        name  = "alb-header"
        value = "bft"
      }
    }

    enabled =  true
    web_acl_id = aws_wafv2_web_acl.cloudfront_acl.arn
    default_root_object = "index.html"

    #静的コンテンツ用ビヘイビア
    default_cache_behavior {
        allowed_methods = [ "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
        cached_methods = [ "GET", "HEAD" ]
        target_origin_id = aws_s3_bucket.static-content.id
        
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

    #API用ビヘイビア
    ordered_cache_behavior {
        path_pattern     = "/api/*"
        allowed_methods  = [ "GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE" ]
        cached_methods   = ["GET", "HEAD"]
        target_origin_id = aws_alb.ALB_Childcare.dns_name

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
    
    #地理的制限
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

#S3用アクセス許可
resource "aws_cloudfront_origin_access_identity" "static-content" {}