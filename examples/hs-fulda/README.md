# HS-Fulda NetLab OpenStack RKE2 example

based on https://github.com/zifeo/terraform-openstack-rke2

## Usage

Start by cloning the repo

```
git clone -b hsfulda-example https://github.com/srieger1/terraform-openstack-rke2.git
```

Go to the example/hs-fulda folder and create a terraform.tfvars file
containing your OpenStack credentials, e.g.:

```
project     = "CloudComp<your-group-number>"
username    = "CloudComp<your-group-number>"
password    = "<your-password>"
```

Run terraform inside the folder:

```
terraform init
terraform apply
```

The final step of the terraform template fetches the kubeconfig
file that can be used with regular Kubernetes clients/tools like
kubectl, helm etc. To fetch the config file from the k8s server,
the template uses rsync and yq. You can install yq from
https://github.com/mikefarah/yq/releases.
If you're using Windows, rsync is typcially not available. You can
then use scp ```scp ubuntu@<floating-ip>:/etc/rancher/rke2/rke2.yml```
to copy the file or ssh ```ssh ubuntu@<floating-ip>``` into the
controller node that has kubectl already installed:

If stages fail, you can run ```terraform apply``` again. It will
resume the deployment and execute the remaining steps. This is
also possible after changing the cluster config by modifying
the parameters (esp. cluster node count) in
[main.tf](https://github.com/srieger1/terraform-openstack-rke2/blob/main/examples/hs-fulda/main.tf)
to some extend (i.e., if you don't modify content that terraform
is not able to handle correctly for redeployment).

Wait for the deployment to finish. Afterwards you can use kubectl,
helm etc. to use your RKE2 Kubernetes cluster. You can see the
status of your cluster using:

```
kubectl --kubeconfig k8s.rke2.yaml get nodes -o wide
kubectl --kubeconfig k8s.rke2.yaml get pods -n kube-system
```

After essential kube-system pods are deployed and running, you can
deploy workloads to your cluster, e.g., wordpress:

```
helm install my-release oci://registry-1.docker.io/bitnamicharts/wordpress
```

You can see the deployment status of wordpress using:

```
export KUBECONFIG=k8s.rke2.yaml
kubectl get svc --namespace default -w my-release-wordpress
kubectl get pv --namespace default
kubectl get pvc --namespace default
kubectl get pods --namespace default
...
```

To do a clean delete, you should first delete the workloads that were
deployed, as terraform only knows the initial state and additional
volumes as well as load balancer are automatically deployed in OpenStack by
the openstack-cloud-provider in the deployed RKE2 cluster (see, e.g.:
```kubectl --kubeconfig k8s.rke2.yaml logs openstack-cloud-controller-manager-...```)
and hence not included in the terraform state.

```
helm --kubeconfig k8s.rke2.yaml uninstall my-release
terraform destroy
```

Check that load balancers and volumes possibly created by the helm chart
deployment and not contained in the terraform state, as descirbed above,
are deleted.

You can change the number of deployed agents/nodes, RKE2 version,
volume sizes etc. by changing the parameters in
[main.tf](https://github.com/srieger1/terraform-openstack-rke2/blob/main/hs-fulda/main.tf)

## Windows

If you use a Windows machine to run terraform, the last step of the
deployment, that fetches rke2.yaml kubeconfig file via ssh and rsync
will fail if you don't have rsync and yq installed. No worries.
The entire RKE2 setup will succeed in the background (on the
deployed instances) regardless of that.

To use kubectl you can fetch the kubeconfig from /etc/rancher/rke2/rke2.yml
from the server instance. You can login to the RKE2 server instance
by using the floating IP created by terraform as shown for the
failing SSH command and login using your SSH key. As soon as RKE2
is ready, you find kubectl preinstalled on the instance and only need
to install helm (https://helm.sh/docs/helm/helm_install/) if you want
to follow the README.

Otherwise you can install rsync (https://www.rsync.net/resources/howto/windows_rsync.html)
and yq (https://github.com/mikefarah/yq/releases) on your Windows
machine.

Another option is to install Windows Subsystem for Linux (WSL/WSL2)
providing rsync and run terraform from there.
