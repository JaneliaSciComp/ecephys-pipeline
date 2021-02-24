FROM centos:8

RUN dnf install -y \
        wget \
        unzip \
        git

WORKDIR /ecephys-install
RUN wget https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh \
    -O miniconda-install.sh
ADD conda-requirements.yml .

COPY ecephys_spike_sorting ecephys_spike_sorting
