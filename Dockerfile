# Jetson Thor / JetPack 7 / CUDA 13 / PyTorch 2.9 base
FROM nvcr.io/nvidia/pytorch:25.10-py3@sha256:42263b2424fc237b34c4fc4a91c30d603c57eed36e37d31ff6d9a4f1f801edee

# ComfyUI version to install (pinned for reproducibility)
ARG COMFYUI_VERSION=v0.18.3
ARG COMFYUI_REF=173e1aa2dfd8e7bae53f64a538faa4c51e9efbcb
ARG COMFYUI_MANAGER_REF=8aca0751d13db3574b48b99bd28f2f432ddd025c

# SAM2 source archive — git+ URLs cannot be hash-verified by pip;
# we download the tarball and verify its sha256 before installing.
ARG SAM2_COMMIT=2b90b9f5ceec907a1c18123530e92e794ad901a4
ARG SAM2_SHA256=1f2fbfad3ffa38110368abac76c6ef9df9c282a66d5c2807bc94abf4d2fb30f8

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    COMFYUI_VERSION=${COMFYUI_VERSION} \
    COMFYUI_ALLOW_RUNTIME_PIP=0

# OS deps for ComfyUI (image, audio, video support)
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    wget \
    ca-certificates \
    libgl1 \
    libglib2.0-0 \
    ffmpeg \
    libsox-dev \
    libavformat-dev \
    libavcodec-dev \
    libavutil-dev \
    libavdevice-dev \
    libavfilter-dev \
    libswresample-dev \
    libswscale-dev \
    libsm6 \
    libxext6 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt

# Clone official ComfyUI at pinned version
RUN git clone --filter=blob:none https://github.com/Comfy-Org/ComfyUI.git ComfyUI && \
    cd ComfyUI && \
    git checkout --detach "${COMFYUI_REF}" && \
    test "$(git rev-parse HEAD)" = "${COMFYUI_REF}"

WORKDIR /opt/ComfyUI

# Install torchaudio from Jetson AI Lab (CUDA-enabled for Thor)
# Matches PyTorch 2.9 in 25.10 base image
RUN pip install --index-url https://pypi.jetson-ai-lab.io/sbsa/cu130 "torchaudio==2.9.0" --no-deps

# Install hash-locked Python deps for ComfyUI core and ComfyUI-Manager.
# The lockfile is generated from the pinned upstream commits by ./generate-lockfiles.sh
# and intentionally omits torch/torchvision/torchaudio because the base image supplies them.
COPY requirements-runtime.lock.txt /tmp/requirements-runtime.lock.txt
RUN pip install --require-hashes -r /tmp/requirements-runtime.lock.txt

# Extra packages for custom nodes (can be overridden via ConfigMap mount)
# These are pre-installed at build time for faster startup, but entrypoint
# will re-check and install any new/changed packages from this file
COPY extra-requirements.txt /opt/ComfyUI/extra-requirements.txt
COPY requirements-extra.lock.txt /tmp/requirements-extra.lock.txt
# Use --no-build-isolation so packages like sageattention can find torch during build
RUN pip install --no-build-isolation --require-hashes -r /tmp/requirements-extra.lock.txt

# Install SAM2 from a sha256-verified GitHub archive (git+ URLs are not hash-verifiable by pip)
RUN wget -q -O /tmp/sam2.tar.gz \
        "https://github.com/facebookresearch/sam2/archive/${SAM2_COMMIT}.tar.gz" \
    && echo "${SAM2_SHA256}  /tmp/sam2.tar.gz" | sha256sum -c - \
    && pip install --no-deps /tmp/sam2.tar.gz \
    && rm /tmp/sam2.tar.gz

