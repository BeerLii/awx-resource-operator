# AWX Resource Operator

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Build Status](https://github.com/ansible/awx-resource-operator/workflows/CI/badge.svg?event=push)](https://github.com/ansible/awx-resource-operator/actions)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-Ansible-yellow.svg)](https://docs.ansible.com/ansible/latest/community/code_of_conduct.html) 
[![AWX Mailing List](https://img.shields.io/badge/mailing%20list-AWX-orange.svg)](https://groups.google.com/g/awx-project)
[![IRC Chat - #ansible-awx](https://img.shields.io/badge/IRC-%23ansible--awx-blueviolet.svg)](https://libera.chat)

An operator that can be used along side [Ansible AWX](https://github.com/ansible/awx) to launch automation jobs and create job templates by creating resources directly in kubernetes. This operator is built with [Operator SDK](https://github.com/operator-framework/operator-sdk) and Ansible.

## Table of Contents

- [AWX Resource Operator](#awx-resource-operator)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
    - [Prerequisites](#prerequisites)
  - [Installing the Operator](#installing-the-operator)
  - [Usage](#usage)
    - [Create an AWX Access Token](#create-an-awx-access-token)
    - [Create a Connection Secret](#create-a-connection-secret)
    - [AnsibleJob](#ansiblejob)
      - [Launching Workflows](#launching-workflows)
    - [JobTemplate](#jobtemplate)
    - [AnsibleInventory](#ansibleinventory)
    - [AnsibleHost](#ansiblehost)
    - [AnsibleGroup](#ansiblegroup)
    - [AnsibleUser](#ansibleuser)
    - [AnsibleTeam](#ansibleteam)
    - [AnsibleExecutionEnvironment](#ansibleexecutionenvironment)
  - [Building and Testing](#building-and-testing)
  - [Author](#author)
  - [Code of Conduct](#code-of-conduct)
  - [Get Involved](#get-involved)

## Overview

The awx-resource-operator provides the following Custom Resources. Each resource
acts on the AWX instance described by the `connection_secret` referenced in its
spec:

* AnsibleJob - launches a job in the AWX instance specified in the specified k8s secret (awx host url, token)
* JobTemplate - creates a job template in the AWX instance specified.
* AnsibleProject - creates a project in the AWX instance specified.
* AnsibleWorkflow - launches a workflow in the AWX instance specified.
* WorkflowTemplate - creates a workflow template in the AWX instance specified.
* AnsibleCredential / AnsibleCredentialType - manages credentials and credential types.
* AnsibleInventory / AnsibleHost / AnsibleGroup - manages inventories, hosts and host groups.
* AnsibleInstanceGroup / AnsibleSchedule - manages instance groups and schedules.
* AnsibleUser - grants AWX user type permissions to an existing user.
* AnsibleTeam - creates an AWX team, grants AWX roles to the team and adds usernames as team members.
* AnsibleExecutionEnvironment - creates an AWX execution environment (container image) inside an organization.

### Prerequisites

* Install the kubernetes-based cluster of your choice:
  * [Openshift](https://docs.openshift.com/container-platform/4.11/installing/index.html)
  * [K8s](https://kubernetes.io/docs/setup/)
  * [CodeReady containers](https://access.redhat.com/documentation/en-us/red_hat_openshift_local/2.5)
  * [minikube](https://minikube.sigs.k8s.io/docs/start/)
* Deploy AWX using the [awx-operator](https://github.com/ansible/awx-operator#basic-install)
* Create an OAuth2 token for your user in the AWX UI


## Installing the Operator

1. Clone the awx-resource-operator

```
git clone git@github.com:ansible/awx-resource-operator.git
```

2. Log in to your cluster.

```
kubectl login <cluster-url>
```

3. Run the make target

```
NAMESPACE=awx IMG=quay.io/ansible/awx-resource-operator:latest make deploy
```

This will create a deployment named `resource-operator-controller-manager` in the namespace specified, in this case the `awx` namespace. The resulting operator pod will reconcile any AnsibleJob or JotTemplate resources created.


## Usage

Now that the awx-resource-operator is installed in your cluster, you can try creating a k8s resource to manage your AWX instance.

First, you need create a k8s secret with connection information for your AWX instance though. Below is example yaml that you can save to a file, edit, and apply to your cluster.

### Create an AWX Access Token

Create an OAuth2 token for your user in the AWX UI.

1. Navigate to Users
2. Select the username you wish to create a token for
3. Click on tokens, then the green plus icon
4. Application can be left empty, input a description and select the read/write scope.

> Alternatively, you can create one at the command-line using the `create_oauth2_token` manage command ([docs](https://docs.ansible.com/automation-controller/4.4/html/administration/tower-manage.html#create-oauth2-token))

### Create a Connection Secret

To make this connection information available to the operator, create a k8s secret with the host and token value. Here is example yaml for the connection k8s secret.

```
---
apiVersion: v1
kind: Secret
metadata:
  name: awx-access
  type: Opaque
stringData:
  token: <generated-token>
  host: https://my-awx-host.example.com/
```

Save this to a file, for example, `awx-connection-secret.yml`, edit it with your host and token value, the apply it to your cluster.

```
kubectl create -f awx-connection-secret.yml
```

### AnsibleJob

Launch an automation job on AWX by creating an AnsibleJob resource. Be sure to specify the connection secret on `connection_secret` as well as the Job Template you wish to launch.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleJob
metadata:
  generateName: demo-job-1 # generate a unique suffix per 'kubectl create'
spec:
  connection_secret: awx-access
  job_template_name: Demo Job Template
```

It is possible to configure other things like inventory, extra vars, and time to live for the job.

```
spec:
  connection_secret: awx-access
  job_template_name: Demo Job Template
  inventory: Demo Inventory                    # Inventory prompt on launch needs to be enabled
  runner_image: quay.io/ansible/awx-resource-runner
  runner_version: latest
  job_ttl: 100

  extra_vars:                                  # Extra variables prompt on launch needs to be enabled
     test_var: test

  job_tags: "provision,install,configuration"  # Specify tags to run
  skip_tags: "configuration,restart"           # Skip tasks with a given tag
```

Note that prompt on launch needs to be enabled for inventories and extra vars if you are specifying those. In order to enable "PROMPT ON LAUNCH", within the AWX UI:

1. Select Resources -> Templates
2. Within Templates, select your template and click the "PROMPT ON LAUNCH" checkbox next to INVENTORY and EXTRA VARIABLES.

![Prompt on Launch Configuration Example](./docs/images/on-launch-configuration.png "Prompt on Launch Configuration Example")


#### Launching Workflows

Launch a Workflow Job Template with an AnsibleJob object by specifying the `workflow_template_name` instead of `job_template_name`.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleJob
metadata:
  generateName: demo-job-1 # generate a unique suffix per 'kubectl create'
spec:
  connection_secret: awx-access
  workflow_template_name: Demo Workflow Template
```

### JobTemplate

Create a job template on AWX by creating a JobTemplate resource.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: JobTemplate
metadata:
  name: jobtemplate-4
spec:
  connection_secret: awx-access
  job_template_name: ExampleJobTemplate4
  job_template_project: Demo Project
  job_template_playbook: hello_world.yml
  job_template_inventory: Demo Inventory
```


### AnsibleInventory

Create an inventory on AWX by creating an AnsibleInventory resource.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleInventory
metadata:
  name: beer-inventory
spec:
  connection_secret: awx-access
  name: beer-inventory
  organization: Default
  state: present
```

### AnsibleHost

Create a host inside an existing inventory on AWX by creating an AnsibleHost resource. The referenced inventory must already exist in AWX.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleHost
metadata:
  name: beer-host-1
spec:
  connection_secret: awx-access
  name: beer-host-1
  description: example host
  inventory: beer-inventory
  enabled: true
  state: present
  variables:
    ansible_host: 10.0.0.10
    ansible_user: root
```

Setting `state: absent` deletes the host from AWX again. Host variables are passed through to AWX as-is, so any Ansible connection variables (`ansible_host`, `ansible_user`, `ansible_port`, ...) can be set here.


Inventory 也可以通过 `spec.groups` 一并创建或更新 Host Group。Inventory 本身必须先成功创建，引用的 Host 和子 Group 必须已经存在于该 Inventory 中。

```yaml
spec:
  name: beer-inventory
  organization: Default
  connection_secret: awx-access
  groups:
    - name: beer-test
      hosts:
        - beer-host-1
      children: []
      preserve_existing_hosts: true
      preserve_existing_children: true
```


### AnsibleGroup

Create a host group in an existing AWX inventory with an `AnsibleGroup` resource. The
inventory and any hosts or child groups referenced by `hosts` and `children` must
already exist in AWX.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleGroup
metadata:
  name: beer-test
spec:
  connection_secret: awx-access
  name: beer-test
  inventory: beer-inventory
  description: beer test host group
  state: present
  hosts:
    - beer-host-1
  children: []
  preserve_existing_hosts: true
  preserve_existing_children: true
```

Set `state: absent` to remove the group. By default, the declared `hosts` and
`children` are synchronized; set the corresponding `preserve_existing_*` option
to `true` to retain existing AWX relationships not listed in the resource.


### AnsibleUser

Grant an AWX user type to an existing user with an `AnsibleUser` resource. The
resource is keyed on `username`, so the same username can be managed from
Kubernetes without duplicating the user record.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleUser
metadata:
  name: beer-user
spec:
  connection_secret: awx-access
  username: beer-user
  is_superuser: true
  state: present
```

Set `is_superuser: true` to grant the System Administrator user type, or
`is_system_auditor: true` to grant the System Auditor user type. Both options are
only sent to AWX when they are present in the resource, so an existing user type
is never changed implicitly. Set them to `false` to revoke a user type.

Optional `first_name`, `last_name`, `email` and `organization` fields update the
user profile. When `password_secret` names a k8s Secret (in the same namespace as
the resource) containing a `password` key, the user is created in AWX if it does
not exist yet and the password is applied; without it, the user must already
exist in AWX. Set `state: absent` to delete the user.

AnsibleUser 通过 `spec.username` 指定要管理的 AWX 用户，并使用 `is_superuser`
/ `is_system_auditor` 授予 System Administrator / System Auditor 用户类型权限。
只有在资源中显式声明这两个字段时才会下发到 AWX，因此不会意外修改已有用户的
用户类型；将它们设为 `false` 即可撤销对应权限。

### AnsibleTeam

Create an AWX team, grant AWX roles to the team, and add usernames to the team
with an `AnsibleTeam` resource. Team members implicitly inherit every role that
is granted to the team, so adding a `username` to `spec.users` gives that user
all of the permissions listed in `spec.roles`.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleTeam
metadata:
  name: beer-team
spec:
  connection_secret: awx-access
  name: beer-team
  organization: Default
  description: beer team
  users:
    - beer-user
  roles:
    - role: execute
      job_template: beer-job-template
      state: present
    - role: read
      inventory: beer-inventory
      state: present
  preserve_existing_users: true
  state: present
```

`spec.roles` is a list of AWX role grants. Each entry requires a `role` name
(`admin`, `read`, `member`, `execute`, `update`, `use`, `adhoc`, `approval`,
`auditor`, `project_admin`, `inventory_admin`, `credential_admin`,
`workflow_admin`, `notification_admin`, `job_template_admin` or
`execution_environment_admin`) and exactly one target, chosen from
`organization`, `inventory`, `job_template`, `workflow`, `credential`,
`project` or `instance_group`. Set the optional `state` of a single grant to
`absent` to revoke it.

By default the declared `users` list is synchronized with AWX and usernames that
are no longer listed are removed from the team; set
`preserve_existing_users: true` to keep them. Set `state: absent` to remove the
team. `new_name` renames an existing team, and `name`/`organization` are
required.

AnsibleTeam 会创建一个 AWX team，通过 `spec.roles` 把 AWX 角色（例如某个 job
template 的 `execute`、某个 inventory 的 `read`）授权给这个 team，然后把
`spec.users` 中的 `username` 以 team member 的身份加入 team。由于 team 成员会
自动继承 team 的所有角色，这些用户就通过 team 拿到了对应的权限。

### AnsibleExecutionEnvironment

Create an AWX execution environment with an `AnsibleExecutionEnvironment`
resource. The execution environment is the container image AWX uses to run
jobs, and it lives inside an organization, so `name`, `organization` and
`image` are required.

```
---
apiVersion: tower.ansible.com/v1alpha1
kind: AnsibleExecutionEnvironment
metadata:
  name: beer-ee
spec:
  connection_secret: awx-access
  name: beer-ee
  organization: Default
  image: quay.io/ansible/awx-ee:latest
  description: beer execution environment
  pull: missing
  state: present
```

`spec.image` is the full container image reference
(`registry/namespace/image:tag`) used by AWX when it runs a job. When the image
comes from a private registry, set `spec.credential` to the name of an AWX
"Registry" credential that holds the registry credentials.

`spec.pull` controls how the image is pulled and accepts `always`, `missing`
(default) or `never`. Set `state: absent` to delete the execution environment,
or `state: exists` to only check that it exists. Optional `runner_image`,
`runner_version` and `runner_pull_policy` override the runner job image that
reconciles the resource.

AnsibleExecutionEnvironment 用于在 AWX 中创建 execution environment（即 AWX
运行 job 时使用的容器镜像），它属于某个 organization，因此 `name`、
`organization` 和 `image` 是必填字段。私有仓库镜像可以通过 `credential`
指定一个 AWX "Registry" 类型的凭据；`pull` 支持 `always` / `missing`
（默认）/ `never`。设置 `state: absent` 即可删除该 execution environment。

## Contributing

Please visit our [contributing guidelines](./CONTRIBUTING.md) and [development guide](./docs/development.md) for information on how to set up your environment, build and deploy the operator, and submit changes.

## Author

This maintained by the Red Hat Ansible Team.

## Code of Conduct

We ask all of our community members and contributors to adhere to the [Ansible code of conduct](http://docs.ansible.com/ansible/latest/community/code_of_conduct.html). If you have questions or need assistance, please reach out to our community team at [codeofconduct@ansible.com](mailto:codeofconduct@ansible.com)

## Get Involved

We welcome your feedback and ideas. The AWX resource operator uses the same mailing list and IRC channel as AWX itself. Here's how to reach us with feedback and questions:

- Join the `#ansible-awx` channel on irc.libera.chat
  * You can also join using Matrix and a client of your choice (Element is recommended) for a better experience ([more info here](https://hackmd.io/@ansible-community/community-matrix-faq))
- Join the [mailing list](https://groups.google.com/forum/#!forum/awx-project)
