# Troubleshooting Kubernetes

Troubleshooting Kubernetes requires:

- Knowledge of common terms.
- Establishing which category the problem fits.
- Knowledge of Kubernetes and related tools (kubectl).

## Common Terminology

- **Annotation**: A key-value pair that is used to attach arbitrary
  non-identifying metadata to objects.
- **Applications**: The layer where various containerized applications run.
- **ConfigMap**: An API object used to store non-confidential data in key-value
  pairs. Can be consumed as environment variables, command-line arguments, or
  config files in a volume.
- **Cluster**: A set of machines, called nodes, that run containerized
  applications managed by Kubernetes. A cluster has at least one worker node and
  at least one master node.
- **ClusterRole**: A role contains rules that represent a set of permissions.
  Permissions are purely additive (there are no “deny” rules). At the
  instance level, it is called a ClusterRole.
- **ClusterRoleBinding**: A role binding grants the permissions defined in a
  role to a user or set of users. It holds a list of subjects (users, groups, or
  service accounts), and a reference to the role being granted. When applied at
  the instance level, it is called RoleBinding.
- **Container**: A lightweight and portable executable image that contains
  software and all of its dependencies.
- **Deployment**: An API object that manages a replicated application.
- **Helm Chart**: A package of pre-configured Kubernetes resources that can be
  managed with the Helm tool.
- **Ingress**: An API object that manages external access to the services in a
  cluster, typically HTTP.
- **Init Container**: One or more initialization containers that must run to
  completion before any app containers run.
- **Job**: A finite or batch task that runs to completion.
- **Kubectl**: A command line tool for communicating with a Kubernetes API
  server.
- **Kubelet**: An agent that runs on each node in the cluster. It makes sure
  that containers are running in a pod.
- **Kubernetes API**: The application that serves Kubernetes functionality
  through a RESTful interface and stores the state of the cluster.
- **Label**: Tags objects with identifying attributes that are meaningful and
  relevant to users.
- **Namespace**: An abstraction used by Kubernetes to support multiple virtual
  clusters on the same physical cluster.
- **Node**: A node is a worker machine in Kubernetes.
- **Persistent Volume**: An API object that represents a piece of storage in the
  cluster. Available as a general, pluggable resource that persists beyond the
  lifecycle of any individual Pod.
- **Persistent Volume Claim (PVC)**: Claims storage resources defined in a
  PersistentVolume so that it can be mounted as a volume in a container.
- **Pod**: The smallest and simplest Kubernetes object. A Pod represents a set
  of running containers on your cluster.
- **RBAC (Role-Based Access Control)**: Manages authorization decisions,
  allowing admins to dynamically configure access policies through the
  Kubernetes API.
- **Resource Quotas**: Provides constraints that limit aggregate resource
  consumption per Namespace.
- **Role**: A role contains rules that represent a set of permissions.
  Permissions are purely additive (there are no “deny” rules). At the
  namespace level, it is called a Role.
- **RoleBinding**: A role binding grants the permissions defined in a role to a
  user or set of users. It holds a list of subjects (users, groups, or service
  accounts), and a reference to the role being granted. When applied at the
  namespace level, it is called RoleBinding.
- **Secret**: Stores sensitive information, such as passwords, OAuth tokens, and
  ssh keys.
- **Service**: An abstract way to expose an application running on a set of Pods
  as a network service.
- **Service Account**: Provides an identity for processes that run in a Pod.
- **Volume**: A directory containing data, accessible to the containers in a
  pod.

## Troubleshooting workflows

The type of problem will determine what steps to take. The possible
troubleshooting workflows are for:

- Helm
- Kubernetes integration

### Helm workflow

