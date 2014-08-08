echo "Performing hanlon dry run..."

current_dir=$(pwd)

cd ..

echo "Testing hanlon config..."
cli/hanlon -d config
echo "...testing hanlon config done"
echo

echo "Testing hanlon config ipxe..."
cli/hanlon -d config ipxe
echo "...testing hanlon config ipxe done"
echo

echo "Testing hanlon config db_check..."
cli/hanlon -d config db_check
echo "...testing hanlon config db_check done"
echo

echo "Testing hanlon image..."
cli/hanlon -d image
echo "...testing hanlon image done"
echo

echo "Testing hanlon node..."
cli/hanlon -d  node
echo "...testing hanlon image node"
echo

echo "Testing hanlon tag..."
cli/hanlon -d tag
echo "...testing hanlon tag done"
echo

echo "Testing hanlon policy..."
cli/hanlon -d  policy
echo "...testing hanlon policy done"
echo

echo "Testing hanlon model..."
cli/hanlon -d  model
echo "...testing hanlon model done"
echo

echo "Testing hanlon active_model..."
cli/hanlon -d active_model
echo "...testing hanlon active_model done"
echo

cd $current_dir

echo "Running all tests complete"
