#!/usr/bin/env bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$MYDIR/terraform-setup.sh"

terraform validate
terraform plan -out=tfplan -input=false