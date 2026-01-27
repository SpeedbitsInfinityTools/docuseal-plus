# Making Docker Images Public on GitHub Container Registry

## Problem
When pulling Docker images from `ghcr.io/speedbitsinfinitytools/docuseal-plus:latest`, you get an "unauthorized" error because the packages are private by default.

## Solution: Make Packages Public

### Step 1: Navigate to Your Package
1. Go to your GitHub repository: https://github.com/SpeedbitsInfinityTools/docuseal-plus
2. Click on the **"Packages"** link in the right sidebar (or go directly to: https://github.com/orgs/SpeedbitsInfinityTools/packages)
3. Find the package named `docuseal-plus` (it should show as `ghcr.io/speedbitsinfinitytools/docuseal-plus`)

### Step 2: Access Package Settings
1. Click on the `docuseal-plus` package
2. Click on **"Package settings"** (gear icon) in the right sidebar

### Step 3: Change Visibility to Public
1. Scroll down to the **"Danger Zone"** section
2. Find **"Change visibility"**
3. Click **"Change visibility"**
4. Select **"Public"**
5. Type the package name to confirm: `speedbitsinfinitytools/docuseal-plus`
6. Click **"I understand, change visibility"**

### Alternative: Via GitHub API
If you prefer using the API, you can use this curl command (replace `YOUR_TOKEN` with your GitHub PAT):

```bash
curl -X PATCH \
  -H "Authorization: token YOUR_TOKEN" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/orgs/SpeedbitsInfinityTools/packages/container/docuseal-plus \
  -d '{"visibility":"public"}'
```

## Verify Public Access
After making it public, test pulling without authentication:

```bash
docker pull ghcr.io/speedbitsinfinitytools/docuseal-plus:latest
```

This should work without requiring login.

## Notes
- Making a package public allows **anyone** to pull it without authentication
- The package will still be linked to your repository
- You can change it back to private anytime in the same settings
- All versions/tags of the package will become public
