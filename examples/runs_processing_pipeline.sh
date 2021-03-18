#!/bin/bash

# DATA_DIR - folder that contains all runs
DATA_DIR=/nrs/scicompsoft/goinac/ecephys/SC_10trial
OUTPUT_DIR=$PWD/local/test
CONFIG_DIR=${OUTPUT_DIR}/config
RESULTS_DIR=${OUTPUT_DIR}/results
RUNS_SPECS_FILE=examples/runs.json
KS_TH_BY_REGION_FILE=examples/ks3ThByRegion.json
REF_MS_BY_REGION_FILE=examples/refmsByRegion.json
# LSF_PROJECT_CODE set it to the output of `lsfgroup yourusername`
LSF_PROJECT_CODE=harris
# SINGULARITY_RUNTIME_OPTS - typically it contains volumes that must be mounted inside the container
# if DATA_DIR and OUTPUT_DIR have a common parent only mount the parent
SINGULARITY_RUNTIME_OPTS="--nv -B ${DATA_DIR}"

# TOWER_ACCCESS_TOKEN is available after login to http://nextflow.int.janelia.org under "Your tokens" menu
export TOWER_ACCESS_TOKEN=072f8fd02196a0b75f378ef237549c6822c221da

./main.nf \
    -profile lsf \
    -with-tower "http://nextflow.int.janelia.org/api" \
    --runtime_opts "${SINGULARITY_RUNTIME_OPTS}" \
    --lsf_opts "-P ${LSF_PROJECT_CODE}" \
    --runs ${RUNS_SPECS_FILE} \
    --ks_thresholds_by_region ${KS_TH_BY_REGION_FILE} \
    --ref_per_ms_by_region ${REF_MS_BY_REGION_FILE} \
    --data_dir ${DATA_DIR} \
    --config_dir ${CONFIG_DIR} \
    --results_dir ${RESULTS_DIR}
