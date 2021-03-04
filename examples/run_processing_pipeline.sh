#!/bin/sh

./main.nf \
    -profile localdocker \
    --runs examples/runs.json \
    --data_dir $PWD/../testData/SC_10trial \
    --config_dir $PWD/local/test/config \
    --results_dir $PWD/local/test/results \
    --ks_working_dir /tmp/ks_tmp \
    --has_aux_data true
