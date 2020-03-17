# EKS_autoscale

### Deploy an EKS cluster with autoscaling configured alongwith a sample website, load generator to desmotrate the same. Also show how a node can be removed from production for maintenance ###

**Prerequisites**
Install and login to aws cli
Intall kubectl, helm and docker<br>
**Note: This ishas only been test on a windows machine but should on other operating systems as well which Terraform supports**

**Steps:**
1. Got the docker folder, build a docker image and push to ECR

2. Get the URL of the image and update image-url variable in *terraform/varaibles.tf*

3. In CMD goto*terraform* folder and run *terraform init*
  - This will download all the necessary provisioners
  
4. Then run terraform apply to get an overview of what all will be created and type *'yes'* to apply the changes. Wait for the script to finish
  - This will create a EKS cluster with a autoscaling node group(min1 & max:4) and all other necessary resources
  - It will also deploy metrics-server, cluster-autoscaler and kubernetes-dashboard
    (to login to Dahsboard use token from *kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')* )
  - It will also deploy a simple php website which returns 'OK' while also generates some CPU load alongwith an Horizontal Pod Autoscaler(min:1 and max:10)
  - Check on AWS portal all the resources created
  - Alternatively, use kubectl to explore the cluster
  
5. Goto *loadgenerator* folder and  build a docker image and push to ECR

6. Get the URL of the image and update image-url variable in *varaibles.tf*(inside loadgenerator folder)

7. Now run *terraform init* and *terraform apply* (add --auto-aprove flag to apply to skip the approval)
  - This will create a deployment with 4 replicas that will constant hit the service. Wait for the CPU load on the service to increase and soon you will see CPU load for the service we created earlier increase which should also cause more nodes to spin up automatically
  
8. Goto drainnode and run *terraform init* and *terraform apply*
  - This will get nodes from Kubernetes cluster using *kubectl get nodes* and drain the first node from the list which will cause all pods to be evicted from the node and no further pods to be scheduled. 
  - Run *kubectl uncordon <node-name>* to return the node to its nrmal state
  
**Variables**
  - terraform/variables.tf:
    - *region:* the AWS region to use
    - *image-url:* ECR  image URL for the docker image of the website
    - *cluster-name:* Cluster name and prefix for all other resources
  - loadgenerator/variables.tf
    - *image-url:* ECR  image URL for the docker image of loadgenerator
    - *cluster-name:* Prefix for service created should same as terraform/variables.tf(eg: <test>_svc)

**References:**
- [Terraform EKS intro](https://learn.hashicorp.com/terraform/aws/eks-intro)
- [Kubernetes HPA](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
