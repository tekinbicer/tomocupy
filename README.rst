========
Tomocupy
========

**Tomocupy** is a Python package and a command-line interface for GPU reconstruction of tomographic/laminographic data in 16-bit and 32-bit precision. All preprocessing operations are implemented on GPU with using CuPy library, the backprojection operation is implemented with CUDA C.
The current implementation works with h5 data files having the following structure::

/exchange/data
/exchange/data_white
/exchange/data_dark
/exchange/theta

For other files structures, please adjust src/reader.py. For reconstruction working with numpy arrays see https://github.com/nikitinvv/tomocupy-stream with a jupyter notebook example in tests/test_for_compression.ipynb.

**Tomocupy**  documentation is available `here <https://tomocupy.readthedocs.io/en/latest/>`_.

Docker
======

A ``Dockerfile`` is provided to build a CUDA-enabled image with **tomocupy**
installed as the container entrypoint. Running the image requires the
`NVIDIA Container Toolkit <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html>`_
on the host and an NVIDIA GPU with a driver compatible with the CUDA version
used at build time (CUDA 12.4 by default).

Build
-----

From the repository root::

    docker build -t tomocupy:latest .

The build is parametrized via ``--build-arg``. The defaults are::

    CUDA_VERSION=12.4.1
    UBUNTU_VERSION=22.04
    PYTHON_VERSION=3.11
    CUPY_PACKAGE=cupy-cuda12x

For example, to build against CUDA 11.8 with the matching CuPy wheel::

    docker build \
        --build-arg CUDA_VERSION=11.8.0 \
        --build-arg CUPY_PACKAGE=cupy-cuda11x \
        -t tomocupy:cuda11.8 .

Run
---

The image's entrypoint is the ``tomocupy`` command and its working directory
is ``/input``. Mount the directory that contains your ``.h5`` files into
``/input`` and pass any ``tomocupy`` arguments after the image name.

Show the CLI help::

    docker run --rm --gpus all tomocupy:latest --help

Reconstruct a dataset (full reconstruction with FBP, for example)::

    docker run --rm --gpus all \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -v /path/to/host/input:/input \
        -v /path/to/host/output:/output \
        tomocupy:latest recon \
        --file-name /input/sample.h5  \
        --out-path-name /output/rec \
        --reconstruction-type full \
        --rotation-axis-auto auto \
        --save-format tiff

Select a specific GPU and limit shared memory if needed::

    docker run --rm --gpus '"device=0"' --shm-size=8g \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -v /path/to/host/input:/input \
        -v /path/to/host/output:/output \
        tomocupy:latest recon_steps \
        --file-name /input/sample.h5  \
        --out-path-name /output/rec \
        --reconstruction-type full \
        --rotation-axis-auto auto \
        --save-format tiff

Reconstructed output is written next to the input file by default, so it will
appear under ``/path/to/host/output`` on the host through the bind mount.

To get an interactive shell inside the image (for debugging or running other
subcommands), override the entrypoint::

    docker run --rm -it --gpus all \
        --user "$(id -u):$(id -g)" \
        -e HOME=/tmp \
        -v /path/to/host/input:/input \
        -v /path/to/host/output:/output \
        --entrypoint bash tomocupy:latest

