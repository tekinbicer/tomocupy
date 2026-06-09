============
Containers
============

Tomocupy ships a multi-stage ``Dockerfile`` and an ``apptainer.def`` for
running on workstations and HPC systems without installing CUDA, ``cupy``,
SWIG, CMake, or any Python dependencies on the host. Only a recent NVIDIA
driver is required.

The default images target **CUDA 12.4**, **Python 3.11**, and
``cupy-cuda12x``. The host driver must be NVIDIA driver ``>=550``.

Docker
======

Prerequisites
-------------

* NVIDIA driver ``>=550``
* Docker ``>=19.03``
* `NVIDIA Container Toolkit
  <https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html>`_

Build
-----

::

    $ git clone https://github.com/tomography/tomocupy
    $ cd tomocupy
    $ docker build -t tomocupy:1.1.0-cu124 .

Build with a different CUDA version or Python version
-----------------------------------------------------

::

    $ docker build \
        --build-arg CUDA_VERSION=11.8.0 \
        --build-arg CUPY_PACKAGE=cupy-cuda11x \
        --build-arg PYTHON_VERSION=3.10 \
        -t tomocupy:1.1.0-cu118 .

Run
---

::

    $ docker run --rm --gpus all tomocupy:1.1.0-cu124 recon -h

    $ docker run --rm --gpus all \
        -v /path/to/data:/data \
        tomocupy:1.1.0-cu124 \
        recon --file-name /data/sample.h5 --reconstruction-type full

The container's working directory is ``/data``; bind-mount your dataset
there. The ``ENTRYPOINT`` is the ``tomocupy`` CLI, so any arguments you pass
to ``docker run`` are forwarded to it.

Apptainer / Singularity (HPC)
=============================

Most HPC sites disallow Docker. ``apptainer.def`` builds the same image for
Apptainer (formerly Singularity).

Build
-----

::

    $ apptainer build tomocupy.sif apptainer.def

If your site forbids ``--fakeroot`` builds, build the image on a workstation
and copy the resulting ``tomocupy.sif`` to the cluster.

Alternatively, convert the Docker image directly::

    $ apptainer build tomocupy.sif docker-daemon://tomocupy:1.1.0-cu124

Run
---

The ``--nv`` flag exposes the host's NVIDIA driver to the container.

::

    $ apptainer run --nv tomocupy.sif recon -h

    $ apptainer run --nv \
        -B /scratch/data:/data \
        tomocupy.sif \
        recon --file-name /data/sample.h5 --reconstruction-type full

Notes
=====

* The Dockerfile uses a multi-stage build: the ``-devel`` CUDA image
  compiles the SWIG/CUDA extensions, then only the resulting virtualenv is
  copied into a slim ``-runtime`` image. Final image size is roughly 4-5 GB.
* ``cupy`` is intentionally not declared in ``pyproject.toml`` because the
  correct wheel depends on the CUDA version. The Dockerfile installs it via
  the ``CUPY_PACKAGE`` build argument.
* Compiled extensions (``src/tomocupy/_cfunc_*.so`` and SWIG-generated
  ``cfunc_*.py``) in the source tree are excluded by ``.dockerignore`` so
  the build always produces fresh artifacts.
* The ``beamhardening`` package is **not** installed by default because it
  is not published on PyPI and is only loaded when ``--beam-hardening-method``
  is enabled. To use beam hardening correction, install it from source
  inside the container or rebuild the image with an extra
  ``RUN pip install <source-or-url>`` step.