# Create all model directories (both internal and external mount point)
# These match the MODEL_TYPES in entrypoint.sh for extra_model_paths.yaml generation
# Core: checkpoints, clip, clip_vision, configs, controlnet, diffusion_models, diffusers,
#       embeddings, gligen, hypernetworks, loras, style_models, text_encoders, unet,
#       upscale_models, latent_upscale_models, vae, vae_approx
# Custom nodes: audio_encoders, chibi-fonts, chibi-wildcards, classifiers, dynamicrafter_models,
#       inpaint, instantid, intrinsic_loras, ipadapter, kjnodes_fonts, layer_model, lIm, luts,
#       mediapipe, mmdets, mmdets_bbox, mmdets_segm, model_patches, onnx, photomaker,
#       prompt_generator, pulid, rembg, sams, t5, ultralytics, ultralytics_bbox,
#       ultralytics_segm, VHS_video_formats
RUN mkdir -p \
    /opt/ComfyUI/models/checkpoints /opt/ComfyUI/models/clip /opt/ComfyUI/models/clip_vision \
    /opt/ComfyUI/models/configs /opt/ComfyUI/models/controlnet /opt/ComfyUI/models/diffusion_models \
    /opt/ComfyUI/models/diffusers /opt/ComfyUI/models/embeddings /opt/ComfyUI/models/gligen \
    /opt/ComfyUI/models/hypernetworks /opt/ComfyUI/models/loras /opt/ComfyUI/models/style_models \
    /opt/ComfyUI/models/text_encoders /opt/ComfyUI/models/unet /opt/ComfyUI/models/upscale_models \
    /opt/ComfyUI/models/latent_upscale_models /opt/ComfyUI/models/vae /opt/ComfyUI/models/vae_approx \
    /opt/ComfyUI/models/audio_encoders /opt/ComfyUI/models/chibi-fonts /opt/ComfyUI/models/chibi-wildcards \
    /opt/ComfyUI/models/classifiers /opt/ComfyUI/models/dynamicrafter_models /opt/ComfyUI/models/inpaint \
    /opt/ComfyUI/models/instantid /opt/ComfyUI/models/intrinsic_loras /opt/ComfyUI/models/ipadapter \
    /opt/ComfyUI/models/kjnodes_fonts /opt/ComfyUI/models/layer_model /opt/ComfyUI/models/lIm \
    /opt/ComfyUI/models/luts /opt/ComfyUI/models/mediapipe /opt/ComfyUI/models/mmdets \
    /opt/ComfyUI/models/mmdets_bbox /opt/ComfyUI/models/mmdets_segm /opt/ComfyUI/models/model_patches \
    /opt/ComfyUI/models/onnx /opt/ComfyUI/models/photomaker /opt/ComfyUI/models/prompt_generator \
    /opt/ComfyUI/models/pulid /opt/ComfyUI/models/rembg /opt/ComfyUI/models/sams /opt/ComfyUI/models/t5 \
    /opt/ComfyUI/models/ultralytics /opt/ComfyUI/models/ultralytics_bbox /opt/ComfyUI/models/ultralytics_segm \
    /opt/ComfyUI/models/VHS_video_formats \
    /models/checkpoints /models/clip /models/clip_vision /models/configs /models/controlnet \
    /models/diffusion_models /models/diffusers /models/embeddings /models/gligen /models/hypernetworks \
    /models/loras /models/style_models /models/text_encoders /models/unet /models/upscale_models \
    /models/latent_upscale_models /models/vae /models/vae_approx /models/audio_encoders \
    /models/chibi-fonts /models/chibi-wildcards /models/classifiers /models/dynamicrafter_models \
    /models/inpaint /models/instantid /models/intrinsic_loras /models/ipadapter /models/kjnodes_fonts \
    /models/layer_model /models/lIm /models/luts /models/mediapipe /models/mmdets /models/mmdets_bbox \
    /models/mmdets_segm /models/model_patches /models/onnx /models/photomaker /models/prompt_generator \
    /models/pulid /models/rembg /models/sams /models/t5 /models/ultralytics /models/ultralytics_bbox \
    /models/ultralytics_segm /models/VHS_video_formats

# Install official ComfyUI Manager for node pack management via web UI
RUN git clone --filter=blob:none https://github.com/Comfy-Org/ComfyUI-Manager.git \
    /opt/ComfyUI/custom_nodes/ComfyUI-Manager && \
    git -C /opt/ComfyUI/custom_nodes/ComfyUI-Manager checkout --detach "${COMFYUI_MANAGER_REF}" && \
    test "$(git -C /opt/ComfyUI/custom_nodes/ComfyUI-Manager rev-parse HEAD)" = "${COMFYUI_MANAGER_REF}"

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ComfyUI default port
EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
