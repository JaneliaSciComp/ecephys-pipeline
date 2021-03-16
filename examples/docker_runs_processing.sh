docker run \
       -v /var/run/docker.sock:/var/run/docker.sock \
       -v /Users/goinac/Work/HHMI/ecephys_spike_sorting:/Users/goinac/Work/HHMI/ecephys_spike_sorting \
       nextflow/nextflow:20.10.0 \
       nextflow \
       -dockerize \
       -c /Users/goinac/Work/HHMI/ecephys_spike_sorting/ecephys_spike_sorting/nextflow.config \
       run \
       -w /Users/goinac/Work/HHMI/ecephys_spike_sorting/ecephys_spike_sorting/work \
       /Users/goinac/Work/HHMI/ecephys_spike_sorting/ecephys_spike_sorting/main.nf \
       -profile localdocker \
       --runs /Users/goinac/Work/HHMI/ecephys_spike_sorting/ecephys_spike_sorting/examples/runs.json \
       --data_dir /Users/goinac/Work/HHMI/ecephys_spike_sorting/testData/SC_10trial \
       --config_dir /Users/goinac/Work/HHMI/ecephys_spike_sorting/ecephys_spike_sorting/local/test/config \
       --results_dir /Users/goinac/Work/HHMI/ecephys_spike_sorting/ecephys_spike_sorting/local/test/results \
       --ks_working_dir /tmp/ks_tmp \
       --has_aux_data true
