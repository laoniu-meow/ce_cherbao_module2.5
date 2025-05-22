# Scan all items (warning: expensive on large tables):
aws dynamodb scan \
  --table-name ce10-laoniu \
  --region ap-southeast-1 \
  --output table

# Get a specific item:
aws dynamodb get-item \
  --table-name ce10-laoniu \
  --region ap-southeast-1 \
  --key '{"ISBN": {"S": "1234567890"}, "Genre": {"S": "Fiction"}}'

# Verify Permission
aws dynamodb list-tables
aws dynamodb scan --table-name <table-name>
aws dynamodb delete-table --table-name <table-name>