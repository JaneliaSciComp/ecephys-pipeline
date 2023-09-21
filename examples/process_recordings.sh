#!/bin/bash

# PATHS FOR THIS RUN
# folder for output, shares parent drive (dm11 or nrs) as DATA_DIR. Will be created if it doesn't exist.
OUTPUT_DIR=/groups/apig/apig/jic/SC048_out/preprocessed/output/

# json file of full paths to preprocessed input data (tcat files)
RECORDING_SPECS_FILE=/groups/apig/apig/jic/SC048_out/preprocessed/SC048_recordings.json

# name for log files
RUN_NAME='SC048_rec_01'

# PATHS for your setup
# PARENT_DIR - folder that contains DATA_DIR and OUTPUT_DIR
# PARAM_DIR - folder containing this script and params files
# WORKFLOW_DIR - ecephys-pipeline
PARENT_DIR=/groups/apig/apig/jic
PARAM_DIR=/groups/apig/apig/jic/ecephys_test_data/run_cluster_ecephys
WORKFLOW_DIR=/groups/apig/home/colonellj/ecephys-pipeline
MLM_FULLPATH=27000@vm7142.int.janelia.org

# PATHS to run local copy of the ecephys modules (rather than the version in the containers)
# see SINGULARITY_RUNTIME_OPTS
LOCAL_MODULES_DIR=$WORKFLOW_DIR/containers/ecephys-modules/ecephys_spike_sorting
CONTAINER_MODULES_DIR=/app/ecephys_spike_sorting/ecephys_spike_sorting

# LSF_PROJECT_CODE set it to the output of `lsfgroup yourusername`
LSF_PROJECT_CODE=harris
echo "$LSF_PROJECT_CODE"

# To monitor using nextflow tower, add 
# -with-tower "http://nextflow.int.janelia.org/api" to the command line
# login to http://nextflow.int.janelia.org and create a token under "Your tokens" menu
# past that token here
export TOWER_ACCESS_TOKEN=eyJ0aWQiOiAyNX0uZjExMDc3YWVlYTBkMTQxNjBmMTI5YzI3MDZiZWU3NjQ3Y2QxZjBkNw==

KS_TH_BY_REGION_FILE=${PARAM_DIR}/ks2ThByRegion.json
REF_MS_BY_REGION_FILE=${PARAM_DIR}/refmsByRegion.json
CONFIG_DIR=${OUTPUT_DIR}/config
RESULTS_DIR=${OUTPUT_DIR}/results
OUT_NAME=${RUN_NAME}.out
ERR_NAME=${RUN_NAME}.err

RECORDING_STEPS=\
"kilosort_helper,kilosort_postprocessing,mean_waveforms,quality_metrics"

# container source, e.g. internal registry or aws Elastic Container Registry (ECR)
CONTAINER_SOURCE=public.ecr.aws/janeliascicomp/ecephys

# SINGULARITY_RUNTIME_OPTS - typically it contains volumes that must be mounted inside the container
# To run from the local copy of the python modules, add the mapping: -B ${LOCAL_MODULES_DIR}:${CONTAINER_MODULES_DIR}
SINGULARITY_RUNTIME_OPTS="--nv --env MLM_LICENSE_FILE=${MLM_FULLPATH} -B ${PARENT_DIR}"


RECORDING_STEPS=\
"kilosort_helper,kilosort_postprocessing,mean_waveforms,quality_metrics"

bsub -J $RUN_NAME -n 2 -e $ERR_NAME -o $OUT_NAME -P $LSF_PROJECT_CODE \
NXF_VER=20.10.0 nextflow run ${WORKFLOW_DIR}/main.nf \
    -profile lsf \
    --runtime_opts "${SINGULARITY_RUNTIME_OPTS}" \
    --catgt_container "${CONTAINER_SOURCE}/catgt:4.2" \
    --cwaves_container "${CONTAINER_SOURCE}/cwaves:1.9" \
    --ecephys_modules_container "${CONTAINER_SOURCE}/ecephys-modules:1.0.6" \
    --kilosort_container "${CONTAINER_SOURCE}/kilosort:1.0.4" \
    --pykilosort_container "${CONTAINER_SOURCE}/pykilosort:1.0.4" \
    --tprime_container "${CONTAINER_SOURCE}/tprime:1.7" \
    --lsf_opts "-P $LSF_PROJECT_CODE" \
    --recording_steps ${RECORDING_STEPS} \
    --recordings ${RECORDING_SPECS_FILE} \
    --ks_thresholds_by_region ${KS_TH_BY_REGION_FILE} \
    --ref_per_ms_by_region ${REF_MS_BY_REGION_FILE} \
    --config_dir ${CONFIG_DIR} \
    --results_dir ${RESULTS_DIR} \
    --ks_cpus 8 \
    --ks_post_cpus 6 \
    --metrics_cpus 6 \
    --ks_working_dir ${PARENT_DIR}/ks_tmp \
    --with_pyks false \
    --with_ks_filter false \
    --ks_car false \
    --ks_ver '2.0' \
    --ks_output_tag 'ks2-rec' \
    --ks_copy_results true \
    --ks_copy_fproc 0 \
    --ks_save_rez 0 \
    --include_pcs true \

