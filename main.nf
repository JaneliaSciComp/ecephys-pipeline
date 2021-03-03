#!/usr/bin/env nextflow

/*
    Ecephys spike sorting

    Parameters:
*/
nextflow.enable.dsl=2

include {
    read_json;
} from './lib/utils'

include {
    default_params;
    get_value_or_default;
    get_list_or_default;
    catgt_modules_container_param;
    cwaves_modules_container_param;
    ecephys_modules_container_param;
    kilosort_container_param;
    tprime_modules_container_param

} from './lib/params_utils'

include {
    prepare_run_specs;
} from './lib/probe_utils'

final_params = default_params() + params

process_params = final_params + 
    [
        catgt_container: catgt_modules_container_param(final_params),
        cwaves_container: cwaves_modules_container_param(final_params),
        ecephys_modules_container: ecephys_modules_container_param(final_params),
        kilosort_container: kilosort_container_param(final_params),
        tprime_container: tprime_modules_container_param(final_params),
    ]
include {
    process_probes_for_all_runs;
} from './workflows/process_runs' addParams(process_params)

data_dir = final_params.data_dir // probes dir
results_dir = get_value_or_default(final_params, 'results_dir', data_dir)
config_dir = get_value_or_default(final_params, 'config_dir', results_dir)
working_dir = get_value_or_default(final_params, 'working_dir', "${results_dir}/tmp")

runs_file = final_params.runs
probe_steps = get_list_or_default(
            final_params,
            'steps',
            [
                'catGT_helper',
                'kilosort_helper',
                'kilosort_postprocessing',
                'noise_templates',
                'mean_waveforms',
                'quality_metrics'
            ]
        )

println "!!!!!!!!!!!! PROBE STEPS: $probe_steps"
workflow {
    def runs = prepare_run_specs(read_json(file(runs_file)))
    process_probes_for_all_runs(
        data_dir,
        results_dir,
        config_dir,
        working_dir,
        runs,
        probe_steps) | view

}
