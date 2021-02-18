export AWS_REGION=$2
export AWS_PROFILE=$3
aws_id=$1
ns=$4


for i in `k get pvc -n $ns | awk '{ print $3 }' | tail -n +2`
do
  echo "Defining variables"
  vol_id=`aws ec2 describe-volumes --region $region --filters Name=tag:kubernetes.io/created-for/pv/name,Values=$i --query "Volumes[*].{ID:VolumeId}" --output text`
  pv_name=$i
  svc_name=`aws ec2 describe-volumes --region $region --filters Name=tag:kubernetes.io/created-for/pv/name,Values=$i --query "Volumes[*].{Tag:Tags}" --output text | grep -w 'kubernetes.io/created-for/pvc/name' | awk '{print $3}'`
  
  echo "Creating snapshot"
  aws ec2 create-snapshot --volume-id $vol_id --description '$i' --tag-specifications 'ResourceType=snapshot,Tags=[{Key=svc_name,Value=$svc_name},{Key=vol_id,Value=$vol_id}]'
  snap_id=`aws ec2 describe-snapshots --filters Name=volume-id,Values=$vol_id --query "Snapshots[*].[SnapshotId]" --output text`
  
  echo "Sharing snapshot to aws account"
  aws ec2 modify-snapshot-attribute --snapshot-id $snap_id --attribute createVolumePermission --operation-type add --user-ids $aws_id
  
done
