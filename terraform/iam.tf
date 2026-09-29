resource "aws_iam_user" "user" {
  name = var.iam_user_name
  path = "/"
}

data "aws_iam_policy_document" "user" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.backups.arn}/${var.backup_prefix}/*"]
  }
}

resource "aws_iam_user_policy" "user" {
  name   = "smart-backup-upload"
  user   = aws_iam_user.user.name
  policy = data.aws_iam_policy_document.user.json
}
