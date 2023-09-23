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

## Quick Start

The only software requirements for running this pipeline are:

*Java
*[Nextflow](https://www.nextflow.io) (version 20.10.0 or greater)
*[Singularity](https://sylabs.io) (version 3.5 or greater) or [apptainer](https://apptainer.org/docs/admin/main/installation.html) (version 1.1.9 or greater). 

If you are running in an HPC cluster, ask your system administrator to install Singularity on all the cluster nodes.


To [install Nextflow](https://www.nextflow.io/docs/latest/getstarted.html):

```
    curl -s https://get.nextflow.io | bash 
```
Then add the next install directory to your PATH environment variable.

To [install Singularity](https://sylabs.io/guides/3.7/admin-guide/installation.html) on Oracle Linux:

```
    sudo yum install singularity
```

When installing in Ubuntu, use apt:

Java install (for example, on a newly build workstation):
```
    sudo apt openjdk-17-jre-headless
```
Nextflow install:
```
    curl -s https://get.nextflow.io | bash 
```
Follow the instructions to install apptainer for Ubuntu [here](https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages).

Install docker:
```
    sudo apt install docker.io
```

Clone the ecephys-pipeline repository:
```
    git clone https://github.com/JaneliaSciComp/ecephys-pipeline.git
```

The pipeline reads the runs specs from a JSON file so before running the pipeline you may have to create the runs spec JSON file that looks like this:
```
[
    {
        "name": "SC024_092319_NP1.0_Midbrain",
        "gateIndex": "0",
        "triggers": "start,end",
        "probes": "0,1",
        "regions": [ "cortex", "medulla"]
    }
]
```

You can now launch the pipeline using:
```
    ./main.nf [arguments]
```

## Pipeline Overview

This pipeline is containerized and portable across the various platforms supported by [Nextflow](https://www.nextflow.io). So far it has been tested on standalone Linux workstations running Oracle Ubuntu, and the Janelia compute cluster (IBM Platform LSF).

The pipeline includes the following modules:
* **catGT_helper** - run CatGT preprocessor
* **kilosort_helper** - run spike sorting
* **kilosort_postprocessing** - cleanup Kilosort outputs
* **noise_templates** - identify noise units
* **mean_waveforms** - extract mean waveforms and compute waveform metrics from raw data, given spike times and cluster IDs.
* **quality_metrics** - compute quality metrics for sorted units
* **tPrime_helper** - map times from one SpikeGLX stream to another

## SGLX Runs Required Parameters

The following parameters are required to run the full pipeline. See the [parameter documentation](docs/Parameters.md) for a complete list of all possible options.

| Argument   | Description                                                                           |
|------------|---------------------------------------------------------------------------------------|
| --data_dir | Path to the directory containing SGLX runs. | 
| --results_dir | Path to the directory containing pipeline outputs. If not specified it defaults to the `data_dir` |
| --config_dir | Path where json config files for different steps are generated. If not specified it defaults to `results_dir` |  
| --runs | JSON file containing runs specs to be processed. |
| --probe_steps | Comma separated list of steps to be  run for each probe |


## SGLX Recordings Pipeline

The recordings pipeline is very similar to the runs pipeline the only difference is that the `--runs` parameter is replaced with the `--recordings` parameter and the steps for each recording are defined by `--recording_steps` argument. Also for the recordings pipeline `--data_dir` is not used since each recording spec has the full path to the binary recording file.

| Argument   | Description                                                                           |
|------------|---------------------------------------------------------------------------------------|
| --recordings | JSON file containing recording specs |
| --recording_steps| Comma separated list of pipeline steps |

The recordings specs JSON file looks like this:
```
[
    {
        "binaryLocation": "/probes1/SC011_022319_g0_tcat.imec3.ap.bin",
        "region": "default"
    },
    {
        "binaryLocation": "/probes2/SC011_022320_g0_tcat.imec3.ap.bin",
        "region": "default"
    }
]
```

## Pipeline execution

Nextflow supports many different execution engines for portability across platforms and schedulers. We have tested the pipeline using local execution and using the cluster at Janelia Research Campus (running IBM Platform LSF). To run on a different cluster with a different scheduler, add a new profile type to nextflow.config to set up the calling command.

To run this pipeline on a cluster, all input and output paths must be mounted and accessible on all the cluster nodes. 

### Run the pipeline locally

To run the pipeline locally, you can use the standard profile:

    ./main.nf [arguments]

### Run the pipeline on IBM Platform LSF 

This example also sets the project flag to demonstrate how to set LSF options.

    ./main.nf -profile lsf --lsf_opts "-P <lsf_project_code>" [arguments]

Concrete examples for running the pipeline are provided in the `examples` folder. In practice, becuase there are so many parameters, it is easiest to run from a shell script. examples/process_runs.sh and examples/process_recordings.sh demonstrate calling in LSF environment; examples/process_runs_std is for running in on a standalone workstation.

On the Janalia's LSF cluster the best way to run the pipeline, would be to run the main.nf either in an interactive job or by simply submitting `main.nf` to the cluster, as shown in the example scripts. The reason for this is that nextflow must run on a submit host in order to be able to submit jobs and sommetimes this may be a long running process. 

To start an interactive job check [Janelia Wiki Page](https://wiki.int.janelia.org/wiki/display/ScientificComputing/Janelia+Compute+Cluster#JaneliaComputeCluster-ExampleInteractivejobcommands). Once the job is running the rest of the processing is as if you were running nextflow on any linux server or workstation. Keep in mind that if you want to run the pipeline on the node where the interactive node is running you need access to the GPU. 

To submit the nextflow job to the cluster the command is:
```
bsub -n 1 -o job.out -e job.err nextflow -P <lsf_project_code> run main.nf -profile lsf -- lsf_opts "-P <lsf_project_code>" [arguments]
```

Usage examples are available in the [examples](examples) directory.

## User Manual

Further detailed documentation is available here:

* [Pipeline Parameters](docs/Parameters.md)
* [Running on Windows](docs/RunningOnWindows.md)
* [Development](docs/Development.md)

## License

This software is made available under [Janelia's Open Source Software](https://www.janelia.org/open-science/software-licensing) policy which uses the BSD 3-Clause License and under the [Allen Institute Software License](LICENSE.txt). 
