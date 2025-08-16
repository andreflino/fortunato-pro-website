#!/bin/bash
# scripts/validate.sh
# Simple validation script for local testing

set -e

echo " Validating static website configuration..."

# Check if config file exists
if [ ! -f "config/site.yaml" ]; then
    echo " config/site.yaml not found"
    echo " Copy from template: cp config/site.yaml.template config/site.yaml"
    exit 1
fi

# Check if yq is installed
if ! command -v yq &> /dev/null; then
    echo " Installing yq..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
        brew install yq
    else
        sudo wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
        sudo chmod +x /usr/local/bin/yq
    fi
fi

# Validate YAML syntax
if ! yq eval '.' config/site.yaml > /dev/null 2>&1; then
    echo " Invalid YAML syntax in config/site.yaml"
    exit 1
fi

# Extract values
NAME=$(yq eval '.name' config/site.yaml)
DOMAIN=$(yq eval '.domain' config/site.yaml)
REPOSITORY=$(yq eval '.repository' config/site.yaml)
ENVIRONMENT=$(yq eval '.environment' config/site.yaml)
BUDGET=$(yq eval '.cost.monthly_budget' config/site.yaml)

ERRORS=0

echo " Configuration Summary:"
echo "   Name: $NAME"
echo "   Domain: $DOMAIN"
echo "   Environment: $ENVIRONMENT"
echo "   Monthly Budget: \$$BUDGET"
echo ""

# Validate required fields
if [ "$NAME" = "null" ] || [ -z "$NAME" ]; then
    echo " Missing required field: name"
    ERRORS=$((ERRORS + 1))
fi

if [ "$DOMAIN" = "null" ] || [ -z "$DOMAIN" ]; then
    echo " Missing required field: domain"
    ERRORS=$((ERRORS + 1))
fi

if [ "$REPOSITORY" = "null" ] || [ -z "$REPOSITORY" ]; then
    echo " Missing required field: repository"
    ERRORS=$((ERRORS + 1))
fi

# Validate environment
if ! echo "development staging production" | grep -q "$ENVIRONMENT"; then
    echo " Invalid environment: $ENVIRONMENT"
    ERRORS=$((ERRORS + 1))
fi

# Check if HTML file exists
if [ ! -f "./fortunato-website/index.html" ]; then
    echo " ./fortunato-website/index.html not found"
    ERRORS=$((ERRORS + 1))
fi

# Final result
echo ""
if [ $ERRORS -eq 0 ]; then
    echo " All validations passed!"
    echo " Ready to deploy!"
    exit 0
else
    echo " Found $ERRORS validation errors"
    exit 1
fi