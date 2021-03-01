FROM centos:8

RUN dnf install -y \
        wget \
        unzip \
        git \
        libX11

WORKDIR /ecephys-install
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O miniconda-install.sh
ADD conda-requirements.yml .

COPY ecephys_spike_sorting ecephys_spike_sorting

# This container is also used as a builder for other ecephys tools containers 
# therefore we don't remove anything from ecephys-install
RUN bash miniconda-install.sh -b -p /miniconda

ENV PATH=/miniconda/bin:${PATH}

WORKDIR /app/ecephys_spike_sorting

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.8 && \
    conda env update -n base -f /ecephys-install/conda-requirements.yml && \
    cp -a /ecephys-install/ecephys_spike_sorting .

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
