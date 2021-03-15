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
docker build \
    -t matlab-centos8:2020b \
    -t registry.int.janelia.org/janeliascicomp/matlab-centos8:2020b \
    --build-arg LICENSE_SERVER=27000@e05u04.int.janelia.org \
    containers/matlab-dockerfile-centos8

docker build \
    -t registry.int.janelia.org/janeliascicomp/ecephys-modules:1.0 \
    -t ecephys-modules:1.0 \
    containers/ecephys-modules

docker build \
    -t registry.int.janelia.org/janeliascicomp/catgt:1.0 \
    -t catgt:1.0 \
    containers/catgt

docker build \
    -t registry.int.janelia.org/janeliascicomp/cwaves:1.0 \
    -t cwaves:1.0 \
    containers/cwaves

docker build \
    -t registry.int.janelia.org/janeliascicomp/tprime:1.0 \
    -t tprime:1.0 \
    containers/tprime

docker build \
    -t registry.int.janelia.org/janeliascicomp/kilosort:1.0 \
    -t kilosort:1.0 \
    containers/kilosort

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
./main.nf \
    -profile localdocker \
    --runs examples/runs.json \
    --ref_per_ms_by_region examples/refmsByRegion.json \
    --data_dir /parentOf/runFolder \
    --config_dir /output/configsDir \
    --results_dir /output/resultsDir \
    --ks_working_dir /tmp/ks_tmp \
    --has_aux_data true
```

##### With Singularity
```
./main.nf \
    --runs examples/runs.json \
    --ref_per_ms_by_region examples/refmsByRegion.json \
    --data_dir /parentOf/runFolder \
    --config_dir /output/configsDir \
    --results_dir /output/resultsDir \
    --ks_working_dir /tmp/ks_tmp \
    --has_aux_data true
```

### LSF execution on Janelia cluster
```
./main.nf \
    -profile lsf \
    --runs examples/runs.json \
    --ref_per_ms_by_region examples/refmsByRegion.json \
    --data_dir /parentOf/runFolder \
    --config_dir /output/configsDir \
    --results_dir /output/resultsDir \
    --ks_working_dir /tmp/ks_tmp \
    --has_aux_data true
```
This also uses the internal Janelia instance of Nextflow Tower.
