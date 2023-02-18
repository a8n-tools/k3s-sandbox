# k3s-sandbox

Welcome to the k3s sandbox, a place where you can create and destroy Kubernetes clusters.

Everything has a learning curve. k8s has a steep learning curve, especially if you don't know Docker. Many online
tutorials show how to do X + Y + Z assuming you are running on platform A using technology B and option C. If you
aren't using A, B or C, you have to fill in the gaps using other tutorials. As with complex systems, the documentation
is a sea of information that you can take a deep dive into... and get lost in. It's useful after you start to see how
the pieces fit together.

k8s sandbox is a very opinionated (single path) install from start to finish. Create the `.env` file, run a few
commands and then open the dashboard. If something didn't work, tail the logs to find out why. If something is broken,
the existing node will be uninstalled before installing fresh.

The current state is that it works for me; it may not work for you. The scripts could use more error checking.

## Table of Contents

1. [Terminology](#Terminology)
2. [Requirements](#Requirements)
3. [Quick Start](#Quick-Start)
4. [.env](#env)
5. [Notes to clean up](#Below-are-notes-to-clean-up)
6. [Networking](#Networking)
   1. [Flannel networking](#Flannel-networking)
   2. [Ingress Controller vs Ingress Rules](#Ingress-Controller-vs-Ingress-Rules)
7. [Install k3s cluster](#Install-k3s-cluster)
8. [Dashboard](#Dashboard)
9. [Prometheus stack](#Prometheus-stack)
10. [Cert Manager](#Cert-Manager)
11. [Swagger API](#Swagger-API)
12. [To Learn](#To-Learn)
13. [Resources](#Resources)

## Terminology

- k8s - Kubernetes, the beast we are trying to tame.
- k3s - A smaller Kubernetes. Kubes for short. See [What's with the name?][] and the [pronunciation][].
    - Note: Many other smaller/portable/easy-to-deploy versions of k8s exist besides k3s.
- Helm - Package Manager for k8s.
- Charts - The packages that Helm installs, expressed as yaml files. Commonly called Helm Charts.

[What's with the name?](https://docs.k3s.io/)
[pronunciation](https://github.com/k3s-io/k3s/issues/55)

## Requirements

Google the requirements for k8s and k3s.

- A Linux VM/VPS/bare metal that has access to the internet.
    - **Enable IP forwarding**. IP forwarding is required to pass traffic between networks. I.e. from the host network
      to the container network. Some tools and installation methods enable IP forwarding automatically but don't
      document it.
        - This [issue on k3os][] explains it well: IP forwarding is required and k3s enables it automatically.
        - The docs for [custom CNI][] state IP forwarding should be enabled.
    - **Enable IP masquerade**. The IP masquerade requirement was a little harder to determine.
      The [Flannel option][] `--flannel-ipv6-masq` enables IP masquerade for IPv6 and states it's the default for IPv4.
      During testing, external connectivity would not work until IP masquerade was enabled.
    - Firewall - The docs state [firewalld should be disabled][] for CentOS and RHEL which are RPM based but does not
      explicitly mention openSUSE. During testing, `firewalld` could be enabled with the IP masq option enabled. The
      script adds this option automatically.
- A real domain is needed to request Let's Encrypt certificates. You can use a domain that is already in use. Adding
  entries to the hosts file is preferred since this is a sandbox.
- Cloudflare is used for DNS auth for certs. It's easy to change the CRDs to use other DNS providers, though.
    - Note: The Let's Encrypt staging environment is used to prevent lockout due to rate limiting.
- Download [k3s][] and put it in your path.
    - symlink k8s to kubectl: `ln -s k3s kubectl`
- Download [helm][] and put it in your path.
- Install `envsubst` or download the Go version of [envsubst][] and put it in your path.

[k3s]: https://github.com/k3s-io/k3s/releases

[helm]: https://github.com/helm/helm/releases

[envsubst]: https://github.com/a8m/envsubst/releases

[issue on k3os]: https://github.com/rancher/k3os/issues/600

[custom CNI]: https://docs.k3s.io/installation/network-options#custom-cni

[firewalld should be disabled]: https://docs.k3s.io/advanced#red-hat-enterprise-linux--centos

[Flannel option]: https://docs.k3s.io/installation/network-options#flannel-options

## Quick Start

All steps can be performed on the host server, although I run `fresh-install.sh` on the server and the rest from
my desktop. If you run it all on the server, comment out the `scp` command that copies the config locally.

1. Copy `.env.example` and fill in the necessary information. You'll need to create a Cloudflare API token.
2. Run `./bin/fresh-install.sh`. This will source `.env` and install k3s.
3. Run `./bin/helm-add-repos.sh`. This is a one-time command and is needed only if new apps are added to this sandbox.
4. Run `./bin/install-apps.sh` to install a few k8s apps using Helm Charts.
    - (optional) If running all commands on the server, comment out the `scp` command.
5. Run `./bin/create-crds.sh` to create the Custom Resource Definitions. CRDs define your data in k8s.
6. (One time task) Add hosts file entries for `k3s.BASE_DOMAIN` and `traefik.BASE_DOMAIN`.
7. Visit `https://k3s.BASE_DOMAIN/` and `https://traefik.BASE_DOMAIN/`. Both should be reachable.
    - Run `kubernetes-dashboard/generate-admin-token.sh; cat kubernetes-dashboard/admin-user-token.key` to generate
      the admin token for the k8s dashboard. Run the command a 2nd time to generate another token.
8. Change the `values.yml` files and run `./bin/create-crds.sh` to update the data. Browse through the kubernetes
   dashboard to see how the data has changed.
9. If you change something fundamental to the system, or want to make sure all values have the correct relationship,
   repeat the steps above starting with `fresh-install.sh`.

## .env

`envsubst` will substitute environmental variables from `.env` in the yml files. Secrets are base64 encoded before
substituting.

| Name                        | Purpose                                     | Docs                                                       |
|-----------------------------|---------------------------------------------|------------------------------------------------------------|
| `CLOUDFLARE_API_TOKEN`      | API Token from Cloudflare                   | [Configuring DNS01 Challenge Provider][]                   |
| `CLOUDFLARE_API_EMAIL`      | Your email address for Cloudflare           | [Configuring DNS01 Challenge Provider][]                   |
| `CLOUDFLARE_DNS_SERVERS`    | The DNS servers for your zone in Cloudflare | [--dns01-recursive-nameservers][]                          |
| `ACME_EMAIL`                | The email address for Let's Encrypt         | [Configuring DNS01 Challenge Provider][]                   |
| `BASE_DOMAIN`               | The domain for your cluster                 | Used throughout the configuration                          |
| `ADMIN_BASIC_AUTH_USERNAME` | Basic auth username for the dashboards      | Used in the ingress config                                 |
| `ADMIN_BASIC_AUTH_PASSWORD` | Basic auth password for the dashboards      | Used in the ingress config                                 |
| `K3S_ADMIN_IP`              | k3s IP for listening                        | [--advertise-address][], [--bind-address][], [--tls-san][] |
| `K3S_ADMIN_IFACE`           | Not used; was used for testing              | [--flannel-iface][]                                        |
| `K3S_ADMIN_HOSTNAME`        | SSH hostname to scp the config              | If set, scp the kube config locally                        |

[Configuring DNS01 Challenge Provider]: https://cert-manager.io/docs/configuration/acme/dns01/

[--dns01-recursive-nameservers]: https://cert-manager.io/docs/configuration/acme/dns01/#setting-nameservers-for-dns01-self-check

[--advertise-address]: https://docs.k3s.io/reference/server-config#listeners

[--bind-address]: https://docs.k3s.io/reference/server-config#listeners

[--tls-san]: https://docs.k3s.io/reference/server-config#listeners

[--flannel-iface]: https://docs.k3s.io/reference/server-config#agent-networking

## Below are notes to clean up

## Networking

I believe disabling the firewall will allow k3s to properly enable IP masquerade, and this is probably an edge case
where k3s doesn't set the right iptables for IP masq when the firewall is enabled. There are several issues with respect
to iptables and not being able to connect externally.

Enable IP masquerade in the firewall if the "no route to host" error is present.

```text
E0217 01:58:34.186576       1 controller.go:167] cert-manager/clusterissuers "msg"="re-queuing item due to error processing" "error"="Get \"https://acme-staging-v02.api.letsencrypt.org/directory\": dial tcp: lookup acme-staging-v02.api.letsencrypt.org on 1.1.1.1:53: read udp 10.42.0.12:48704->1.1.1.1:53: read: no route to host" "key"="letsencrypt-staging"
```

```bash
sudo firewall-cmd --zone public --add-masquerade
sudo firewall-cmd --runtime-to-permanent
```

- [Pod network connectivity non-functional as a result of sysctl net.ipv4.ip_forward=0](https://www.suse.com/support/kb/doc/?id=000020166)
- [RedHat CentOS disable firewalld](https://docs.k3s.io/advanced#additional-preparation-for-red-hatcentos-enterprise-linux)

### Flannel networking

> k8s or k3s with helm. you can use libvirt as a provider

The `clusterissuer` is producing the error below.
This [StackOverflow question](https://stackoverflow.com/questions/73815751/k3s-debuging-dns-resolution) is very similar
and suggests to use the `ipsec` flannel backend. k3s supports a
few [flannel options](https://docs.k3s.io/installation/network-options#flannel-options) but not as many
as [documented in flannel](https://github.com/flannel-io/flannel/blob/master/Documentation/backends.md). There's also
the [k8s network docs](https://kubernetes.io/docs/concepts/cluster-administration/addons/#networking-and-network-policy)
.

```text
default       0s          Warning   ErrInitIssuer      clusterissuer/letsencrypt-staging                          Error initializing issuer: Get "https://acme-staging-v02.api.letsencrypt.org/directory": dial tcp 172.65.46.172:443: connect: no route to host
```

### Ingress Controller vs Ingress Rules

[This answer][] has an excellent explanation about ingress controllers and ingress rules.

- The controller is installed when Helm installs Traefik. The controller can be deployed to any namespace, and is the
  actual Traefik binary that runs in a pod.
- The ingress rules must reside in the same namespace as the app or service. The rules are similar to Traefik's routes
  in that they explain how to route the traefik to the app. Traefik's

| Purpose   | Ingress Controller | Ingress Rule        |
|-----------|--------------------|---------------------|
| Type      | Binary (program)   | Rules               |
| Resource  | Pod                | Definitions         |
| Namespace | Any                | Same as the service |

[This answer]: https://stackoverflow.com/a/63167986

## Install k3s cluster

Download [k3sup](https://github.com/alexellis/k3sup/releases) and follow their instructions
to [setup a kubernetes server](https://github.com/alexellis/k3sup#-setup-a-kubernetes-server-with-k3sup).

`k3sup` creates a `kubeconfig` in the current directory with instructions to export the full path as `$KUBECONFIG`.
Alternatively,
the [k3s docs](https://rancher.com/docs/k3s/latest/en/cluster-access/#accessing-the-cluster-from-outside-with-kubectl)
explain the config can be saved to `~/.kube/config` without requiring `$KUBECONFIG` by using the `--local-path` switch
to `k3sup`.

Once installed, copy the config to your local machine so that you can administer the cluster remotely. Make
sure `~/.kube/config` points to the k8s cluster and not localhost.

```bash
mkdir --parents ~/.kube
scp root@sns1:.kube/config ~/.kube/config
```

## Applications

### Kubernetes Dashboard

Follow the [k3s docs](https://rancher.com/docs/k3s/latest/en/installation/kube-dashboard/) to install
the [kubernetes dashboard][].

[k3s docs]: https://rancher.com/docs/k3s/latest/en/installation/kube-dashboard/

[kubernetes dashboard]: https://github.com/kubernetes/dashboard

### Prometheus stack

Install `kube-prometheus-stack`.
See [this question](https://stackoverflow.com/questions/54422566/what-is-the-difference-between-the-core-os-projects-kube-prometheus-and-promethe)
for the difference between [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
and [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus). Use `helm` to install Prometheus.

> Basically, CoreOS's kube-prometheus deploys the Prometheus Stack using Ksonnet.
> Prometheus Operator Helm Chart wraps kube-prometheus / achieves the same end result but with Helm.

### Cert Manager

Install `cert-manager` using [helm](https://cert-manager.io/docs/installation/helm/).

```bash
./cert-manager/cert-manager.sh
```

### Swagger API

Run swagger auto-complete in the IDE. The proxy should already be running.

```bash
./swagger/run-swagger.sh
```

## Useful commands

```bash
kubectl get events --sort-by='{.lastTimestamp}' --all-namespaces --watch
```

- [Local install](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/)

## To Learn

- [sops](https://github.com/mozilla/sops)
- [age](https://github.com/FiloSottile/age)
- [Encrypt Your Sensitive Information Before Storing It - Encrypting with Mozilla SOPS and AGE](https://docs.technotim.live/posts/install-mozilla-sops/)
- [Wildcard Certificates with Traefik + cert-manager + Let's Encrypt in Kubernetes Tutorial](https://docs.technotim.live/posts/kube-traefik-cert-manager-le/)
    - Start at 12:00
- [Monitoring Your Kubernetes Cluster with Grafana, Prometheus, and Alertmanager](https://docs.technotim.live/posts/rancher-monitoring/)
- Other
    - [Use Port Forwarding to Access Applications in a Cluster](https://kubernetes.io/docs/tasks/access-application-cluster/port-forward-access-application-cluster/)
    - [Kubernetes Dashboard](https://docs.k3s.io/installation/kube-dashboard)
    - [TLS on K3s with traefik, cert manger and letsencrypt](https://www.thebookofjoel.com/k3s-cert-manager-letsencrypt)
    - [Services without selectors](https://kubernetes.io/docs/concepts/services-networking/service/#services-without-selectors)
    - [HTTPS on Kubernetes Using Traefik Proxy](https://traefik.io/blog/https-on-kubernetes-using-traefik-proxy/)

## Resources

- Kubernetes
    - [Deployments](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
    - API
        - [Service v1 core](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.24/#service-v1-core)
        - [API Conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
    - [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
    - Concepts
        - [Services, Load Balancing, and Networking](https://kubernetes.io/docs/concepts/services-networking/)
- Package Manager
    - [Helm](https://github.com/helm/helm)
        - [Quickstart Guide](https://helm.sh/docs/intro/quickstart/)
    - [k3s Helm](https://docs.k3s.io/helm)
    - [ArtifactHUB cert-manager](https://artifacthub.io/packages/helm/cert-manager/cert-manager)
    - Helm Charts
        - [k8s at home](https://github.com/bjw-s/helm-charts) ([Search](https://nanne.dev/k8s-at-home-search/#/))
        - [k8s at home; deprecated](https://github.com/k8s-at-home/charts)
- k3s
    - [K3s Server Configuration](https://rancher.com/docs/k3s/latest/en/installation/install-options/server-config/)
    - [k3sup](https://github.com/alexellis/k3sup#-setup-a-kubernetes-server-with-k3sup)
- Apps
    - [cert-manager](https://github.com/cert-manager/cert-manager)
        - [Installation](https://cert-manager.io/docs/installation/)
    - [Kubernetes Dashboard](https://rancher.com/docs/k3s/latest/en/installation/kube-dashboard/)
        - [GitHub](https://github.com/kubernetes/dashboard)
- [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack#multiple-releases)
    - Use this one
        - [kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)
        - [Prometheus Operator](https://github.com/prometheus-operator/prometheus-operator)
        - rpi4cluster [Install Prometheus Operator](https://rpi4cluster.com/monitoring/k3s-prometheus-oper/)
- Smallstep
    - [Getting Started](https://smallstep.com/docs/step-ca/getting-started)
    - [ACME Basics](https://smallstep.com/docs/step-ca/acme-basics)
    - [Integrate Kubernetes cert-manager with an internal ACME CA](https://smallstep.com/docs/tutorials/kubernetes-acme-ca)
- Blogs
    - [Everything Useful I Know About kubectl](https://www.atomiccommits.io/everything-useful-i-know-about-kubectl)
    - [Deploying Node.js apps in a local Kubernetes cluster](https://learnk8s.io/deploying-nodejs-kubernetes)
    - [My road to self hosted kubernetes with k3s - Cert Manager](https://blog.internetz.me/posts/my-road-to-self-hosted-kubernetes-with-k3s_cert-manager/)
    - [Wildcard Certificates with Traefik + cert-manager + Let's Encrypt in Kubernetes Tutorial](https://docs.technotim.live/posts/kube-traefik-cert-manager-le/)
        - [traefik cert-manager let's encrypt](https://github.com/techno-tim/launchpad/tree/master/kubernetes/traefik-cert-manager)
    - [Implementing GitOps on Kubernetes Using K3s, Rancher, Vault and Argo CD](https://www.suse.com/c/rancher_blog/implementing-gitops-on-kubernetes-using-k3s-rancher-vault-and-argo-cd/)
- Other
    - [Kubernetes Failure Stories](https://k8s.af/)
    - [TacticalRMM Kubernetes manifests](https://github.com/amidaware/trmm-awesome/tree/main/kubernetes)
    - [Knote js](https://github.com/learnk8s/knote-js/tree/master)
    - [K3s with Let's Encrypt](https://stackoverflow.com/questions/63872087/k3s-with-lets-encrypt)
    - [Ingress with Traefik on K3s](https://itnext.io/ingress-with-treafik-on-k3s-53db6e751ed3)
    - [Traefik Multi-Cluster Proxy](https://gitlab.com/monachus/channel/-/tree/master/resources/2021-11-30-traefik-tailscale-proxy)
- To Be Categorized
