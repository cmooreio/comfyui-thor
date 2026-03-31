# comfyui-thor

ComfyUI Docker image optimized for NVIDIA Jetson Thor (JetPack 7 / CUDA 13 / PyTorch 2.9).

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
- `cmooreio/comfyui-thor:<version>` - ComfyUI version (e.g., `v0.18.3`)

## Updating ComfyUI Version

1. Check the current upstream tag: https://github.com/Comfy-Org/ComfyUI/tags
2. Update `COMFYUI_VERSION` and `COMFYUI_REF` in `Dockerfile`
3. If needed, update `COMFYUI_MANAGER_REF` to a compatible pinned commit
4. Regenerate the hash-locked Python inputs: `./generate-lockfiles.sh`
5. Build and push: `./build.sh --push`

The lockfiles target the Jetson Thor build environment:
- Python `3.12`
- Linux `aarch64`
- torch stack constrained by `torch-base-constraints.txt`

## Custom Nodes / Extra Packages

Edit `extra-requirements.txt` to add Python packages needed by custom nodes.
After editing that file, regenerate `requirements-extra.lock.txt` with `./generate-lockfiles.sh`.
Those packages are baked in at image build time. Runtime installs are disabled by default;
opt in with `COMFYUI_ALLOW_RUNTIME_PIP=1` only when you explicitly accept the drift risk.
