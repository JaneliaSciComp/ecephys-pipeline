FROM registry.int.janelia.org/janeliascicomp/ecephys-modules:1.0.0 as builder

WORKDIR /tmp

ENV TOOL_DOWNLOAD_URL=https://billkarsh.github.io/SpikeGLX/Support/CatGTLnxApp.zip
RUN wget ${TOOL_DOWNLOAD_URL} -O tool.zip

RUN unzip tool.zip

FROM ubuntu:16.04

RUN apt-get update -y && \
    apt-get install -y \
        libx11-dev

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

WORKDIR /app/ecephys_spike_sorting

COPY --from=builder /ecephys-install/ecephys_spike_sorting ecephys_spike_sorting

ENV PYTHONPATH=/app/ecephys_spike_sorting:${PYTHONPATH}

WORKDIR /app

COPY --from=builder /tmp/CatGT-linux /app/CatGT

WORKDIR /app/CatGT

RUN chmod 555 *.sh && \
    chmod 555 CatGT && \
    ./install.sh
