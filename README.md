# DevOps Tools Setup Scripts

A curated collection of **universal, cross-distro installation scripts** for essential DevOps tools. These scripts are designed to work seamlessly across major Linux distributions including Ubuntu, Debian, Fedora, CentOS, Amazon Linux, and more.

> Built by [Divakar Chakali](https://github.com/divakarchakali-aka-DC) — DevSecOps enthusiast, automation architect, and visual storyteller.

---

## Tools Covered

| Tool            | Script Name                        | Description                                      |
|-----------------|------------------------------------|--------------------------------------------------|
| Terraform       | `terraform-setup.sh`               | Universal installer with distro detection        |
| Docker Compose  | `docker-compose.sh`                | Installs Docker Compose with version fallback    |
| Jenkins         | `jenkins-setup.sh`                 | Jenkins master setup                             |
| Jenkins Slave   | `jenkins-slave-setup.sh`           | Agent setup for Jenkins                          |
| SonarQube       | `sonar-setup.sh`                   | SonarQube server setup                           |
| Nexus           | `nexus-setup.sh`                   | Nexus Repository Manager setup                   |
| Tomcat          | `tomcat-setup.sh`                  | Apache Tomcat installation                       |
| Java            | `Java-setup.sh`                    | Installs OpenJDK (version controlled)            |
| Trivy           | `trivy-setup.sh`                   | Container vulnerability scanner setup            |
| ArgoCD          | `ArgoCD-setup-k8s.sh`              | ArgoCD install on Kubernetes                     |
| AWS CLI + EKS   | `awscli+kubectl+eksctl-setup.sh`   | CLI tools for AWS and EKS                        |
| Kops + Kubectl  | `kubectl+kops-setup.sh`            | Kubernetes CLI and Kops setup                    |
| EKS Cluster     | `eks-cluster-creation.sh`          | Script to bootstrap an EKS cluster               |
| RBAC + Secrets  | `k8s-acc-role-binding-secret.sh`   | Kubernetes RBAC and secret binding               |

---

## Features

- **Distro-aware**: Automatically detects package manager (`apt`, `yum`, `dnf`) and adapts.
- **Minimal dependencies**: Uses native tools like `wget`, `curl`, and `gpg`.
- **Idempotent**: Safe to re-run without breaking existing setups.
- **Readable & Modular**: Each script is self-contained and easy to audit or extend.

---

## Getting Started

Clone the repo:

```bash
git clone https://github.com/divakarchakali-aka-DC/DevOps-tools-setup.git
cd DevOps-tools-setup
```

Run any setup script:

```bash
chmod +x terraform-setup.sh
./terraform-setup.sh

---

## Uninstallation

Each tool can be cleanly removed. For example, to uninstall Terraform:

```bash
# Example: Uninstall Terraform
sudo rm -f $(command -v terraform)
sudo rm -f /etc/apt/sources.list.d/hashicorp.list
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg
sudo apt update
```

> Full uninstallation scripts coming soon!

---

## License

This project is licensed under the [MIT License](./LICENSE).

---

## Contributing

Pull requests are welcome! If you have a script for another DevOps tool or want to improve cross-platform support, feel free to fork and contribute.

---

## Contact

For feedback, suggestions, or collaboration:
- GitHub: [@divakarchakali-aka-DC](https://github.com/divakarchakali-aka-DC)
- Email: chdivakardiva192000@gmail.com

---

> _“Automate everything. Document what matters. Share what scales.”_

---
