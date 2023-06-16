# Django Deployment

## Prerequisites

Install the following tools:

- [Terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
  - [aws session manager](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)

## AWS account creation

1. Create aws free tier account
2. Create new IAM user instead of using the root account
   - enter username (e.g. `manager`), password and select `Programmatic access`
   - Go to user and security credentials, **create access key** and download the csv file with credentials
   - export the credentials to the environment variables

    ```bash
    export AWS_ACCESS_KEY_ID=
    export AWS_SECRET_ACCESS_KEY=
    ```

3. Create user Group (e.g. `manager`)
    - Add user (e.g. `manager`) to this newly created group
    - Add permission policies to the new group:
        - AmazonEC2FullAccess
        - AdministratorAccess

4. Create new role to use **amazon session manger** to avoid ssh access to the instance
   - Create new **SSM role** (e.g. `EC2-SSM-Access-Role`)
     - Use case = EC2
     - Add `AmazonSSMManagedInstanceCore` policy to the role

5. Create `hosted zone` in Route53
    - Add a new domain (e.g. `django.bl4ko.com`)

## Create EC2 instance using terraform

Init the terraform directory

```bash
terraform init
```

Create the infrastructure

```bash
terraform apply
```

### Architecture explained

We are using ubuntu 22.04 image. With cloud init, the docker is automatically installed and the docker compose file is copied to the instance. We have three containers in our docker compose file:

- `django` - our django application
- `postgres` - postgres database
- `nginx` - nginx acting as reverse proxy

The nginx container is exposed to the internet on port 80, which is only accessible through cloud front.
This is achieved using security group where only the cloud front prefix list is allowed to the instance. 

```bash
# Get the prefix list id for cloud front
aws ec2 describe-managed-prefix-lists
# Search for "PrefixListName": "com.amazonaws.global.cloudfront.origin-facing"
```

With this we achieve only HTTPS traffic to our app.

Also public access to our instance is disabled. The only way to access the instance is through **aws session manager**.

## Securely connect to instance

Secure connection to the instance is done via **aws session manager**. To connect to the instance run:

```bash
aws ssm start-session --target $(terraform output -raw instance_id)
```

### SSH over Session Manager

To setup SSH over Session Manager you will need to add the following to `~/.ssh/config`:

```bash
host i-* mi-*
    ProxyCommand sh -c "aws ssm start-session --target %h --document-name AWS-StartSSHSession --parameters 'portNumber=%p'"
```

Also add the following permission to the previously created role  (`EC2-SSM-Access-Role`)

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": "ssm:StartSession",
            "Resource": [
                "arn:aws:ec2:region:account-id:instance/instance-id",
                "arn:aws:ssm:*:*:document/AWS-StartSSHSession"
            ]
        }
    ]
}
```

Now we can connect to the instance via ssh over ssm

```bash
# Now works
ssh $(terraform output -raw instance_id)
```

## Docker compose

First copy the docker files for our app to run.

```bash
scp -r ./django-on-docker $(terraform output -raw instance_id):/home/ubuntu/
```

Now we can run our app using docker compose

```bash
ssh $(terraform output -raw instance_id) "cd django-on-docker && docker-compose up -d"
```

Now the app is available through cloud front on the domain name `django.bl4ko.com`

- you can upload custom file and see it
- for example upload custom image and open it in the browser

## Evaluation of Cloud Providers

I will evaluate the cloud providers that I have worked with before:

- `GCP`: This provider shines in its **exceptional documentation**, making it straightforward for users to get started and troubleshoot any issues. Its robust array of features and intuitive use makes it a contender for handling diverse tasks.
- `Azure`: Azure is feature-rich, which is its main strength, but it suffers from a **steep learning curve** due to its **complex** user interface. It can be time-consuming to set up applications and the documentation could certainly use some improvement, making it less suitable for rapid deployment tasks.
- `DigitalOcean` Its **simplicity** and **user-friendly interface** make it a great choice for smaller projects, where speed of server deployment and instance management are paramount. However, it falls short when it comes to offering advanced features like its counterparts, and its cost-effectiveness might be questionable for larger scale projects.