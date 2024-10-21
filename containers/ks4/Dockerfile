ARG ECEPHYS_VERSION
FROM registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION} as builder

WORKDIR /tmp
RUN mkdir ks4 && \
    cd ks4 && \
    git clone https://github.com/jenniferColonell/KS4.git . && \
    git checkout -b ks4-latest

FROM oraclelinux:8

USER root

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

RUN dnf update -y && \
    dnf install -y dnf-utils

RUN dnf -y install --nogpgcheck \
        https://download.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm \
        https://download1.rpmfusion.org/free/el/rpmfusion-free-release-8.noarch.rpm \
        https://download1.rpmfusion.org/nonfree/el/rpmfusion-nonfree-release-8.noarch.rpm

RUN dnf install -y \
    git \
    mesa-libGL

WORKDIR /tmp-install

COPY --from=builder /ecephys-install/Miniforge3.sh .
COPY --from=builder /ecephys-install/conda-requirements.yml .

RUN bash Miniforge3.sh -b -p /miniforge && \
    rm Miniforge3.sh

ENV PATH=/miniforge/bin:${PATH}

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.9
    
RUN conda env update -n base -f conda-requirements.yml && \
    rm -f conda-requirements.yml

WORKDIR /app
COPY --from=builder /tmp/ks4 Kilosort

RUN cd /app/ks4 && \
    conda activate base && \
    python -m pip install kilosort \
    conda install pytorch pytorch-cuda=11.8 -c pytorch -c nvidia \
    pip install -e . && \


WORKDIR /app/ecephys_spike_sorting
COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
