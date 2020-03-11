#!/usr/bin/env bash

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$MYDIR/terraform-setup.sh"

terraform apply -input=false -auto-approve tfplan