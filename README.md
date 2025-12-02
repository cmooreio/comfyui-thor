# comfyui-thor

ComfyUI Docker image optimized for NVIDIA Jetson Thor (JetPack 7 / CUDA 13 / PyTorch 2.8).

## Requirements

- Must be built **on psythor** to ensure ARM64/Jetson compatibility
- Docker with NVIDIA runtime support
- Docker Hub credentials (for push)

## Building

```bash
# SSH to psythor
ssh psythor.local

# Navigate to build directory
cd /path/to/homelab/docker/comfyui-thor

# Build only
./build.sh

# Build and push to Docker Hub
./build.sh --push
```

## Tags

Each build creates three tags:
- `cmooreio/comfyui-thor:latest` - Latest build
- `cmooreio/comfyui-thor:<git-sha>` - Git commit SHA for traceability
- `cmooreio/comfyui-thor:<version>` - ComfyUI version (e.g., `0.3.76`)

## Updating ComfyUI Version

1. Check latest release: https://github.com/comfyanonymous/ComfyUI/releases
2. Update `COMFYUI_VERSION` in `Dockerfile`
3. Build and push: `./build.sh --push`

## Custom Nodes / Extra Packages

Edit `extra-requirements.txt` to add Python packages needed by custom nodes.
The entrypoint script will install any new packages at container startup.
