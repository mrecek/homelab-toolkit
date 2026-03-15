# infra-toolkit

General-purpose infrastructure operations container for homelab CI runners and development workspaces.

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
    container: ghcr.io/mrecek/infra-toolkit:latest
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
  name = "ghcr.io/mrecek/infra-toolkit:latest"
}
```

The image includes a non-root `ops` user (UID 1000) with passwordless sudo.

### Local Development

```bash
docker run -it --rm ghcr.io/mrecek/infra-toolkit:latest
```

## Tags

| Tag | Description |
|-----|-------------|
| `latest` | Current main branch build |
| `YYYY.MM.DD` | CalVer date of build |
| `vX.Y.Z` | Pinned release version |
| `<sha>` | Git commit SHA for traceability |

Weekly automated rebuilds ensure base image security patches are picked up.

## Building Locally

```bash
docker build -t infra-toolkit .
```
