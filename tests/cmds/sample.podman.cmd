# Building image from container file
podman build --no-cache --pull=always -f Containerfile -t localhost/tomocupy:v1.1 .

# Running container from built image
podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable \
           -v /home/tbicer/projects/tests/data:/data:Z localhost/tomocupy:v1.1 \ 
           recon --file-name /data/sand1_pink30keV_exp0p02_ang2400_dist120mm_312.h5 \
           --nsino-per-chunk 4 --reconstruction-type full --center-search-width 100
