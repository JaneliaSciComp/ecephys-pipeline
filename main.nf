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
    process_tprime;
} from './workflows/process_runs' addParams(process_params)

data_dir = final_params.data_dir // probes dir
results_dir = get_value_or_default(final_params, 'results_dir', data_dir)
config_dir = get_value_or_default(final_params, 'config_dir', results_dir)
working_dir = get_value_or_default(final_params, 'working_dir', "${results_dir}/tmp")

runs_file = final_params.runs
probe_steps = get_list_or_default(
            final_params,
            'probe_steps',
            [
                'catGT_helper',
                'kilosort_helper',
                'kilosort_postprocessing',
                'noise_templates',
                'psth_events',
                'mean_waveforms',
                'quality_metrics',
                'tPrime_helper',
            ]
        )


log.info """
         Run $probe_steps
         """

workflow {
    def runs = prepare_run_specs(read_json(file(runs_file)))
    // process all probes
    def probe_results = process_probes_for_all_runs(
        data_dir,
        results_dir,
        config_dir,
        runs,
        probe_steps)

    if (probe_steps.contains('tPrime_helper')) {
        def tprime_inputs = probe_results
        | groupTuple(by: [2,4,5,7]) // group by run_folder, run_name, gate, triggers

        process_tprime(
            data_dir,
            results_dir,
            config_dir,
            tprime_inputs.map { it[2] }, // run folder
            tprime_inputs.map { it[4] }, // run name
            tprime_inputs.map { it[5] }, // gate name
            tprime_inputs.map { it[6] }, // probes
            tprime_inputs.map { it[7] }, // triggers
        ) | view
    }

}
