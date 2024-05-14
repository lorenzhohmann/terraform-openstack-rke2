# HS-Fulda NetLab OpenStack RKE2 Example

This guide outlines the steps to set up an RKE2 Kubernetes cluster on OpenStack using Terraform, based on [this repository](https://github.com/zifeo/terraform-openstack-rke2).

## Attention
This example implements the deactivation of the validation of all TLS certificates by default. **Never** use this code in a production environment.

## Usage

### Step 1: Clone the Repository

```sh
git clone https://github.com/Stinktopf/terraform-openstack-rke2.git
```

### Step 2: Configure Terraform Variables

Navigate to the `example/hs-fulda` folder and create a `terraform.tfvars` file with your OpenStack credentials:

```hcl
project  = "CloudComp<your-group-number>"
username = "CloudComp<your-group-number>"
password = "<your-password>"
```

### Step 3: Initialize and Apply Terraform

Run the following commands inside the folder:

```sh
terraform init
terraform apply
```

### Step 4: Fetch kubeconfig File

#### Linux Users

The final step fetches the `kubeconfig` file for Kubernetes clients like `kubectl` and `helm` automatically using `rsync` and `yq`. Install `yq` from [here](https://github.com/mikefarah/yq/releases).

#### Windows Users

If running Terraform on Windows, fetching `rke2.yaml` via `ssh` and `rsync` will fail without `rsync` and `yq`. The RKE2 setup will still succeed. You have four options:

**Option 1: SSH**

Manually log in and fetch `rke2.yaml` by assigning a temporary floating IP:

```sh
ssh ubuntu@<floating-ip>
```

**Option 2: SCP**

Use `scp` to copy the `kubeconfig` file by assigning a temporary floating IP:

```sh
scp ubuntu@<floating-ip>:/etc/rancher/rke2/CloudComp<your-group-number>-k8s.rke2.yaml .
```

**Option 3: WSL**

Use Windows Subsystem for Linux (WSL/WSL2) to run Terraform. Install `yq` from [here](https://github.com/mikefarah/yq/releases).

**Option 4: Install rsync and yq**

Install `rsync` from [here](https://www.rsync.net/resources/howto/windows_rsync.html) and `yq` from [here](https://github.com/mikefarah/yq/releases).

### Step 5: Handle Deployment Issues

If stages fail, rerun `terraform apply` to resume deployment. Modify cluster parameters (e.g., node count) in the [main.tf](https://github.com/srieger1/terraform-openstack-rke2/blob/main/examples/hs-fulda/main.tf) file and rerun `terraform apply`.

### Step 6: Use Your Kubernetes Cluster

After deployment, use `kubectl`, `helm`, etc., with your RKE2 Kubernetes cluster:

```sh
export KUBECONFIG=CloudComp<your-group-number>-k8s.rke2.yaml
watch kubectl get nodes,pods -o wide -n kube-system
```

After about four minutes, all pods should be running in the kube-system namespace and you can deploy workloads, such as WordPress:

```sh
helm install my-release oci://registry-1.docker.io/bitnamicharts/wordpress
```

Check deployment status:

```sh
watch kubectl get svc,pv,pvc,pods -o wide --namespace default
```

You can access WordPress using the `EXTERNAL-IP` from `kubectl get svc -n default -w my-release-wordpress`.

### Step 7: Clean Up

Before running `terraform destroy`, delete workloads:

```sh
helm uninstall my-release
terraform destroy
```

The WordPress Helm Chart creates volumes in OpenStack that need to be deleted manually. If these volumes are not deleted, it can cause issues with the available quotas.

### Useful tools

- For managing multiple Kubernetes clusters, consider using [kubectx](https://github.com/ahmetb/kubectx). 
- For an enhanced terminal-based UI for Kubernetes, try [k9s](https://github.com/derailed/k9s).