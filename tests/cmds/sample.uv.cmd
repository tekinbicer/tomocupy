
# Create an empty uv .venv (tbicer@arecibo)
$ uv venv .venv

# load the uv environment (tbicer@arecibo)
$ . .venv/bin/activate

# install tomocupy via uv (tbicer@arecibo)
$ (.venv) [14:00 tbicer@arecibo tomocupy]$ CUDA_HOME=/usr/local/cuda \
> PATH=/usr/local/cuda/bin:$PATH \
> LD_LIBRARY_PATH=/usr/local/cuda/lib64:$LD_LIBRARY_PATH \
> CMAKE_ARGS="-DCMAKE_CUDA_ARCHITECTURES=86" \
> uv pip install "cupy-cuda12x" .

# load the .venv on tomo3 and then run recon (tbicer@tomo3)
(.venv) $ tomocupy recon --file-path ... # run recon directly
