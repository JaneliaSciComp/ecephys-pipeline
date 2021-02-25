#!/usr/bin/env nextflow

/*
    Ecephys spike sorting

    Parameters:
*/
nextflow.enable.dsl=2

include {
    default_params;
    get_value_or_default;
    get_list_or_default;
} from './lib/params_utils'

include {
    prepare_run_specs;
    read_config;
} from './lib/probe_utils'

final_params = default_params() + params

include {
    process_runs;
} from './workflows/process_runs'

npx_dir = final_params.npx_dir // probes dir
output_dir = get_value_or_default(final_params, 'out', npx_dir)
config_dir = get_value_or_default(final_params, 'config', output_dir)
working_dir = get_value_or_default(final_params, 'working_dir', '/tmp/kilosort_temp')

runs_file = final_params.runs
steps = get_list_or_default(final_params, 'steps', [])


workflow {

    def runs = prepare_run_specs(read_config(file(runs_file)))
    println "!!!! SPECS $runs"
    process_runs(npx_dir, runs) | view

    // probes_to_process = Channel
    //                     .fromPath("$inputDir/*.bin")
    //                     .map { f -> [f.name, f] }

    // ks_configs = kilosortConfig(probes_to_process)
    // ks_res = kilosort(ks_configs)
    // res = kilosortPostProcessing(ks_res)

    // res.view {it -> println("!!!!! IT is $it")}
}
