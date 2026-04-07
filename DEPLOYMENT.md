# Chatwoot Deployment Guide

This document explains how to build, deploy, and sync custom Chatwoot changes with future releases.

## 🐳 Docker Deployment Setup

### Container Registry
- **Registry:** GitHub Container Registry (GHCR)
- **Image URL:** `ghcr.io/urbany/chatwoot`
- **Authentication:** Automatic via GitHub (no secrets needed)

### Docker Workflow
**File:** `.github/workflows/build-custom-docker.yml`

**Triggers:**
- Push to `develop` → `ghcr.io/urbany/chatwoot:develop`
- Push to `master` → `ghcr.io/urbany/chatwoot:latest`
- Version tags (`v*`) → Multiple tags (version, major.minor, latest)
- Manual trigger via GitHub Actions UI

**Features:**
- Community Edition (CE) builds only
- Strips enterprise code
- Multi-platform support (linux/amd64)
- Docker layer caching
- Automatic authentication

## 🚀 Deployment Process

### 1. Feature Development
```bash
# Work on feature branch
git checkout -b feature/your-feature
# Make changes
git add .
git commit -m "feat: add your feature"
git push origin feature/your-feature
```

**Docker Build:** `ghcr.io/urbany/chatwoot:feature-your-feature`

### 2. Integration Testing
```bash
# Merge to develop for testing
git checkout develop
git merge feature/your-feature
git push origin develop
```

**Docker Build:** `ghcr.io/urbany/chatwoot:develop`

### 3. Production Release (Tagged)
```bash
# Create and push version tag
git tag -a v4.12.1-feature-name -m "Description of changes"
git push origin v4.12.1-feature-name
```

**Docker Tags Created:**
- `ghcr.io/urbany/chatwoot:v4.12.1-feature-name`
- `ghcr.io/urbany/chatwoot:4.12.1`
- `ghcr.io/urbany/chatwoot:4.12`

### 4. Manual Docker Build
1. Go to: https://github.com/urbany/chatwoot/actions/workflows/build-custom-docker.yml
2. Click "Run workflow"
3. Select branch
4. Click "Run workflow"

## 🔄 Syncing with Future Chatwoot Releases

### Understanding the Branch Structure

```
chatwoot/chatwoot (upstream)
├── master (stable releases)
├── develop (development branch)
└── release/x.x.x (release branches)

urbany/chatwoot (your fork)
├── master (sync with upstream master)
├── develop (sync with upstream develop)
├── custom-v4.8.0 (your custom base version)
└── feature/* (your feature branches)
```

### Sync Strategy

**Option 1: Track Upstream Release (Recommended)**
```bash
# Add upstream remote if not exists
git remote add upstream https://github.com/chatwoot/chatwoot.git

# Fetch latest upstream
git fetch upstream

# Create custom version branch from upstream release
git checkout -b custom-v4.9.0 upstream/v4.9.0

# Cherry-pick your custom commits
git log custom-v4.8.0..custom-v4.8.0-whatsapp --oneline
# For each commit you want to port:
git cherry-pick <commit-sha>

# Push to your fork
git push origin custom-v4.9.0
```

**Option 2: Rebase Feature Branch**
```bash
# Update your develop branch
git checkout develop
git fetch upstream
git rebase upstream/develop

# Rebase your feature branch
git checkout feature/your-feature
git rebase develop

# Push updated feature branch
git push origin feature/your-feature --force-with-lease
```

**Option 3: Merge Upstream into Custom Branch**
```bash
# Create new custom version
git checkout -b custom-v4.9.0 upstream/v4.9.0

# Merge your previous custom branch
git merge custom-v4.8.0-whatsapp --no-edit

# Resolve conflicts if any
# Push to fork
git push origin custom-v4.9.0
```

### Keeping Track of Custom Changes

**Document your custom commits:**
```bash
# List custom commits between versions
git log --oneline custom-v4.8.0..custom-v4.8.0-whatsapp > custom-commits-v4.8.0.txt
```

**File:** `CUSTOM_CHANGES.md` (maintain this file)
```markdown
## Custom Changes by Version

### v4.8.1-whatsapp-templates
- Added WhatsApp templates management UI
- Added API endpoint for fetching templates
- Controller: `whatsapp_templates_controller.rb`
- Vue Component: `WhatsAppTemplatesPage.vue`
- Routes: `/api/v1/accounts/:account_id/inboxes/:inbox_id/whatsapp_templates`

### Future v4.9.0
- (to be filled)
```

## 📦 K8s Deployment

### Update Image Reference
```yaml
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: chatwoot
spec:
  template:
    spec:
      containers:
      - name: chatwoot
        image: ghcr.io/urbany/chatwoot:v4.12.1-whatsapp-templates
        imagePullPolicy: Always
```

### Deploy New Version
```bash
# Update image tag
kubectl set image deployment/chatwoot chatwoot=ghcr.io/urbany/chatwoot:v4.12.1-whatsapp-templates

# Or apply updated manifest
kubectl apply -f deployment.yaml

# Check rollout status
kubectl rollout status deployment/chatwoot
```

## 🛠️ Troubleshooting

### Docker Build Failures
```bash
# Check workflow logs
gh run list --repo urbany/chatwoot --workflow=build-custom-docker.yml

# View specific run
gh run view <run-id> --repo urbany/chatwoot
```

### Sync Conflicts
```bash
# Check what's different
git diff custom-v4.8.0 upstream/v4.9.0

# See merge conflicts before merging
git merge --no-commit --no-ff custom-v4.8.0-whatsapp
```

### Verify Docker Image
```bash
# Pull and test locally
docker pull ghcr.io/urbany/chatwoot:v4.12.1-whatsapp-templates
docker run -p 3000:3000 ghcr.io/urbany/chatwoot:v4.12.1-whatsapp-templates
```

## 📝 Release Checklist

Before releasing:
- [ ] Code reviewed and tested
- [ ] Linting passes (RuboCop, ESLint)
- [ ] Database migrations prepared
- [ ] Environment variables documented
- [ ] Docker image builds successfully
- [ ] K8s deployment tested in staging
- [ ] Backup plan ready (rollback procedure)
- [ ] Documentation updated (this file)

After releasing:
- [ ] Monitor K8s pods for issues
- [ ] Check application logs
- [ ] Verify WhatsApp templates functionality
- [ ] Update CUSTOM_CHANGES.md
- [ ] Tag in repository for future reference

## 🔗 Useful Links

- Your Fork: https://github.com/urbany/chatwoot
- GitHub Actions: https://github.com/urbany/chatwoot/actions
- Container Registry: https://github.com/urbany/chatwoot/pkgs/container/chatwoot
- Upstream Chatwoot: https://github.com/chatwoot/chatwoot
