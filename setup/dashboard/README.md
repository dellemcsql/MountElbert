	Clone git repository using below command to your home directory

git clone https://github.com/dellemcsql/MountElbert.git 

cd MountElbert && git checkout

	Go to dashboard folder and list all the files
 
	Create all the dashboard configuration ( After creating each deployment mentioned below, please run kubectl get pods -n kube-system to see the status of newly deployed pods. Once the pods creation completes then only proceed with next deployment steps.)
o	Create influxdb deployment

  kubectl create -f influxdb.yaml

o	Create heapster deployment

  kubectl create -f heapster.yaml

o	Create Dashbord deployment

  kubectl create -f dashbord.yaml

o	Create influxdb deployment

  kubectl create -f sa_cluster_admin.yaml

Verify if all pods have been created successfully 
  
  kubectl get pods -n kube-system

: =>  Once above steps completes successfully, proceed with be below steps to generate token for login into k8s dashboard.

	Run below command to see the token for service account. Copy the Tokens details to be used in next steps.

  kubectl -n kube-system describe sa dashboard-admin

	Run below command to find token for dashboard login ( make sure to replace tokens details copied from above steps to the one highlighted in red)

  kubectl -n kube-system describe secret dashboard-admin-token-dvrj4
	 
You will be able to see token listed as highlighted in above image. Copy and save the token to some text editor to be used in next step.

	Go to any of the node IP/name in web browser as mentioned below

https://<IP_Address>:32323

where <IP_Address> is the IP address of your master/worker node.
 

Select the “Token” option and paste the token which you have copied in last step and proceed with SIGN IN.

 

