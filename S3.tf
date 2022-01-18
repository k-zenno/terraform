resource "aws_s3_bucket" "bucket" {
  bucket_prefix = "static-content"
  acl = "private"

}

resource "aws_s3_bucket_policy" "bucket" {
    bucket = aws_s3_bucket.bucket.id
    policy = data.aws_iam_policy_document.static-content.json
}

data "aws_iam_policy_document" "static-content" {
  statement {
    sid = "Allow CloudFront"
    effect = "Allow"
    principals {
        type = "AWS"
        identifiers = [aws_cloudfront_origin_access_identity.static-www.content_arn]
    }
    actions = [
        "s3:GetObject"
    ]

    resources = [
        "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}