#!/bin/bash

#set +x
aws_id=$1 #target aws id
export AWS_REGION=$2
export AWS_PROFILE=$3
export KUBECONFIG=$4
ns=$5
c=0

#clear place in vars file
sed -i '/snaps/,$d' vars
echo "snaps = {" >> vars

for i in `kubectl get pvc -n $ns | awk '{ print $3 }' | tail -n +2`;
do
  #echo "Defining variables"
  vol_id=`aws ec2 describe-volumes --region $AWS_REGION --filters Name=tag:kubernetes.io/created-for/pv/name,Values=$i --query "Volumes[*].{ID:VolumeId}" --output text`
  pv_name=$i
  pvc_name=`aws ec2 describe-volumes --region $AWS_REGION --filters Name=tag:kubernetes.io/created-for/pv/name,Values=$i --query "Volumes[*].{Tag:Tags}" --output text | grep -w 'kubernetes.io/created-for/pvc/name' | awk '{print $3}'`
  
  if [[ $pvc_name == *"volume"* ]]; then
    app='exchange-market-service'
  else
    app=${pvc_name::-4}
  fi
  
  
  #echo "Creating snapshot"
  aws ec2 create-snapshot --volume-id $vol_id --description "$i" --tag-specifications "ResourceType=snapshot,Tags=[{Key=pvc_name,Value=$pvc_name},{Key=vol_id,Value=$vol_id},{Key=Name,Value=Prod_bkp}]"
  
  snap_array[$c]=`aws ec2 describe-snapshots --filters Name=volume-id,Values=$vol_id --query "Snapshots[*].[SnapshotId]" --output text`
  echo "\"${snap_array[$c]}\": {\"pv\": \"$pv_name\", \"app\": \"$app\", \"pvc\": \"$pvc_name\",}," >> vars
  c=$((c+1))
  

done

echo "Sharing snapshot to other aws account"
for i in "${snap_array[@]}"; 
do 
  aws ec2 modify-snapshot-attribute --snapshot-id "$i" --attribute createVolumePermission --operation-type add --user-ids $aws_id 
done

echo "}" >> vars
