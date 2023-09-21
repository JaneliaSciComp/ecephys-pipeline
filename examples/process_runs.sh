#!/bin/bash

# Data location
# DATA_DIR - folder that contains all runs
# OUTPUT_DIR - folder for output, needs to share a parent drive (dm11 or nrs) as DATA_DIR. Will be created if it doesn't exist.
foldername=SC048
DATA_DIR=/groups/apig/apig/jic/${foldername}
OUTPUT_DIR=/groups/apig/apig/jic//${foldername}_out
RUNS_SPECS_FILE=/groups/apig/apig/jic/${foldername}/${foldername}_runs.json

# name for log files
RUN_NAME=${foldername}_ks2_test_01


# Environment paths
# PARENT_DIR - folder that contains DATA_DIR and OUTPUT_DIR
# PARAM_DIR - folder containing this script and parameter files
# WORKFLOW_DIR - ecephys-pipeline
# MLM_FULLPATH - full path to MATLAB LICENCE file
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
# paste that token here
# plus add -with-tower "http://nextflow.int.janelia.org/api" parameter to nf command line
export TOWER_ACCESS_TOKEN=eyJ0aWQiOiAyNX0uZjExMDc3YWVlYTBkMTQxNjBmMTI5YzI3MDZiZWU3NjQ3Y2QxZjBkNw==


CONFIG_DIR=${OUTPUT_DIR}/config
RESULTS_DIR=${OUTPUT_DIR}/results
KS_TH_BY_REGION_FILE=${PARAM_DIR}/ks2ThByRegion.json
REF_MS_BY_REGION_FILE=${PARAM_DIR}/refmsByRegion.json
GFIX_BY_REGION_FILE=${PARAM_DIR}/gfixByRegion.json

OUT_NAME=${RUN_NAME}.out
ERR_NAME=${RUN_NAME}.err

# container source, e.g. internal registry or aws Elastic Container Registry (ECR)
CONTAINER_SOURCE=public.ecr.aws/janeliascicomp/ecephys

# SINGULARITY_RUNTIME_OPTS - typically it contains volumes that must be mounted inside the container
# if DATA_DIR and OUTPUT_DIR have a common parent only mount the parent
# To run from the local copy of the python modules, add the mapping: -B ${LOCAL_MODULES_DIR}:${CONTAINER_MODULES_DIR}
SINGULARITY_RUNTIME_OPTS="--nv --env MLM_LICENSE_FILE=${MLM_FULLPATH} -B ${PARENT_DIR}"

# full set of possible probe steps
#PROBE_STEPS=\
#"catGT_helper,kilosort_helper,kilosort_postprocessing,mean_waveforms,quality_metrics,tPrime_helper"
# probe steps to run with this script:
PROBE_STEPS="catGT_helper,kilosort_helper,kilosort_postprocessing,mean_waveforms,quality_metrics,tPrime_helper"

bsub -J $RUN_NAME -n 2 -e $ERR_NAME -o $OUT_NAME -P $LSF_PROJECT_CODE \
NXF_VER=20.10.0  nextflow run ${WORKFLOW_DIR}/main.nf \
    -profile lsf \
    --runtime_opts "${SINGULARITY_RUNTIME_OPTS}" \
    --catgt_container "${CONTAINER_SOURCE}/catgt:4.2" \
    --cwaves_container "${CONTAINER_SOURCE}/cwaves:1.9" \
    --ecephys_modules_container "${CONTAINER_SOURCE}/ecephys-modules:1.0.6" \
    --kilosort_container "${CONTAINER_SOURCE}/kilosort:1.0.4" \
    --pykilosort_container "${CONTAINER_SOURCE}/pykilosort:1.0.4" \
    --tprime_container "${CONTAINER_SOURCE}/tprime:1.7" \
    --lsf_opts "-P $LSF_PROJECT_CODE" \
    --probe_steps ${PROBE_STEPS} \
    --runs ${RUNS_SPECS_FILE} \
    --ks_thresholds_by_region ${KS_TH_BY_REGION_FILE} \
    --ref_per_ms_by_region ${REF_MS_BY_REGION_FILE} \
    --gfix_by_region ${GFIX_BY_REGION_FILE} \
    --data_dir ${DATA_DIR} \
    --config_dir ${CONFIG_DIR} \
    --results_dir ${RESULTS_DIR} \
    --ks_cpus 8 \
    --ks_post_cpus 6 \
    --metrics_cpus 6 \
    --ks_working_dir ${PARENT_DIR}/ks_tmp \
    --catgt_cmd_args '-prb_fld -apfilter=butter,16,250,9000 -lffilter=butter,16,1,500' \
    --catgt_do_gfix true \
    --catgt_car_mode 'loccar' \
    --catgt_loccar_min 50 \
    --catgt_loccar_max 200 \
    --catgt_skip false \
    --has_aux_data true \
    --ni_present true \
    --ni_extract_cmd_args '-xa=0,0,0,1,3,500 -xia=0,0,1,3,3,0 -xd=0,0,-1,1,50 -xid=0,0,-1,2,1.7 -xid=0,0,-1,3,5 -xid=0,0,-1,3,5' \
    --process_lf true \
    --with_pyks false \
    --with_ks_filter false \
    --ks_car false \
    --ks_ver '2.0' \
    --ks_output_tag 'ks2' \
    --ks_copy_results true \
    --ks_copy_fproc 0 \
    --ks_save_rez 0 \
    --include_pcs true \
    --event_ex_cmd_arg 'xd=0,0,-1,1,50' \
    --to_stream_sync_cmd_args 'imec0'
