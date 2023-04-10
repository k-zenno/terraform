####################
#静的コンテンツ配置用バケット
####################
resource "aws_s3_bucket" "static-content" {
  bucket = "static-content-bft"

}

#バケットポリシー設定
resource "aws_s3_bucket_policy" "static-content" {
    bucket = aws_s3_bucket.static-content.id
    policy = data.aws_iam_policy_document.static-content.json
}

#バケットポリシー定義
data "aws_iam_policy_document" "static-content" {
  statement {
    sid    = "Allow CloudFront"
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static-content.iam_arn]
    }
    actions = [
        "s3:GetObject"
    ]
    resources = [
        "${aws_s3_bucket.static-content.arn}/*"
    ]
  }
}

####################
#アーティファクトストア用バケット
####################
#fargateデプロイ用パイプライン
resource "aws_s3_bucket" "fargate-pipeline" {
  bucket = "s3-fargate-artifactstore-bft"
}

#reactデプロイ用パイプライン
resource "aws_s3_bucket" "react-pipeline" {
  bucket = "s3-react-artifactstore-bft"
}

