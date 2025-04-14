#!/bin/bash
set -eo pipefail

# Configuration
TF_DIR="./"
LOG_FILE="deploy-$(date +%Y%m%d).log"
#TF_BUCKET="secure-upload-system2024040322"
#REGION="us-east-1"

log() {
    echo -e "\n[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}



deploy() {
    cd "$TF_DIR"
    terraform fmt
    terraform init -reconfigure
    terraform validate
    terraform plan -out=tfplan

#    if [[ $confirm == "yes" || "y"  || "YES" ]]; then
    read -p "Apply changes? (yes/no): " confirm
    if [[ "$confirm" =~ ^(yes|y|YES|Y)$ ]]; then
        terraform apply tfplan
        terraform output -json admin_credentials > credentials.json
    fi
}

main() {
#    init_backend
    deploy
    log "Deployment complete. Log: $LOG_FILE"
}

main 2>&1 | tee -a "$LOG_FILE"



