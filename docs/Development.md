# Development

### Building containers

All containers used by the pipeline have been made available on the Janelia's internal docker registry, but all docker recipes used for building these containers have been made available.

### Matlab container

Kilosort step requires a full licensed matlab installation so in order to build the container for kilosort you will need first the full matlab container. To build a full matlab container
image you can follow the instructions from Mathworks presented [here](https://github.com/mathworks-ref-arch/matlab-dockerfile).
Mathworks' instructions are for building a docker image based on ubuntu:18 but we used a Oracle Linux 8 based installation that can be found in the `containers/matlab-oraclelinux8` subfolder. Once you download the full matlab following the Mathworks instructions and prepared `containers/matlab-oraclelinux8/matlab_installer_input.txt` you can run:
```
docker build \
    -t matlab-oraclelinux8:2020b \
    -t registry.int.janelia.org/ecephys/matlab-oraclelinux8:2020b \
    --build-arg LICENSE_SERVER=27000@vm7142.int.janelia.org \
    containers/matlab-dockerfile-oraclelinux8
```

### Kilosort container
This is the container used for running Kilosort module and it requires a Matlab license to run it
```
docker build \
    -t registry.int.janelia.org/ecephys/kilosort:1.0 \
    -t kilosort:1.0 \
    containers/kilosort
```

As a side note if you need to run the pipeline with docker,  because kilosort requires GPU for processing, you will have to install nvidia container runtime as described 
[here](https://github.com/NVIDIA/nvidia-container-runtime). 

### CatGT container
This is used for running CatGT module and it contains the CatGT tool developed by Bill Kharsh available [here](https://billkarsh.github.io/SpikeGLX/)

```
docker build \
    -t registry.int.janelia.org/ecephys/catgt:1.0 \
    -t catgt:1.0 \
    containers/catgt
```

### C_Waves container
This is used for running mean waveforms module and it contains the C_Wave tool developed by Bill Kharsh available [here](https://billkarsh.github.io/SpikeGLX/)
```
docker build \
    -t registry.int.janelia.org/ecephys/cwaves:1.0 \
    -t cwaves:1.0 \
    containers/cwaves
```

### TPrime container
This is used for running TPrime module and it contains the TPrime tool developed by Bill Kharsh available [here](https://billkarsh.github.io/SpikeGLX/)
```
docker build \
    -t registry.int.janelia.org/ecephys/tprime:1.0 \
    -t tprime:1.0 \
    containers/tprime
```

### Ecephys-modules container
This is a generic container that contains all Ecephys modules but no other non-python based tools
```
docker build \
    -t registry.int.janelia.org/ecephys/ecephys-modules:1.0 \
    -t ecephys-modules:1.0 \
    containers/ecephys-modules
```