# Jetson Thor / JetPack 7 / CUDA 13 / PyTorch 2.8 base
FROM nvcr.io/nvidia/pytorch:25.08-py3

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

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

# Clone official ComfyUI
RUN git clone --depth=1 https://github.com/comfyanonymous/ComfyUI.git ComfyUI

WORKDIR /opt/ComfyUI

# Install torchaudio from Jetson AI Lab (CUDA-enabled for Thor, matches PyTorch 2.8.0)
RUN pip install --index-url https://pypi.jetson-ai-lab.io/sbsa/cu130 "torchaudio==2.8.0" --no-deps

# Install Python deps (skip torch/torchvision/torchaudio - already provided)
RUN pip install --upgrade pip && \
    grep -vE '^torch(vision|audio)?$' requirements.txt > requirements-filtered.txt && \
    echo "opencv-python" >> requirements-filtered.txt && \
    pip install -r requirements-filtered.txt

# Create model directories (defaults, but we'll also mount external models)
RUN mkdir -p \
    /opt/ComfyUI/models/text_encoders \
    /opt/ComfyUI/models/vae \
    /opt/ComfyUI/models/diffusion_models \
    /models

# Install official ComfyUI Manager for node pack management via web UI
RUN git clone --depth=1 https://github.com/Comfy-Org/ComfyUI-Manager.git \
    /opt/ComfyUI/custom_nodes/ComfyUI-Manager && \
    pip install -r /opt/ComfyUI/custom_nodes/ComfyUI-Manager/requirements.txt

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ComfyUI default port
EXPOSE 8188

ENTRYPOINT ["/entrypoint.sh"]
CMD ["python3", "main.py", "--listen", "0.0.0.0", "--port", "8188"]
