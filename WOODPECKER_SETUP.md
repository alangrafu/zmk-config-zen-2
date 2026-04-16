# Woodpecker CI Setup for ZMK Config

This document explains how to set up and use Woodpecker CI with this ZMK configuration repository.

## Overview

This repository has been configured to work with Woodpecker CI, an open-source CI/CD tool that can be self-hosted. The pipeline automatically builds ZMK firmware for your Corneish Zen keyboard.

## Files Added

- `.woodpecker.yml` - Woodpecker CI pipeline configuration

## How It Works

The Woodpecker pipeline:

1. **Parses `build.yaml`** to determine which boards to build
2. **Initializes a West workspace** using your `config/west.yml`
3. **Updates dependencies** (Zephyr, ZMK modules)
4. **Builds firmware** for each board variant in parallel
5. **Collects artifacts** (`.uf2` files) for download

### Matrix Build

The pipeline uses Woodpecker's matrix feature to build firmware for multiple boards in parallel:
- `corneish_zen_v2_left` - Left half of the keyboard
- `corneish_zen_v2_right` - Right half of the keyboard

Each matrix entry runs as an independent, parallel workflow.

## Setup Instructions

### Prerequisites

1. **Woodpecker Server**: You need a running Woodpecker CI instance
   - See: https://woodpecker-ci.org/docs/intro
   - Can be self-hosted on your own infrastructure

2. **Woodpecker Agent**: At least one agent with Docker support
   - The agent must be able to run Docker containers
   - Recommended: Linux-based agent (the ZMK build image is Linux-based)

### Configuration Steps

1. **Enable the Repository in Woodpecker**
   - Log into your Woodpecker instance
   - Go to your repository settings
   - Enable the repository for CI builds

2. **Verify Agent Labels** (optional)
   - The pipeline doesn't require specific labels by default
   - If you want to route to specific agents, add a `labels:` section to `.woodpecker.yml`

3. **Push to Trigger**
   - Push to any branch to trigger the pipeline
   - Or trigger manually from the Woodpecker UI

## Running the Pipeline

### Automatic Triggers

The pipeline runs on:
- `push` events
- `pull_request` events
- `tag` events
- Manual trigger (from Woodpecker UI)

### Manual Trigger

1. Go to your repository in Woodpecker
2. Click on the "Run" button
3. Select the branch you want to build
4. The pipeline will start immediately

## Artifacts

### What Gets Built

After a successful build, the following artifacts are created:

- `corneish_zen_v2_left_with_studio.uf2` - Left side with ZMK Studio support
- `corneish_zen_v2_right-zmk.uf2` - Right side standard firmware
- `*.config` - Kconfig files (for debugging)
- `*.dts` - DeviceTree files (for debugging)

### Downloading Artifacts

Woodpecker stores artifacts in the workspace volume during the pipeline run. You can:

1. **Via Woodpecker UI**: 
   - Navigate to the pipeline run
   - Look for artifact download links (if your Woodpecker instance has artifact retention enabled)

2. **Via Woodpecker API**:
   ```bash
   curl -H "Authorization: Bearer <token>" \
     https://your-woodpecker-instance/api/repos/<owner>/<repo>/builds/<build-id>/logs
   ```

3. **From Logs**: 
   - The `summary` step prints artifact locations
   - Files are in the `artifacts/` directory in the workspace

## Customization

### Adding New Boards

Edit `build.yaml` and add new board entries:

```yaml
include:
  - board: corneish_zen_v2_left
  - board: corneish_zen_v2_right
  - board: your_new_board  # Add this line
```

Then update the matrix in `.woodpecker.yml`:

```yaml
matrix:
  BOARD:
    - corneish_zen_v2_left
    - corneish_zen_v2_right
    - your_new_board  # Add this line
```

### Modifying Build Steps

Edit `.woodpecker.yml` to:
- Add custom build steps
- Change Docker images
- Add caching (if your Woodpecker instance supports it)
- Add notifications (email, webhook, etc.)

### Enabling Caching

If your Woodpecker instance supports volume caching, you can cache the west modules to speed up builds:

```yaml
# Add to steps that use west modules
backend_options:
  docker:
    volumes:
      - zmk-cache:/woodpecker/src/github.com/<owner>/<repo>/modules
      - zmk-cache:/woodpecker/src/github.com/<owner>/<repo>/zephyr
```

## Troubleshooting

### Build Fails with "No firmware artifact found"

- Check that `build.yaml` is correctly formatted
- Verify your keyboard configuration in `config/`
- Check the build logs for compilation errors

### Pipeline Doesn't Start

- Verify the repository is enabled in Woodpecker
- Check that you have at least one active agent
- Ensure the agent has Docker support enabled

### Missing Artifacts

- Artifacts are only stored during the pipeline run
- If artifact retention is not configured, they may be deleted after the run
- Download artifacts immediately after build completion

## Comparison with GitHub Actions

| Feature | GitHub Actions | Woodpecker CI |
|---------|---------------|---------------|
| Matrix Builds | ✅ Native | ✅ Native |
| Docker Containers | ✅ | ✅ |
| Artifact Upload | ✅ GitHub API | Workspace volume |
| Caching | ✅ actions/cache | Volume mounts (if configured) |
| Self-Hosted | Runners required | Designed for it |
| Cost | Free for public repos | Self-hosted (your infrastructure) |

## Additional Resources

- [Woodpecker CI Documentation](https://woodpecker-ci.org/docs/intro)
- [ZMK Firmware Documentation](https://zmk.dev/docs)
- [Corneish Zen Configuration](https://zmk.dev/docs/boards/corneish-zen)

## Support

If you encounter issues:
1. Check the pipeline logs in Woodpecker UI
2. Verify your `build.yaml` syntax with a YAML validator
3. Test locally using the `build.sh` script
4. Check Woodpecker agent logs for Docker issues
