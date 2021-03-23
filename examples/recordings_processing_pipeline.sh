#!/bin/sh

PROFILE=lsf
# LSF_PROJECT_CODE set it to the output of `lsfgroup yourusername`
LSF_PROJECT_CODE=
# SINGULARITY_RUNTIME_OPTS - typically it contains volumes that must be mounted inside the container
# When the recordings json is present all directories for the probes present in the file must
# be accessible inside the container so make sure you either bind all the directories
# or their common (non-roott) directory
SINGULARITY_RUNTIME_OPTS=""

# TOWER_ACCCESS_TOKEN is available after login to http://nextflow.int.janelia.org under "Your tokens" menu
export TOWER_ACCESS_TOKEN=072f8fd02196a0b75f378ef237549c6822c221da

if [[ "$PROFILE" == "lsf"]] ; then
    PROFILE_ARG="-profile lsf"
else
    PROFILE_ARG=
fi

./main.nf \
    ${PROFILE_ARG} \
    -with-tower "http://nextflow.int.janelia.org/api" \
    --runtime_opts "${SINGULARITY_RUNTIME_OPTS}" \
    --lsf_opts "-P ${LSF_PROJECT_CODE}" \
    --recordings examples/recordings.json \
    --config_dir $PWD/local/test/config \
    --results_dir $PWD/local/test/results \
    --ks_working_dir /tmp/ks_tmp
