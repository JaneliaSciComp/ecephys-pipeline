ARG ECEPHYS_VERSION
FROM registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION} as builder

WORKDIR /tmp
# RUN mkdir kilosort-1.0 && \
#    cd kilosort-1.0 && \
#    git clone https://github.com/cortex-lab/KiloSort.git . && \
#    git checkout -b 1.0 cd040da && \
#    cd ..

# Checkout the modified version of kilosort2
RUN mkdir kilosort-2.0 && \
    cd kilosort-2.0 && \
    git clone https://github.com/jenniferColonell/KS20_for_preprocessed_data.git . && \
    git checkout -b 2.0 fb27020 && \
    cd ..

# Checkout tag 2.5 from Kilosort2 repo
RUN mkdir kilosort-2.5 && \
    cd kilosort-2.5 && \
    git clone https://github.com/jenniferColonell/KS2.5.2_seed . && \
    git checkout -b 2.5 5d4ef1b && \
    cd ..

# RUN mkdir kilosort-3.0 && \
#    cd kilosort-3.0 && \
#    git clone https://github.com/jenniferColonell/Kilosort2.git . && \
#    git checkout -b 3.0 f16dda7 && \
#    cd ..

RUN git clone https://github.com/kwikteam/npy-matlab.git npy-matlab

FROM janeliascicomp/matlab-oraclelinux8:2022 

USER root

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=all
ARG LICENSE_SERVER
ENV MLM_LICENSE_FILE=${LICENSE_SERVER}

WORKDIR /tmp-install

COPY --from=builder /ecephys-install/Miniforge3.sh .
COPY --from=builder /ecephys-install/conda-requirements.yml .

RUN bash Miniforge3.sh -b -p /miniforge && \
    rm Miniforge3.sh

ENV PATH=/miniforge/bin:${PATH}
ENV LD_LIBRARY_PATH=/miniforge/lib:${LD_LIBRARY_PATH}

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.10

RUN conda env update -n base -f conda-requirements.yml && \
    rm -f conda-requirements.yml

WORKDIR /usr/local/MATLAB/extern/engines/python
RUN python setup.py install

WORKDIR /app
# COPY --from=builder /tmp/kilosort-1.0 kilosort-1.0
COPY --from=builder /tmp/kilosort-2.0 kilosort-2.0
COPY --from=builder /tmp/kilosort-2.5 kilosort-2.5
# COPY --from=builder /tmp/kilosort-3.0 kilosort-3.0
COPY --from=builder /tmp/npy-matlab npy-matlab

RUN cd /app/kilosort-2.0/CUDA && \
    matlab -sd . -batch mexGPUall && \
    cd /app/kilosort-2.5/CUDA && \
    matlab -sd . -batch mexGPUall 

# for adding KS1
#   cd /app/kilosort-1.0/CUDA && \
#   matlab -sd . -batch mexGPUall && \    

#    cd /app/kilosort-3.0/CUDA && \
#    matlab -sd . -batch mexGPUall

WORKDIR /app/ecephys_spike_sorting
COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
ENV LD_PRELOAD=/miniforge/lib/libstdc++.so.6
ENV MLM_LICENSE_FILE=
