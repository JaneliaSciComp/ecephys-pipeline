ARG ECEPHYS_VERSION
FROM registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION} as builder

WORKDIR /tmp
RUN mkdir ks4 && \
    cd ks4 && \
    git clone https://github.com/jenniferColonell/KS4.git --branch main . && \
    git checkout -b ks4-latest

FROM nvidia/cuda:12.0.0-base-ubuntu20.04

USER root

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

RUN apt-get update -y && \
    apt-get install -y \
        git \
        libx11-dev


WORKDIR /tmp-install

COPY --from=builder /ecephys-install/Miniforge3.sh .
COPY --from=builder /ecephys-install/conda-requirements.yml .

RUN bash Miniforge3.sh -b -p /miniforge && \
    rm Miniforge3.sh

ENV PATH=/miniforge/bin:${PATH}

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.10
    
RUN conda env update -n base -f conda-requirements.yml && \
    rm -f conda-requirements.yml

WORKDIR /app
COPY --from=builder /tmp/ks4 ks4

RUN cd /app/ks4 && \
    ls && \
    conda env update -n base -f environment_docker.yml && \
    . /miniforge/etc/profile.d/conda.sh && \
    conda activate base && \       
    pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118 && \
    pip install -e .


WORKDIR /app/ecephys_spike_sorting
COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
