**Objective:** Create a reusable, open-source "VibeBox Base" Docker image. This image will serve as a secure foundation for Vibe Coding agents, decoupling tooling from domain logic.

**Output:** A published Docker image on DockerHub (`your-username/vibebox-base`) updated automatically via GitHub Actions.

---

## 🛑 CHECKPOINT 1: Human Setup (Required)

*Do not proceed until these steps are marked complete.*

* [ ] **Create GitHub Repository:** Create a public empty repository (e.g., `vibebox-base`).
* [ ] **Create DockerHub Account:** Ensure you have a valid account at [hub.docker.com](https://hub.docker.com).
* [ ] **Generate Access Token:** Go to DockerHub Settings -> Security -> New Access Token (Read/Write/Delete permissions).
* [ ] **Set GitHub Secrets:**
* Go to Repo Settings -> Secrets and variables -> Actions -> New Repository Secret.
* `DOCKERHUB_USERNAME`: Your Docker ID.
* `DOCKERHUB_TOKEN`: The Access Token you just generated.



---

## 🚀 Phase 2: Foundation (Agent Task)

*Create the following files to define the image.*

### 1. `Dockerfile`

Create a `Dockerfile` in the root.
**Requirements:**

* **Base Image:** `mcr.microsoft.com/devcontainers/base:debian-bookworm` (Stable, slim).
* **Labels:** OCI compliant source/description labels.
* **System Deps:** `nodejs`, `npm`, `build-essential` (apt-get).
* **Vibe Tools:** Global install of `opencode-ai` and `vibebox` (npm).
* **Sandbox:** Create directory `/workspaces` with `777` permissions.
* **Entry:** Set `WORKDIR /workspaces` and `CMD ["/bin/bash"]`.

### 2. `vibebox.toml`

Create a default security configuration file in the root.
**Requirements:**

* **Mode:** Strict isolation.
* **Mounts:** Allow `/workspaces` (read-write).
* **Block:** Explicitly block access to root sensitive files (e.g., `/root/.ssh`, `/etc/shadow`).

---

## ⚙️ Phase 3: Automation (Agent Task)

*Set up the CI/CD pipeline to publish the image.*

### 3. `.github/workflows/publish.yml`

Create a GitHub Action workflow.
**Requirements:**

* **Trigger:** On `push` to `main`, `pull_request` to `main`, and `release` tags (`v*`).
* **Permissions:** `contents: read`, `packages: write`.
* **Steps:**
1. Checkout Code.
2. Setup Docker Buildx.
3. Login to DockerHub (using Secrets from Checkpoint 1).
4. Extract Metadata (Tags/Labels).
5. Build and Push to DockerHub.


* **Caching:** Enable GitHub Actions caching for faster builds.

---

## 🛡️ Phase 4: Maintenance (Agent Task)

*Ensure the image stays secure and up-to-date.*

### 4. `.github/dependabot.yml`

Create a Dependabot configuration.
**Requirements:**

* **Docker:** Check for updates to the `mcr.microsoft.com` base image weekly.
* **GitHub Actions:** Check for updates to the CI/CD actions (checkout, build-push, etc.) weekly.

---

## ✅ CHECKPOINT 5: Final Review (Human)

*Review the Agent's work before merging.*

* [ ] **Verify Files:** Check that `Dockerfile`, `vibebox.toml`, and `.github/` folders exist.
* [ ] **Commit & Push:** Commit the changes to `main`.
* [ ] **Verify Build:** Go to the "Actions" tab in GitHub and watch the pipeline run.
* [ ] **Verify Registry:** Check DockerHub to confirm the image `vibebox-base:latest` is published.
* [ ] **Verify Badges:** Check README.md badges show success (GitHub Actions badge may take 5-10 minutes to update due to caching).

---

## 🔄 Periodic Maintenance

*Ongoing tasks to keep the image healthy and up-to-date.*

### Weekly Checks

* [ ] **Review Dependabot PRs:** Check for automated dependency update PRs and merge if tests pass.
* [ ] **Verify Build Status:** Ensure latest workflow runs are succeeding at https://github.com/dlouwers/vibebox-base/actions
* [ ] **Check Badge Status:** Verify README badges display correctly (green success indicators).
* [ ] **Monitor DockerHub:** Confirm image tags are publishing correctly at https://hub.docker.com/r/dlouwers/vibebox-base

### Monthly Checks

* [ ] **Test Image Pull:** Run `docker pull dlouwers/vibebox-base:latest` and verify it works.
* [ ] **Review Security:** Check for any security advisories on base image or dependencies.
* [ ] **Validate Tools:** Test that `opencode-ai` and `vibebox` commands work inside the container.
* [ ] **DockerHub Token:** Verify Personal Access Token hasn't expired (regenerate if needed).

### When Issues Occur

* **Badge shows failure but build succeeds:** Wait 10 minutes for GitHub cache to refresh.
* **Build fails with "image not found":** Check base image tag is valid at https://mcr.microsoft.com
* **DockerHub push fails:** Verify `DOCKERHUB_TOKEN` secret is valid and has write permissions.
* **Dependabot PRs fail:** Review logs to identify if base image or action version has breaking changes.
