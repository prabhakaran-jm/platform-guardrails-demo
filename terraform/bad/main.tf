terraform {
  required_providers {
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
}

# Mocking cloud infrastructure metadata using null_resource triggers
# so we don't require live cloud credentials to demonstrate IaC policy checks.
resource "null_resource" "mock_database" {
  triggers = {
    # INTENTIONAL FAILURE: public access allowed
    public_access = "true"
    # INTENTIONAL FAILURE: encryption disabled
    encryption_enabled = "false"
    # INTENTIONAL FAILURE: owner and environment tags omitted
    owner       = ""
    environment = ""
  }
}
