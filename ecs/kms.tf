resource "aws_kms_key" "ashirt" {
  count       = var.kms ? 1 : 0
  description = "ashirt default key"
  #deletion_window_in_days = 10
  tags = {
    Name = "${var.app_name}-key"
  }
}

resource "aws_kms_alias" "ashirt" {
  count         = var.kms ? 1 : 0
  name          = "alias/ashirt"
  target_key_id = aws_kms_key.ashirt[count.index].key_id
}
