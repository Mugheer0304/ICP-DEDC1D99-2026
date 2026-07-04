# CI/CD Pipeline Demo Project

A complete, working CI/CD pipeline built with **GitHub Actions**. It automatically
lints, tests, builds, containerizes, and deploys a small Node.js/Express API
every time code is pushed.

## Project structure

```
ci-cd-demo-project/
├── app/
│   ├── index.js          # Express API (the app being shipped)
│   ├── index.test.js      # Jest unit + integration tests
│   ├── package.json       # npm scripts: lint, test, build
│   └── .eslintrc.json      # Lint rules
├── Dockerfile              # Multi-stage build → small production image
├── .gitignore
└── .github/
    └── workflows/
        └── ci-cd.yml       # The pipeline itself (5 stages)
```

## What the pipeline does (5 stages)

| # | Stage | Runs when | What it does |
|---|-------|-----------|--------------|
| 1 | **Lint** | every push/PR | Runs ESLint to catch syntax/style errors early |
| 2 | **Test** | after lint passes | Runs Jest (7 unit + integration tests), uploads coverage report |
| 3 | **Build** | after tests pass | Confirms the app boots correctly, packages a build artifact |
| 4 | **Docker Build & Push** | only on `main` branch pushes | Builds a Docker image and pushes it to Docker Hub |
| 5 | **Deploy** | only on `main`, after image push | Deploys the new image to your server/hosting provider |

Each stage only runs if the previous one succeeds (`needs:` keyword), and stages
4–5 are restricted to the `main` branch so feature branches and pull requests
only go through lint/test/build — they never accidentally deploy.

---

## Step-by-step: how to set this up yourself

### Step 1 — Get the project onto your machine
Download the files from this chat, then in a terminal:
```bash
cd ci-cd-demo-project
git init
git add .
git commit -m "Initial commit: app + CI/CD pipeline"
```

### Step 2 — Create a GitHub repository and push
1. Go to https://github.com/new and create an empty repository (don't add a README there).
2. Connect your local project to it and push:
```bash
git remote add origin https://github.com/<your-username>/<your-repo>.git
git branch -M main
git push -u origin main
```

### Step 3 — Verify the app runs locally (optional but recommended)
```bash
cd app
npm install
npm run lint     # should exit with no errors
npm test         # should show 7 passing tests
npm run build    # should print "Build check passed"
npm start        # starts the API on http://localhost:3000
```
Test it: `curl http://localhost:3000/health` → `{"status":"ok"}`

### Step 4 — Understand what triggers the pipeline
Open `.github/workflows/ci-cd.yml`. The `on:` block says the pipeline runs on:
- any push to `main` or `develop`
- any pull request targeting `main`
- manually, via the "Run workflow" button (Actions tab → workflow_dispatch)

### Step 5 — Watch it run automatically
As soon as you pushed in Step 2, GitHub Actions already ran stages 1–3
(lint, test, build) automatically. Go to your repo → **Actions** tab to watch
it live. Click the running/completed workflow to see each stage's logs.

### Step 6 — Set up Docker Hub for the image-publishing stage
The "Docker Build & Push" stage needs credentials stored as **GitHub Secrets**
(never hardcode credentials in the YAML file):
1. Create a free account at https://hub.docker.com if you don't have one.
2. In Docker Hub: Account Settings → Security → **New Access Token**, copy it.
3. In your GitHub repo: Settings → Secrets and variables → Actions →
   **New repository secret**, add:
   - `DOCKERHUB_USERNAME` → your Docker Hub username
   - `DOCKERHUB_TOKEN` → the access token you just created

### Step 7 — Configure the deploy stage for your target
Stage 5 is intentionally left as a **template** with two ready-made options
commented out in `ci-cd.yml` — pick whichever matches where you host the app:

**Option A: Deploy to your own server (VM/VPS) via SSH**
Uncomment the `appleboy/ssh-action` block and add these secrets:
- `DEPLOY_HOST` — server IP or domain
- `DEPLOY_USER` — SSH username
- `DEPLOY_SSH_KEY` — private SSH key with access to that server

**Option B: Deploy to a platform with a deploy-hook URL (e.g., Render, Railway)**
Uncomment the `curl` deploy-hook block and add:
- `RENDER_DEPLOY_HOOK_URL` — the deploy hook URL from your hosting dashboard

Until you configure one of these, the workflow runs a **simulated deploy step**
so the pipeline completes end-to-end without errors — replace it once you pick
a real target.

### Step 8 — Trigger a full run through all 5 stages
Make a small change on `main` (or merge a PR into `main`) and push:
```bash
git commit --allow-empty -m "Trigger full pipeline"
git push
```
Watch the Actions tab — you'll see all 5 jobs run in sequence, each gated on
the previous one succeeding.

### Step 9 — (Optional) Add branch protection
Settings → Branches → Add rule for `main` → require the "Test" and "Build"
status checks to pass before merging. This stops anyone from merging code
that fails the pipeline.

### Step 10 — Extend it
Ideas once the basics are working:
- Add a `staging` environment/job that deploys `develop` branch pushes to a staging URL
- Add Slack/Discord notifications on failure (`8398a7/action-slack`)
- Add security scanning (`npm audit`, `trivy` for the Docker image)
- Add semantic-release for automatic versioning and changelogs

---

## Why each design choice was made
- **`needs:`** chains jobs into stages instead of running everything in parallel blindly — a broken lint should stop tests from even starting, saving CI minutes.
- **`if: github.ref == 'refs/heads/main'`** on stages 4–5 keeps pull requests safe: they get full validation but can never trigger a real deployment.
- **Multi-stage Dockerfile** keeps the final image small by excluding dev dependencies and build tools.
- **Secrets, not hardcoded values** for all credentials — this is a hard requirement for any real-world pipeline.
- **`workflow_dispatch`** lets you manually re-run a deploy without needing a new commit.
