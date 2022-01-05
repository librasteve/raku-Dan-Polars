FROM --platform=linux/arm64 jupyter/scipy-notebook 

USER root
RUN buildDeps="cmake \
         libc6-dev \
         libencode-perl \
         libzstd-dev \
         libssl-dev \
         python3-wheel \
         librust-libz-sys+default-dev" \
    && apt-get update && apt-get upgrade -y \
    && apt-get install -y --no-install-recommends build-essential $buildDeps \
    && rm -rf /var/lib/apt/lists/* 

USER jovyan
RUN wget https://static.rust-lang.org/rustup/dist/aarch64-unknown-linux-gnu/rustup-init \
    && chmod +x rustup-init && ./rustup-init -y && source $HOME/.cargo/env
    #&& conda create -n myenv python=3.8 -y && conda activate myenv \
    #&& pip install maturin
    #&& pip install polars


ENTRYPOINT ["/bin/bash"]

