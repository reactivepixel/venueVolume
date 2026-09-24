FROM nvidia/cuda:12.8.0-devel-ubuntu24.04

ENV DEBIAN_FRONTEND=noninteractive \
    TORCH_CUDA_ARCH_LIST=8.9 \
    CUDAARCHS=89 \
    CMAKE_CUDA_ARCHITECTURES=89 \
    TORCH_HOME=/opt/torch-cache \
    PIP_NO_CACHE_DIR=1 \
    PIP_NO_INPUT=1 \
    GIT_TERMINAL_PROMPT=0 \
    PATH=/opt/venv/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates ffmpeg git cmake ninja-build build-essential pkg-config \
    python3 python3-dev python3-venv python3-pip \
    libboost-program-options-dev libboost-graph-dev libboost-system-dev \
    libeigen3-dev libopenimageio-dev libmetis-dev libgoogle-glog-dev \
    libgtest-dev libgmock-dev libsqlite3-dev libceres-dev libsuitesparse-dev \
    libcurl4-openssl-dev libssl-dev libopenblas-openmp-dev \
    libgl-dev libglew-dev libglib2.0-0 libgl1 libgomp1 \
    && mkdir -p /usr/include/opencv4 \
    && rm -rf /var/lib/apt/lists/*

# Ubuntu's COLMAP package is older and lacks CUDA, so build pinned 4.0.4.
RUN git clone --depth 1 --branch 4.0.4 https://github.com/colmap/colmap.git /opt/colmap \
    && cmake -S /opt/colmap -B /opt/colmap/build -GNinja \
       -DCMAKE_BUILD_TYPE=Release -DCMAKE_CUDA_ARCHITECTURES=89 \
       -DCUDA_ENABLED=ON -DGUI_ENABLED=OFF -DOPENGL_ENABLED=OFF \
       -DONNX_ENABLED=OFF -DCGAL_ENABLED=OFF -DDOWNLOAD_ENABLED=OFF \
       -DBLA_VENDOR=OpenBLAS \
    && cmake --build /opt/colmap/build --parallel 4 \
    && cmake --install /opt/colmap/build \
    && ldconfig \
    && colmap -h >/dev/null

COPY pins.txt /opt/mov2splat/pins.txt
RUN python3 -m venv /opt/venv \
    && python -m pip install --upgrade pip==25.1.1 setuptools==80.9.0 wheel==0.45.1 \
    && python -m pip install torch==2.7.1+cu128 torchvision==0.22.1+cu128 \
       --index-url https://download.pytorch.org/whl/cu128 \
    && python -m pip install --no-build-isolation -r /opt/mov2splat/pins.txt

# Upstream fused-ssim hardcodes sm_75 and sm_80 when no GPU is visible during
# docker build. Keep its pinned source, but compile only sm_89.
RUN git clone https://github.com/rahul-goel/fused-ssim.git /opt/fused-ssim \
    && cd /opt/fused-ssim \
    && git checkout 328dc9836f513d00c4b5bc38fe30478b4435cbb5 \
    && sed -i '/"-gencode=arch=compute_75,code=sm_75",/d; /"-gencode=arch=compute_80,code=sm_80",/d' setup.py \
    && python -m pip install --no-build-isolation /opt/fused-ssim

# The trainer lives in the pinned upstream source tree. Fetch LPIPS/AlexNet weights
# during image construction, so training never needs a network connection.
RUN git clone --depth 1 --branch v1.5.3 \
      https://github.com/nerfstudio-project/gsplat.git /opt/gsplat-source \
    && mkdir -p /opt/torch-cache \
    && python -c 'from torchmetrics.image.lpip import LearnedPerceptualImagePatchSimilarity; LearnedPerceptualImagePatchSimilarity(net_type="alex", normalize=True)' \
    && python -c 'import torch, gsplat; print(torch.__version__, gsplat.__version__)' \
    && python /opt/gsplat-source/examples/simple_trainer.py default --help >/dev/null

COPY scripts/run.sh /opt/mov2splat/run.sh
RUN chmod 755 /opt/mov2splat/run.sh
ENTRYPOINT ["/opt/mov2splat/run.sh"]
