ARG CUDA_VERSION=12.4.1
ARG UBUNTU_VERSION=22.04
ARG PYTHON_VERSION=3.11
ARG CUPY_PACKAGE=cupy-cuda12x


# ---------- builder stage ----------
FROM docker.io/nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS builder

ARG PYTHON_VERSION
ARG CUPY_PACKAGE

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    UV_LINK_MODE=copy \
    UV_PYTHON_DOWNLOADS=never

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        curl \
        git \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        python${PYTHON_VERSION}-dev \
        python${PYTHON_VERSION}-venv \
        build-essential \
        cmake \
        ninja-build \
        swig \
        pkg-config \
        libgl1 \
        libglib2.0-0 \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3 \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python \
    && rm -rf /var/lib/apt/lists/*

COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv

ENV VIRTUAL_ENV=/opt/venv
RUN uv venv --python python${PYTHON_VERSION} "${VIRTUAL_ENV}"
ENV PATH="${VIRTUAL_ENV}/bin:${PATH}"

WORKDIR /opt/tomocupy
COPY pyproject.toml VERSION README.rst LICENSE CMakeLists.txt ./
COPY src/ ./src/

RUN uv pip install --python "${VIRTUAL_ENV}/bin/python" \
        "${CUPY_PACKAGE}" \
        . \
    && find "${VIRTUAL_ENV}" -name '__pycache__' -type d -prune -exec rm -rf {} +


# ---------- runtime stage ----------
FROM docker.io/nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS runtime

ARG PYTHON_VERSION

ENV DEBIAN_FRONTEND=noninteractive \
    VIRTUAL_ENV=/opt/venv \
    PATH=/opt/venv/bin:/usr/local/bin:/usr/bin:/bin \
    PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update && apt-get install -y --no-install-recommends \
        python${PYTHON_VERSION} \
        libgl1 \
        libglib2.0-0 \
        libgomp1 \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python3 \
    && ln -sf /usr/bin/python${PYTHON_VERSION} /usr/local/bin/python \
    && apt-get purge -y software-properties-common \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/venv /opt/venv

# cupy >= 12.2 needs CUDA Runtime headers at runtime for NVRTC JIT
# compilation. The -runtime CUDA base image strips them; ship NVIDIA's
# headers-only wheel (~70 MB) so cp.ones(1) and other ElementwiseKernel
# calls don't fail. Ref: https://docs.cupy.dev/en/stable/install.html#faq
COPY --from=ghcr.io/astral-sh/uv:latest /uv /usr/local/bin/uv
RUN /usr/local/bin/uv pip install --python /opt/venv/bin/python --no-cache \
        "nvidia-cuda-runtime-cu12==12.4.*" \
    && rm -f /usr/local/bin/uv \
    && find /opt/venv -name '__pycache__' -type d -prune -exec rm -rf {} +

WORKDIR /data

ENTRYPOINT ["tomocupy"]
CMD ["--help"]