```mermaid
graph TD;
  A --> |Yes| B
  B --> |Yes| C
  B --> |No| D
  D --> |Yes| E
  D --> |No| F
  A --> |No| G
  G --> |Yes| H
  H --> I
  I --> |Yes| J
  J --> |Yes| K
  K --> |Running| L
  K --> |Completed| M
  I --> |No| N
  J --> |No| O
  G --> |No| P
  P --> |Yes| Q
  P --> |No| R
  R --> |Yes| S
  R --> |No| T
  A{Are you seeing an error stating<br>'$name' has no deployed releases?}
  B{Did the initial install fail,<br>and GitLab was never operational?}
  C[You will need to purge the failed<br>install before installing again.]
  D{Did the initial install command<br>time out, but GitLab still came up<br>successful?}
  E[You should add the --force flag<br>to the helm upgrade command<br>to ignore the error and attempt<br>to update the release.]
  F[This may be a bug/issue<br>in GitLab and will require<br>deeper investigation. Escalate<br>to GitLab support.]
  G{Is the unicorn or sidekiq<br>pods hitting CrashBackLoops?}
  H[Likely this means the dependencies container<br>on those pods is failing to pass. Grab the logs<br>of the dependencies containers from the<br>unicorn and sidekiq pods.]
  I{Are you seeing messages showing<br>the database schema versions?}
  J{Is the current version less<br>than the codebase version?}
  K{This means the migration job has not completed. Run<br>kubectl get pod -l job-name=job_name_here<br>What does the STATUS show?}
  L[Check the logs from the job pod. Any<br>failures/errors in said pod will need<br>to be fixed.]
  M[The application containers should start<br>shortly after the next check passes. If<br>they do not start after some time, this<br>will require deeper investigation.<br>Escalate to GitLab support.]
  N[Any failures/errors in said<br>pod will need to be fixed.]
  O[This is may be a bug/issue<br>in GitLab and will require<br>deeper investigation. Escalate<br>to GitLab support.]
  P{Is the GitLab runner<br>failing to register?}
  Q(This can happen when the runner<br>token has changed in GitLab. Find<br>the new shared runner token via<br>amdin/runners in the GitLab UI,<br>delete the old secret for<br>giltab-runner-secret, and create<br>a new one.)
  R{Are you hitting Too<br>many redirects errors?}
  S(This normally means your TLS termination<br>is occurring before the nginx ingress and<br>the tls-secrets are specficied in the<br>configuration. Set the<br>'nginx.ingress.kubernetes.io/ssl-redirect'<br>value to false under<br>global.ingress.annotations<br>in your values.yml and apply the change<br>to your helm deployment.)
  T(It is likely the issue you are<br>encountering is either a<br>Kubernetes, bug, issue, or<br>configuration issue. You<br>should escalate to GitLab<br>support.)
```

### Kubernetes integration Workflow

```mermaid
graph LR;
  A --> |Yes| B
  A --> |No| C
  C --> |Yes| D
  C --> |No| E
  E --> |Yes| F
  E --> |No| G
  G --> |Yes| H
  G --> |No| I
  A{Does the helm install<br>present a 401 error?}
  B[This means the token is bad.<br>Try following the docs and using<br>the exact command]
  C{Does it present a blank<br>Kubernetes error?}
  D[This means the CA Certificate<br>is bad. Try following the docs<br>and using the exact command]
  E{Does it present a 500<br>error?}
  F[This means there is an issue with<br>RBAC. Check if RBAC is enabled<br>on the cluster and check the<br>Kubernetes settings in GitLab]
  G{Is there a helm-install pod<br>on your Kubernetes cluster?}
  H[Check the logs for this pod.<br>It likely will show errors.<br>Those would need to be resolved]
  I[This may be a bug/issue<br>in GitLab and will require<br>deeper investigation. Escalate<br>to GitLab support.]
```

## Troubleshooting walkthrough

Most Kubernetes troubleshooting can be broken down into 2 categories:

- [Troubleshooting helm](#troubleshooting-helm)
- [Troubleshooting Kubernetes integration](#troubleshooting-kubernetes-integration)

Generally speaking, if it does not fall into those two categories, it is either:

- Something GitLab support needs to look into.
- Something a Kubernetes administrator needs to look into.

Exercise caution. Issues that appear to be GitLab problems can be Kubernetes or
infrastructure issues.

### Troubleshooting helm

TBD

### Troubleshooting Kubernetes integration

TBD

## Common issues

TBD

## Replication

Setting up Kubernetes can be tricky and costly. There are two methods we
recommend:

- [k3s](https://k3s.io/)
- [minikube](https://kubernetes.io/docs/setup/learning-environment/minikube/)

Of the two, k3s tends to be the most viable. It is closer to a production style
deployment.

STEPS FOR K3S DEPLOYMENT HERE

You can read more using minkube via
[Kubernetes documentation](https://kubernetes.io/docs/setup/learning-environment/minikube/).
