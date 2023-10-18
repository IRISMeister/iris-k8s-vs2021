cat subnets.json | jq -r ".[]" |
while read -r array; do
  echo $array 
  aws efs create-mount-target --file-system-id $filesystemid --subnet-id $array --security-group $sgid
done