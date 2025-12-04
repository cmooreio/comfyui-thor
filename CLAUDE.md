# ComfyUI Thor Docker Image

## Tagging Convention

When building and pushing this image, use exactly these three tags:

```bash
docker build \
  -t cmooreio/comfyui-thor:latest \
  -t cmooreio/comfyui-thor:<comfyui-version> \
  -t cmooreio/comfyui-thor:<git-sha> \
  .
```

Example:
```bash
docker build \
  -t cmooreio/comfyui-thor:latest \
  -t cmooreio/comfyui-thor:v0.3.76 \
  -t cmooreio/comfyui-thor:abc1234 \
  .
```

- `latest` - Always points to most recent build
- `<comfyui-version>` - Matches COMFYUI_VERSION ARG in Dockerfile (e.g., v0.3.76)
- `<git-sha>` - Short git commit hash from this repo

Do NOT use other tags like base image version (25.11-py3) or component versions (torchaudio, pytorch).
