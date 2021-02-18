#!/bin/bash

reg=eu-west-2

ebsn=$1

pvcn=`aws ec2 describe-volumes --region $reg --volume-ids $ebsn --output text --query "Volumes[*].{ID:VolumeId, Name:Tags}" | grep 'pvc/name' |awk '{print $3}'|grep pvc`
pvn=`aws ec2 describe-volumes --region $reg --volume-ids $ebsn --output text --query "Volumes[*].{ID:VolumeId, Name:Tags}" | grep 'pv/name' |awk '{print $3}'`
ns=`aws ec2 describe-volumes --region $reg --volume-ids $ebsn --output text --query "Volumes[*].{ID:VolumeId, Name:Tags}" | grep 'pvc/namespace' |awk '{print $3}'`
app=${pvcn::-4}

kubectl delete pvc $pvcn -n $ns

cat <<EOT > pv.yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  annotations:
    kubernetes.io/createdby: aws-ebs-dynamic-provisioner
    pv.kubernetes.io/provisioned-by: kubernetes.io/aws-ebs
  finalizers:
  - kubernetes.io/pv-protection
  labels:
    failure-domain.beta.kubernetes.io/region: $reg
    failure-domain.beta.kubernetes.io/zone: eu-west-2a
  name: $pvn
spec:
  accessModes:
  - ReadWriteOnce
  awsElasticBlockStore:
    fsType: ext4
    volumeID: aws://eu-west-2a/$ebsn
  capacity:
    storage: 1Gi
  claimRef:
    apiVersion: v1
    kind: PersistentVolumeClaim
    name: $pvcn
    namespace: $ns
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: failure-domain.beta.kubernetes.io/zone
          operator: In
          values:
          - eu-west-2a
        - key: failure-domain.beta.kubernetes.io/region
          operator: In
          values:
          - $reg
  persistentVolumeReclaimPolicy: Retain
  storageClassName: aws-retain
  volumeMode: Filesystem
EOT

kubectl apply -f pv.yaml

cat <<EOT > pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  annotations:
    volume.beta.kubernetes.io/storage-provisioner: kubernetes.io/aws-ebs
  finalizers:
  - kubernetes.io/pvc-protection
  labels:
    app: $app
  name: $pvcn
  namespace: $ns
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: aws-retain
  volumeMode: Filesystem
  volumeName: $pvn
status:
  accessModes:
  - ReadWriteOnce
  capacity:
    storage: 1Gi
EOT

kubectl apply -f pvc.yaml -n $ns
