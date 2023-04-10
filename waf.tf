####################
# WAF
####################
#IPset
#resource "aws_wafv2_ip_set" "UserIP" {
#  provider = aws.east
#  name               = "UserIP"
#  description        = "User IP set"
#  scope              = "CLOUDFRONT"
#  ip_address_version = "IPV4"
#
#
#  addresses = [
#    "61.215.150.186/32",
#    "118.86.228.127/32",
#    "106.168.66.13/32",
#    "203.124.80.95/32",
#    "106.72.47.34/32",
#    "150.249.201.147/32",
#    "106.184.148.66/32",
#    "125.12.160.119/32",
#    "125.12.152.43/32",
#    "133.200.193.33/32",
#    "27.139.135.230/32",
#    "118.240.210.144/32",
#    "113.33.153.186/32",
#    "112.137.46.68/32",
#    "180.149.191.89/32"#Z
#  ]
#}

#ACL
resource "aws_wafv2_web_acl" "cloudfront_acl" {
  name        = "cloudfront_acl"
  scope       = "CLOUDFRONT"
  provider = aws.east

  default_action {
    allow {}
  }

  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 2
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesCommonRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesSQLiRuleSet"
    priority = 3
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesSQLiRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesSQLiRuleSet"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWSManagedRulesAmazonIpReputationList"
    priority = 4
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAmazonIpReputationList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesAmazonIpReputationList"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesKnownBadInputsRuleSet"
    priority = 5
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesKnownBadInputsRuleSet"
      sampled_requests_enabled   = true
    }
  }
  rule {
    name     = "AWSManagedRulesAnonymousIpList"
    priority = 6
    override_action {
      none {}
    }
    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesAnonymousIpList"
        vendor_name = "AWS"
      }
    }
    visibility_config {
      cloudwatch_metrics_enabled = false
      metric_name                = "AWSManagedRulesAnonymousIpList"
      sampled_requests_enabled   = true
    }
  }


  visibility_config {
    cloudwatch_metrics_enabled = false
    metric_name                = "cloudfront_acl"
    sampled_requests_enabled   = true
  }
  
}



