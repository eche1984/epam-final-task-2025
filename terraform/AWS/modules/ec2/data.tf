data "aws_key_pair" "movie-analyst-ansible" {
  key_name = "movie-analyst-ansible_dev"
}

data "aws_key_pair" "movie-analyst-frontend" {
  key_name = "movie-analyst-frontend_dev"
}

data "aws_key_pair" "movie-analyst-backend" {
  key_name = "movie-analyst-backend_dev"
}
