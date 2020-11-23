# Extracellular Electrophysiology Pipeline

## Usage

You must have [Nextflow](https://www.nextflow.io) and [Singularity](https://sylabs.io) installed before running the pipeline.

### Local execution
```
./pipeline.nf -config nextflow.config -profile localsingularity --in /path/to/probes --config /path/to/configs --out /path/to/outputs
```

### LSF execution on Janelia cluster
```
./pipeline.nf \
    -config nextflowl.config \
    -profile lsf \
    -with-tower 'http://nextflow.int.janelia.org/api' \
    --in /path/to/probes --config /path/to/step-configs --out /path/to/outputs
```
This also uses the internal Janelia instance of Nextflow Tower.
