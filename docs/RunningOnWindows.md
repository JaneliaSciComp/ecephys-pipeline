# Running on Windows

Runing the pipeline on Linux and on MAC is pretty straight forward given that installing and running nextflow on these platforms is very simple. However on Windows things are slightly more complicated mainly because Windows support for nextflow is done through Windows Subsystem for Linux (WSL). We should also mention that on MAC not all modules are supported because of the CUDA requirement, so kilosort 2 or 3 cannot run on MAC.

## Windows Setup

As we already mentioned Nextflow runs on Windows under WSL. Moreover because the pipeline uses docker containers it will actually only run on a system that supports WSL 2. Instructions for setting up WSL 2 can be found [here](https://docs.microsoft.com/en-us/windows/wsl/install-win10). 

Next step is to install docker and Docker Desktop for windows. The procedure and the requirements for Docker Desktop are described at [Docker's site](https://docs.docker.com/docker-for-windows/install/) and at [Microsoft's site](https://docs.microsoft.com/en-us/windows/wsl/tutorials/wsl-containers)

Setting up and configuring CUDA, needed for kilosort module, requires the most technical knowledge, because at the time of writing this, it is only possible by [registering with the Windows Insider Program](https://insider.windows.com/getting-started/#register) and by signing up with the [Nvidia Developer Program](https://developer.nvidia.com/developer-program) in order to have access to the CUDA WSL2 drivers. [Microsoft's site](https://docs.microsoft.com/en-us/windows/win32/direct3d12/gpu-cuda-in-wsl) has detailed instructions for [enabling CUDA in WSL2](https://docs.microsoft.com/en-us/windows/win32/direct3d12/gpu-cuda-in-wsl) with references to NVIDIA's [CUDA on WSL User Guide](https://docs.nvidia.com/cuda/wsl-user-guide/index.html).

Even though singularity can be installed and configured under WSL easily, running the pipeline using singularity it's not possible under WSL. This is because singularity gives access to the GPU drivers using `--nv` flag which exposes GPU `/dev/` device and this is not possible on a virtualized OS. Singularity will have to change to use something like NVIDIA vGPU at the hypervisor level.


## Running on Windows.

Once the Windows setup is completed it's easy to create a script similar to the one below to run the pipeline:
```
#!/usr/bin/env bash


DATA_DIR=/mnt/c/ecephys/testData/SC_10trial
OUTPUT_DIR=/mnt/c/ecephys/testResults/SC_10trial
CONFIG_DIR=${OUTPUT_DIR}/config
RESULTS_DIR=${OUTPUT_DIR}/results
RUNS_SPECS_FILE=examples/runs.json
KS_TH_BY_REGION_FILE=examples/ks3ThByRegion.json
REF_MS_BY_REGION_FILE=examples/refmsByRegion.json
RUNTIME_OPTS="--gpus=all -v ${DATA_DIR}:${DATA_DIR} -v $PWD:$PWD"
PROFILE_ARG="-profile localdocker"

nextflow run main.nf \
    ${PROFILE_ARG} \
    --runtime_opts "${RUNTIME_OPTS}" \
    --runs ${RUNS_SPECS_FILE} \
    --ks_thresholds_by_region ${KS_TH_BY_REGION_FILE} \
    --ref_per_ms_by_region ${REF_MS_BY_REGION_FILE} \
    --data_dir ${DATA_DIR} \
    --config_dir ${CONFIG_DIR} \
    --results_dir ${RESULTS_DIR}

```

If you create this script on windows you will have to run it through a tool such as `dos2unix` to convert EOL delimiters from <CR><LF> to <LF>
