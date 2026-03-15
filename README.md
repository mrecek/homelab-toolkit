# homelab-toolkit

General-purpose homelab operations container for CI runners and development workspaces.

## What's Inside

| Category | Tools |
|----------|-------|
| **IaC** | Ansible, OpenTofu |
| **Cloud** | Azure CLI, Azure SDK (identity, keyvault) |
| **Dev** | mise, just, GitHub CLI, git |
| **Runtime** | Python 3.12, pip, jq, curl, openssh-client |
| **Ansible Collections** | ansible.posix, azure.azcollection |

## Usage

### GitHub Actions (self-hosted runner)

```yaml
jobs:
  deploy:
    runs-on: self-hosted
    container: ghcr.io/mrecek/homelab-toolkit:latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
      - run: ansible-playbook playbook.yml
```

### Coder Workspace

```hcl
resource "docker_image" "workspace" {
  name = "ghcr.io/mrecek/homelab-toolkit:latest"
}
```

The image includes a non-root `ops` user (UID 1000) with passwordless sudo.

### Local Development

```bash
docker run -it --rm ghcr.io/mrecek/homelab-toolkit:latest
```

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Current main branch build |
| `YYYY.MM.DD-<sha>` | CalVer date + short commit SHA (e.g., `2026.03.15-abc1234`) |

Every push to main produces both tags. Weekly automated rebuilds pick up base image security patches.

## Building Locally

```bash
docker build -t homelab-toolkit .
```
