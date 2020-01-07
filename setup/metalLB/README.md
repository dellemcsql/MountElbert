Prerequisite:
	You should have git configured on your client machine
	Your client machine should have kube configuration completed

MetalLB is a load-balancer implementation for bare metal Kubernetes clusters, using standard routing protocols. We will be setting up a Layer 2 Load-Balancer so that we can access our deployments from outside cluster.

	To install MetalLB, apply the manifest as shown below:

kubectl apply -f https://raw.githubusercontent.com/google/metallb/v0.7.3/manifests/metallb.yaml

This will deploy MetalLB to your cluster, under the metallb-system namespace. 

To view the running pod for MetalLB, use below command.

	kubectl get pods -n metallb-system -o wide
	kubectl get sa -n metallb-system 

•The metallb-system/controller deployment. This is the cluster-wide controller that handles IP address assignments.
•The metallb-system/speaker daemonset. This is the component that speaks the protocol(s) of your choice to make the services reachable.
•Service accounts for the controller and speaker, along with the RBAC permissions that the components need to function.

The installation manifest does not include a configuration file. MetalLB’s components will still start but will remain idle until you define and deploy a configmap.

To install the configmap MetalLB, create the below mentioned yaml file (metallb-config.yaml) into your client and apply the same.

apiVersion: v1
kind: ConfigMap
metadata:
  namespace: metallb-system
  name: config
data:
  config: |
    address-pools:
    - name: default
      protocol: layer2
      addresses:
      - <start-IP-range>-<end-IP-range>

Change the <start-IP-range> and <end-IP-range> to IP address as per your environment with free pool of IPs.
	
Once metallb-config.yaml is saved. Create the configmap below command:

kubectl create -f metallb-config.yaml
	 
Your kubernetes cluster has now been configured with MetalLB load-balancer. Now whenever a service of type “LoadBalancer” gets created for any deployments, you will be able to see an external IP address assigned to to your service. 
