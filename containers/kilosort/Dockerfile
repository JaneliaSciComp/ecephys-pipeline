FROM registry.int.janelia.org/janeliascicomp/matlab-centos8:2020b

USER root

RUN dnf install -y \
        git \
        wget

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

WORKDIR /tmp-install
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O miniconda-install.sh
RUN bash miniconda-install.sh -b -p /miniconda && \
    rm miniconda-install.sh

ADD conda-requirements.yml /tmp-install
ENV PATH=/miniconda/bin:${PATH}

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.8

RUN conda env update -n base -f conda-requirements.yml && \
    rm -f conda-requirements.yml

WORKDIR /usr/local/MATLAB/extern/engines/python
RUN python setup.py install

WORKDIR /app/kilosort
RUN git clone https://github.com/cortex-lab/KiloSort.git .
RUN cd /app/kilosort/CUDA && \
    matlab -sd . -batch mexGPUall

WORKDIR /app/kilosort2
RUN git clone https://github.com/MouseLand/Kilosort.git .
RUN cd /app/kilosort2/CUDA && \
    matlab -sd . -batch mexGPUall

WORKDIR /app/npy-matlab
RUN git clone https://github.com/kwikteam/npy-matlab.git .

WORKDIR /app/ecephys_spike_sorting
COPY ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
