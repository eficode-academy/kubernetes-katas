
# Kubernetes cluster

Create the cluster on Google Kubernetes Engine

Things to remember:

- Open the firewall to the cluster `gcloud compute firewall-rules create alltcpmike --allow tcp`
- Need to create an IAM -> service account in the project and give it the role `Kubernetes Engine -> Kubernetes Engine Developer`
- Make sure you use the region `europe-west1-b`
- Make sure you use the name `training-cluster`
