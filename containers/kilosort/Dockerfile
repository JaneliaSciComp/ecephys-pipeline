FROM registry.int.janelia.org/janeliascicomp/ecephys-modules:1.0 as builder

WORKDIR /tmp
RUN git clone https://github.com/cortex-lab/KiloSort.git kilosort1
RUN git clone https://github.com/MouseLand/Kilosort.git kilosort2
RUN git clone https://github.com/kwikteam/npy-matlab.git npy-matlab

FROM registry.int.janelia.org/janeliascicomp/matlab-centos8:2020b

USER root

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all

WORKDIR /tmp-install

COPY --from=builder /ecephys-install/miniconda-install.sh .
COPY --from=builder /ecephys-install/conda-requirements.yml .

RUN bash miniconda-install.sh -b -p /miniconda && \
    rm miniconda-install.sh

ENV PATH=/miniconda/bin:${PATH}

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.8

RUN conda env update -n base -f conda-requirements.yml && \
    rm -f conda-requirements.yml

WORKDIR /usr/local/MATLAB/extern/engines/python
RUN python setup.py install

WORKDIR /app
COPY --from=builder /tmp/kilosort1 kilosort
COPY --from=builder /tmp/kilosort2 kilosort2
COPY --from=builder /tmp/npy-matlab npy-matlab

RUN cd /app/kilosort/CUDA && \
    matlab -sd . -batch mexGPUall && \
    cd /app/kilosort2/CUDA && \
    matlab -sd . -batch mexGPUall

WORKDIR /app/ecephys_spike_sorting
COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
