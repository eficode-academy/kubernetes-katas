
# Kubernetes cluster

Create the cluster on Google Kubernetes Engine

Things to remember:

- Open the firewall to the cluster `gcloud compute firewall-rules create alltcpmike --allow tcp`
- Need to create an IAM -> service account in the project and give it the role `Kubernetes Engine -> Kubernetes Engine Developer`
- Make sure you use the region `europe-west1-b`
- Make sure you use the name `training-cluster`

# Writing and CI

Automated tests can extract Kubernetes YAML from markdown files and automatically lint them. For this to work, annotate your multi-line code blocks with both `yaml` and `k8s`. Your multi-line code block will have as its first line ````yaml,k8s`.
