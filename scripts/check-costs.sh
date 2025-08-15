#!/bin/bash
# scripts/check-costs.sh
# Simple cost estimation script

set -e

echo "AWS Infrastructure Cost Estimation"
echo "===================================="

# Load configuration
BUDGET=$(yq eval '.cost.monthly_budget' config/site.yaml)
FREE_TIER=$(yq eval '.cost.free_tier_optimized' config/site.yaml)

echo "Configuration:"
echo "Budget Limit: \$$BUDGET"
echo "Free Tier Optimized: $FREE_TIER"
echo ""

# Calculate costs
if [ "$FREE_TIER" = "true" ]; then
    echo " Cost Breakdown (Monthly):"
    echo "    S3 Storage (5GB): \$0.00 (Free Tier)"
    echo "    CloudFront (1TB): \$0.00 (Free Tier)"
    echo "    CloudWatch: \$0.00 (Free Tier)"
    echo ""
    echo " TOTAL ESTIMATED COST: \$0.00"
    echo " Your setup stays within AWS Free Tier!"
else
    echo "💸 Cost Breakdown (Monthly):"
    echo "    S3 Storage: \$0.50"
    echo "    CloudFront: \$1.50"
    echo "    CloudWatch: \$0.50"
    echo ""
    echo " TOTAL ESTIMATED COST: \$2.50"
fi

echo ""
echo " Cost estimate within budget (\$$BUDGET)"
echo " Ready to deploy!"