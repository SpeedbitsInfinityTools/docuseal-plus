# Local Docker Build for DocuSeal Plus

Build multi-architecture Docker images (AMD64 + ARM64) locally on your ARM laptop and push to GitHub Container Registry.

## Why Build Locally?

| Build Machine | AMD64 Build | ARM64 Build |
|---------------|-------------|-------------|
| **ARM laptop** | Emulated (works well) | Native (fast) |
| **GitHub Actions** | Native (fast) | Emulated (crashes/timeout) |

Building on an ARM laptop is faster and more reliable for ARM64 images.

## Quick Start

```bash
# Navigate to this folder
cd deploy/localbuild

# 1. One-time setup (installs QEMU and buildx)
./setup.sh

# 2. Copy credentials template and fill in your GitHub PAT
cp keys.template.yml keys.yml
nano keys.yml  # Add your GitHub username and PAT

# 3. Login to GHCR
./login-ghcr.sh

# 4. Test build locally (no push)
./build-test.sh

# 5. Build and push release
./build-and-push.sh
```

## Scripts

| Script | Description |
|--------|-------------|
| `setup.sh` | One-time setup for Docker buildx and QEMU |
| `login-ghcr.sh` | Login to GitHub Container Registry |
| `build-test.sh` | Test build locally without pushing |
| `build-and-push.sh` | Interactive build and push to GHCR |
| `reset-builder.sh` | Fix EOF errors by recreating the builder |

## Credentials Setup

1. Create a GitHub Personal Access Token (PAT) at: https://github.com/settings/tokens
2. Required permissions: `write:packages`, `read:packages`
3. Copy `keys.template.yml` to `keys.yml` and fill in your credentials
4. **Never commit `keys.yml`** - it's in `.gitignore`

## Build Options

When running `build-and-push.sh`:

1. **Dev build** - Tags: `dev-YYYYMMDD-SHA` (no version bump)
2. **Latest build** - Tags: `latest` + dev tag (no version bump)
3. **Release build** - Tags: `latest` + base version + full version
   - Auto-increments the 4th digit: `2.3.0.1` → `2.3.0.2`
   - Updates the `VERSION` file

## Version Scheme

- `X.Y.Z` - Base DocuSeal version (upstream)
- `X.Y.Z.N` - Plus release number

Example: `2.3.0.2` means DocuSeal 2.3.0 with Plus release #2.

## Build Time

On an ARM laptop (e.g., Surface Pro X, Apple Silicon Mac):

- ARM64 only: ~10-15 minutes (native)
- AMD64 only: ~15-25 minutes (emulated)
- Both architectures: ~25-40 minutes

## Troubleshooting

### "Error: Buildx not set up"
Run `./setup.sh` first.

### "Invalid github_pat in keys.yml"
Make sure you've copied `keys.template.yml` to `keys.yml` and filled in your actual GitHub PAT.

### EOF error / "failed to receive status: rpc error"
This happens when the buildx daemon connection times out during long emulated builds.

**Fix:** Reset the builder:
```bash
./reset-builder.sh
```

Or manually:
```bash
docker buildx rm multiarch
./setup.sh
```

Then retry your build. The `build-test.sh` script also has an option 4 that does this automatically.

### Build crashes or hangs
Try building single architecture first with `./build-test.sh` to identify which platform has issues.

### Permission denied
Make sure scripts are executable: `chmod +x *.sh`

### WSL-specific issues
If builds fail on WSL, make sure:
1. Docker Desktop is running in Windows
2. WSL integration is enabled in Docker Desktop settings
3. You have enough disk space (builds can use 10-20GB temporarily)
