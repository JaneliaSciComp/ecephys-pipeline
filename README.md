# Extracellular Electrophysiology Pipeline
![ecephys_spike_sorting_icon](icon.png)

This is a [nextflow](https://www.nextflow.io) pipeline for 
processing **e**xtra**c**ellular **e**lectro**phys**iology data 
from Neuropixels probes.

The [code](https://github.com/AllenInstitute/ecephys_spike_sorting) was originally developed 
at the Allen Institute for Brain Science and it includes 
[additions](https://github.com/jenniferColonell/ecephys_spike_sorting)
made by Jennifer Colonell for running with SpikeGLX data, 
including integration of CatGT (preprocessing) and 
TPrime (synchronization across data streams)

## Overview

For an overview of the processing pipeline please check the original 
github repos from [Allen Institute](https://github.com/AllenInstitute/ecephys_spike_sorting) 
and [Jennifer Colonell](https://github.com/jenniferColonell/ecephys_spike_sorting). Here we will
focus mostly on the nextflow pipeline implementation. 

In order to run the pipeline you must first create a Docker container
which must contain a full matlab installation. The reason for needing
a full matlab installation is because kilosort currently requires matlab python
engine so it cannot be precompiled into an executable. To build a full matlab container
image you can follow the instructions from Mathworks presented [here](https://github.com/mathworks-ref-arch/matlab-dockerfile).
Mathworks' instructions are for building a docker image based on ubuntu:18 but if
you prefer Centos 8 distribution we have a docker recipe based on Centos 8 in the
matlab-dockerfile-centos8 folder.
Once you download the full matlab and prepared matlab_installer_input.txt, create the matlab container followed by
creating the ecephys container:
```
cd matlab-dockerfile-centos8
docker build -t registry.int.janelia.org/janeliascicomp/matlab-centos8:2020b --build-arg LICENSE_SERVER=27000@e05u04.int.janelia.org .
cd ..
docker build -t registry.int.janelia.org/janeliascicomp/ecephys:1.0 .
```

## Usage

You must have [Nextflow](https://www.nextflow.io) and 
[Docker](https://www.docker.com/products/container-runtime) or 
[Singularity](https://sylabs.io) installed before running the pipeline.

Also because kilosort2 requires a GPU, if you run the pipeline using docker,
make sure you install nvidia container runtime as described 
[here](https://github.com/NVIDIA/nvidia-container-runtime). With singularity
this is not necessary because singularity provides access to the GPU,
if one exists, using the '--nv' flag.

### Local execution
##### With Docker
```
pipeline/pipeline.nf \
    -config pipeline/nextflow.config \
    -profile localdocker \
    --runtime_opts "-u $(id -u):$(id -g) --runtime=nvidia" \
    --in /path/to/probes --config /path/to/configs --out /path/to/outputs
```

##### With Singularity
```
pipeline/pipeline.nf \
    -config pipeline/nextflow.config \
    -profile localsingularity \
    --in /path/to/probes --config /path/to/configs --out /path/to/outputs
```

### LSF execution on Janelia cluster
```
pipeline/pipeline.nf \
    -config pipeline/nextflowl.config \
    -profile lsf \
    -with-tower 'http://nextflow.int.janelia.org/api' \
    --in /path/to/probes --config /path/to/step-configs --out /path/to/outputs
```
This also uses the internal Janelia instance of Nextflow Tower.
