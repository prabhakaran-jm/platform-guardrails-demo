terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

resource "null_resource" "mock_database" {
  triggers = {
    # PASS: public access disabled
    public_access = "false"
    # PASS: encryption enabled
    encryption_enabled = "true"
    # PASS: owner and environment tags included
    owner       = "platform-team"
    environment = "production"
  }
}
