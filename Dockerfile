FROM  matlab-centos8:2020b

USER root

RUN dnf config-manager -y --add-repo http://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-rhel8.repo

RUN dnf install -y \
        git \
        wget

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

WORKDIR /tmp
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O miniconda-install.sh
RUN bash miniconda-install.sh -b -p /miniconda

RUN rm miniconda-install.sh
ADD conda-requirements.txt /tmp
ADD pip-requirements.txt /tmp
ENV PATH=/miniconda/bin:${PATH}

RUN conda config --set always_yes yes
RUN conda update -q conda && \
    conda install python=3.8 && \
    conda install --file conda-requirements.txt && \
    pip install -r pip-requirements.txt

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

ADD ecephys_spike_sorting /app/ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}

WORKDIR /app/ecephys_spike_sorting
