ARG CUDA_VERSION=12.4.1
ARG UBUNTU_VERSION=22.04
ARG PYTHON_VERSION=3.11
ARG CUPY_PACKAGE=cupy-cuda12x

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${UBUNTU_VERSION} AS builder

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
        "${CUPY_PACKAGE}[ctk]" \
        . \
    && find "${VIRTUAL_ENV}" -name '__pycache__' -type d -prune -exec rm -rf {} +


FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${UBUNTU_VERSION} AS runtime

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

WORKDIR /data

ENTRYPOINT ["tomocupy"]
CMD ["--help"]
