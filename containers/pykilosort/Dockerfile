FROM registry.int.janelia.org/janeliascicomp/ecephys-modules:1.0.2 as builder

WORKDIR /tmp
RUN git clone \
    https://github.com/int-brain-lab/pykilosort.git \
    --branch ibl_prod \
    --single-branch \
    pykilosort

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

COPY --from=builder /ecephys-install/miniconda-install.sh .
COPY --from=builder /ecephys-install/conda-requirements.yml .

RUN bash miniconda-install.sh -b -p /miniconda && \
    rm miniconda-install.sh

ENV PATH=/miniconda/bin:${PATH}

RUN conda config --set always_yes yes && \
    conda update -q conda && \
    conda install python=3.9

RUN conda env update -n base -f conda-requirements.yml && \
    rm -f conda-requirements.yml

WORKDIR /app
COPY --from=builder /tmp/pykilosort pykilosort

RUN cd /app/pykilosort && \
    conda env update -n base -f pyks2.yml && \
    . /miniconda/etc/profile.d/conda.sh && \
    conda activate base && \
    pip install -e . && \
    pip install cython && \
    conda install -c conda-forge pyfftw && \
    pip install git+https://github.com/int-brain-lab/ibllib.git && \
    pip install -U phylib

WORKDIR /app/ecephys_spike_sorting
COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}
