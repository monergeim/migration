# migration

1. Use aws2aws.sh script to scan required kubernetes namespace, create snapshots, parse vars to terraform var file and share snapshots to another aws account
```
./aws2aws.sh <target aws account id> <source aws region> <source aws profile> <path to source kuber config> <namespace where to backup all PVs>
./aws2aws.sh 13*********17 eu-west-2 default ~/.kube/config uat
```
2.Initiate and run terraform
```
terraform init
terraform apply -var-file vars
```
Example of vars file:
```
aws_region = "eu-west-2"
aws_access_key = "AK*************52"
aws_secret_key = "JF*****************************b5"
cluster_name = "xxxxxxx"
ns = "uat"
kube_conf = "~/.kube/xxxxxx.cfg"
snaps = {
"snap-xxxxxxxxxxxxxxxxx": {"pv": "yyyyyyyyyyyyyyyyyyyyyyyyyy", "app": "exchange-audit-service", "pvc": "exchange-audit-service-pvc",},
```
snaps part will be generated automatically
At the end you will have created namespace in target kubernetes, pvc and pv from source cluster
