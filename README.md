# Home Assignment

## Flask App

A simple _'Hello World'_ flask app listening on `0.0.0.0:8888`

Build and run on docker with

```
$ cd app/
$ docker build -t hello_world .
$ docker run -dp 8888:8888 -t hello_world
```

Image can be push to a container registry

---

## Terraform

### [EKS Module](./iac/EKS/main.tf)

Creates EKS cluster on AWS.

| Inputs               |        Default        |
| :------------------- | :-------------------: |
| az_count             |           2           |
| cidr_block           |     "10.0.0.0/16"     |
| cluster_name         | "Hello_World_Cluster" |
| cluster_desired_size |           2           |
| cluster_max_size     |           4           |
| cluster_min_size     |           2           |

### [K8s Module](./iac/K8s/main.tf)

Creates ECR config secret and AWS LB Ingress controller

---

## K8s Manifests

### [Ingress](./k8s/ingress.yml)

Deploys AWS internet facing ALB that directs traffic into the cluster

### [Service](./k8s/service.yml)

Deploys K8s Node Port Service that directs traffic into _Hello_World_ deployment pods

### [Deployment](./k8s/deployment.yml)

Deploys K8s Deployment set of _Hello_World_ app image from AWS ECR

---

## CI/CD Pipelines

Actions Secrets:

- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- CLUSTER_NAME

### [Image Creation Pipeline](./.github/workflows/build-n-push.yml)

Builds _Hello_World_ image and push it to AWS ECR

Triggers:

- Changes on _app_ directory
- Manual trigger

Action flow:

1. Checkout this repository
2. Configure AWS credentials (with AWS secrets)
3. Login to ECR registry
4. Build and push image to ECR

### [Deploy K8s Manifests](./.github/workflows/deploy.yml)

Deploys the K8s manifests into EKS cluster

Triggers:

- Changes on _k8s_ directory
- Manual trigger

Action flow:

1. Checkout this repository
2. Configure AWS credentials (with AWS secrets)
3. Setup kubeconfig for EKS cluster management
4. Apply manifest and get app URL
5. Output URL on job summery
