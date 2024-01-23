# Task II
## ECR Repository using Terraform
1) Create ECR repository using terraform
    Terraform configuration to create new ecr repository, once new repository is created it will pull public nginx image and push to our private ecr repository using null resources.

## Instructions
Before running terraform scripts, make sure you have access to aws account. you can configure your aws account using `aws configure` command and provide `access_key` and `secret_key`.

`terraform init`: Terraform will initialize provider and module that we used in out configuration, it will also try to initialize backend if we provide any. I dont setup any backend in this task since it is a simple one so terraform will use local backend

`terrafrom plan`: Run terraform plan to verify before it create any resource in our account.

`terraform apply`: Once we verify the plan output we can run apply by running this command and approve to create resources.

In `ecr.tf` i have used `null_resources` which used to configure our local environment or remote servers that we created using terraform `remote_exec` or `local_exec`.

## Nginx Deployment
 Developed kubernetes manifest for nginx deployment, with service object and transform nginx deployment into helm chart. Used kubernetes secret for `imagePullSecrets` to pull our nginx image from private ecr repository.

### Instruction
* Cluster setup:
    Created KIND cluster using `kind create cluster` command.

* Lets create ecr registry secret before deploying nginx to our kind cluster

    ```
    kubectl create secret docker-registry regcred --docker-server=$ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com --docker-username=AWS --docker-password=$(aws ecr get-login-password)
    ```
    Above command using aws cli to get token from aws ecr, so make sure you configured aws access_key and secret_key in you cli.

* Once we create registry secret, we are good to deploy our nginx deployment by below command
    ```
    kubectl apply -f nginx.yml service.yml
    ```
* Since i used kind cluster for this development, i used `ClusterIp` in nginx service object, we can port forward this service to view the application in localhost using below command
    ```
    kubectl port-forward svc/nginx-service 80:80
    ```
* If we are using Cloud kubernetes provider like EKS,GKE,AKS we can leverage thier specific load balancer to expose of application to internet also by using any ingress controller. We can also use `NodePort` to expose it on node ip.

## Nginx Helm Chat
* Templating above nginx deployment into helm chart to parameterize it.

* `$ helm create nginx-test`: Create a boiler plate helm chart with nginx-test as Chart name

* Modified `values.yml` with values like `replicaCount`, `imagePullSecrets` etc as per our requirement

* Create `deployment.yml`, `service.yml` template inside the template folder with context to use it as same template for multiple environment.

* Render the template that we created in above step using `helm template . --values .\values.yaml` and verify deployment manifest are rendered as expected.

* Finally deploy helm chart using below command
```
 helm install nginx-chart . --values .\values.yaml
```
* Pass specific `values-dev.yml`, `values-prod.yml` to use different enviroment configuration.

# Improvements

We can use [helm secrets](https://github.com/jkroepke/helm-secrets) to store our secrets in fully encrypted way. It enable us to store fully encrypted secrets.yml in git repository. It is backed by sops and gpg keys.

### Quick Setup (Windows)
* Install helm plugin by providing `helm plugin install https://github.com/jkroepke/helm-secrets`
* Install dependencies 
    1) Sops - `choco install sops`
    2) gpg - Download from [here](https://www.gpg4win.org/get-gpg4win.html)
* Steps to create helm secrets
 1) `gpg --gen-key` - provide Name, email and pharsphase
 2) `gpg --list-keys` - grab the key thumbprint to encypt the `secret.yml`
 3) `sops -p $THUMBPRINT_FROM_GPG` secret.yml - Enter your secret in key-value pair to add it on `secret.yml`
 4) `helm secrets view secrets.yml` - verify secrets that you added in above steps
 5) Reference the secret key in your template like below example
 ```
 {{ .Values.password}} # here password is key name for secrets that we added in secrets.yml
 ```

* Also we can fully automate creation of kind cluster and deploy helm chart using terraform kind_cluster provide and helm provider.

* `aws ecr get-login-password`: the secret for registry that we created above will expire in 12 hours, so we need to keep update the ecr registry token. It can be achieve in kubernetes cron job. I have place draft of that cron job in `misc` folder it requires aws `access_key` and `secret_key`



