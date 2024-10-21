FROM oraclelinux:8

RUN dnf install -y \
        wget \
        unzip \
        git \
        libX11

WORKDIR /ecephys-install
RUN wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh"

# This container is also used as a builder for other ecephys tools containers 
# therefore we don't remove anything from ecephys-install
RUN bash Miniforge3.sh -b -p /miniforge

COPY conda-requirements.yml /ecephys-install/

ENV PATH=/miniforge/bin:${PATH}
# ENV LD_LIBRARY_PATH=/miniforge/lib:${LD_LIBRARY_PATH}

WORKDIR /app/ecephys_spike_sorting

# using >= 3.9 because creating the json config uses dictionary union operator ('|'')
RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.10 && \
    conda env update -n base -f /ecephys-install/conda-requirements.yml

COPY ecephys_spike_sorting /ecephys-install/ecephys_spike_sorting/
COPY ecephys_spike_sorting /app/ecephys_spike_sorting/ecephys_spike_sorting/
COPY scripts /ecephys-install/scripts
COPY scripts /app/scripts
COPY default_ecephys_config.json /app/config/default_ecephys_config.json

RUN chmod 555 /app/scripts/*.sh

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
