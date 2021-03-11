#!/bin/sh

./main.nf \
    -profile localdocker \
    --recordings examples/recordings.json \
    --data_dir $PWD/../testData \
    --config_dir $PWD/local/test/config \
    --results_dir $PWD/local/test/results \
    --ks_working_dir /tmp/ks_tmp \
    --has_aux_data true
