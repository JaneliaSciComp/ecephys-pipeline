FROM registry.int.janelia.org/janeliascicomp/ecephys-modules:1.0.4 as builder

WORKDIR /tmp
RUN mkdir kilosort-1.0 && \
    cd kilosort-1.0 && \
    git clone https://github.com/cortex-lab/KiloSort.git . && \
    cd ..

# Checkout the modified version of kilosort2
RUN mkdir kilosort-2.0 && \
    cd kilosort-2.0 && \
    git clone https://github.com/jenniferColonell/KS20_for_preprocessed_data.git . && \
    cd ..

# Checkout tag 2.5 from Kilosort2 repo
RUN mkdir kilosort-2.5 && \
    cd kilosort-2.5 && \
    git clone https://github.com/jenniferColonell/Kilosort2.git . && \
    git checkout -b 2.5 c31df11 && \
    cd ..

RUN mkdir kilosort-3.0 && \
    cd kilosort-3.0 && \
    git clone https://github.com/jenniferColonell/Kilosort2.git . && \
    cd ..

RUN git clone https://github.com/kwikteam/npy-matlab.git npy-matlab

FROM registry.int.janelia.org/janeliascicomp/matlab-oraclelinux8:2020b

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
COPY --from=builder /tmp/kilosort-1.0 kilosort-1.0
COPY --from=builder /tmp/kilosort-2.0 kilosort-2.0
COPY --from=builder /tmp/kilosort-2.5 kilosort-2.5
COPY --from=builder /tmp/kilosort-3.0 kilosort-3.0
COPY --from=builder /tmp/npy-matlab npy-matlab

RUN cd /app/kilosort-1.0/CUDA && \
    matlab -sd . -batch mexGPUall && \
    cd /app/kilosort-2.0/CUDA && \
    matlab -sd . -batch mexGPUall && \
    cd /app/kilosort-2.5/CUDA && \
    matlab -sd . -batch mexGPUall && \
    cd /app/kilosort-3.0/CUDA && \
    matlab -sd . -batch mexGPUall

WORKDIR /app/ecephys_spike_sorting
COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
