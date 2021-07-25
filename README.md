# Lendflow DevOps Assessment

# Goal

Create a script or IaC-powered method to deploy a containerized webserver to AWS, as well as a script to check that the service is running and publicly available.

# Overview

I chose to complete this assessment using Terraform because I'm the most familiar with it as
an IAC tool and I'm really excited to use it wherever I can.

My Terraform configuration is pretty simple. I chose to leave everything in a single `main.tf`
file because the resources are all related and there are not many of them.

In my opinion, `make` makes (ha) prototype tooling for repositories like this one pretty easy. In the case of Terraform, `make`s' dependency support makes ensuring that the `apply` process is executed in the appropriate order (from `init` to `plan` to `apply`) a breeze. You'll find a `Makefile` at the root of this repository with some straightforward commands configured.

# You'll need

- To clone this repository by running:

```bash
$ git clone https://elliottmoos@bitbucket.org/elliottmoos/devops-challenge.git
```

- Have `make` installed - This is pre-installed on most machines but if you don't have it check these places for instructions on how to install it:
  - [MacOS](https://stackoverflow.com/questions/10265742/how-to-install-make-and-gcc-on-a-mac)
  - [Linux(Ubuntu/Debian)](https://stackoverflow.com/questions/11934997/how-to-install-make-in-ubuntu)
- Terraform version 1.0.0 or greater - You can run `make tools` in the root of this repository if you have [Homebrew](https://brew.sh/) installed on MacOS. Otherwise check the [docs](https://learn.hashicorp.com/tutorials/terraform/install-cli) for installation instructions.
- AWS credential env vars set - Values provided by me if you're one of the folks evaluating this entry.
  - AWS_ACCESS_KEY_ID
  - AWS_SECRET_ACCESS_KEY

# Directory Structure

- app:
  - This houses a copy of the `Dockerfile` I used to build the lightly customized nginx image used in the deployment. I haven't included tooling around building and pushing this image as I felt it was just outside the scope of this assessment. However, I can make a change if that is desired.
  - You'll also find an `html` directory with an `index.html` and `favicon.ico` file in it. These are the assets I replace the default nginx image assets with.
- terraform:
  - I put the json template for the web service ecs task definition in an `ecs_task_definitions` directory to show how I might organize them in a normal circumstance.
  - The rest of the files should look pretty familiar if you've worked with Terraform before:
    - input.tf: Variable declarations. We pass the corresponding values in main.tfvars to these when planning or applying or destroying via the `-var-file` option.
    - main.tf: Configuration code including resources and data sources.
    - main.tfvars: Terraform variable values
    - output.tf: Just one value: The application load balancers' DNS name interpolated into a url that should be passed to the service-check script.
    - terraform.tfstate: Terraform state file. Named pretty well.
    - versions.tf: Specifies the required version constraint for the Terraform CLI in this case.
- Makefile:
  - This is definitely old tech but it's reliable and gets the job done
  - You'll find a few commands that will help keep the clutter off of the command line:
    - `tools`: Installs latest Terraform CLI on MacOS via Homebrew (optional)
    - `terraform-init`: Initializes the Terraform environment and installs the required providers
    - `terraform-validate`: Depends on `terraform-init`. Validates the syntax of your HCL
    - `terraform-plan`: Depends on `terraform-init`. Creates binary Terraform plan used by terraform apply.
    - `terraform-apply`: Depends on `terraform-plan`. Applies binary plan.
    - `terraform-destroy`: Tears everything down
    - `service-check`: Requires a `url` env var declaration. Passes the url to the `service-check.sh` bash script.
- service-check.sh:
  - Takes a url, makes a GET request via `curl` and greps the response for a 200 status code.
  - Returns an UP message if successful and a DOWN message if not.

# Provisioning

1. Ensure required env vars are set and tools are installed
2. Replace `vpc_id`, `subnet_a_id`, and `subnet_b_id` variable values in `main.tfvars` if deploying into an AWS account other than mine
3. `make terraform-apply`
4. Copy the `web_service_url` output value from the Terraform apply report to pass to `make service-check`

# Checking web service health

1. `make service-check url={web_service_url copied from the provisioning step}`
   > If all went well, you should see "Lendflow Challenge web service is UP!" on the command line.
   > If not, "Lendflow Challenge web service is NOT READY or DOWN:(".

# Tearing it all down

1. `make terraform-destroy`
