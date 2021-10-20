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
    get_map_or_default;
    catgt_modules_container_param;
    cwaves_modules_container_param;
    ecephys_modules_container_param;
    kilosort_container_param;
    tprime_modules_container_param
} from './lib/params_utils'

include {
    prepare_run_specs;
    prepare_recording_specs;
} from './lib/probe_utils'

final_params = default_params() + params

process_params = final_params + 
    [
        ks_thresholds_by_region: get_map_or_default(final_params, 'ks_thresholds_by_region', [default_value: '[9,9]']),
        ref_per_ms_by_region: get_map_or_default(final_params, 'ref_per_ms_by_region', [default_value: 2.0]),
        catgt_container: catgt_modules_container_param(final_params),
        cwaves_container: cwaves_modules_container_param(final_params),
        ecephys_modules_container: ecephys_modules_container_param(final_params),
        kilosort_container: kilosort_container_param(final_params),
        tprime_container: tprime_modules_container_param(final_params),
    ]

probe_steps = get_list_or_default(
            final_params,
            'probe_steps',
            [
                'catGT_helper',
                'depth_estimation',
                'kilosort_helper',
                'kilosort_postprocessing',
                'noise_templates',
                'psth_events',
                'mean_waveforms',
                'quality_metrics',
                'tPrime_helper',
            ]
        )

recording_steps = get_list_or_default(
            final_params,
            'recording_steps',
            [
                'kilosort_helper',
                'kilosort_postprocessing',
                'noise_templates',
                'mean_waveforms',
                'quality_metrics',
            ]
        )

include {
    process_probes_for_all_runs;
    process_tprime;
} from './workflows/process_runs' addParams(process_params + create_ks_params(probe_steps))

include {
    process_all_recordings;
} from './workflows/process_recordings' addParams(process_params+ create_ks_params(recording_steps))

data_dir = final_params.data_dir // probes dir
results_dir = get_value_or_default(final_params, 'results_dir', data_dir)
config_dir = get_value_or_default(final_params, 'config_dir', results_dir)

workflow {
    
    if (final_params.runs) {
        // if the runs parameter is specified 
        // read and proccess the run specs from the speccifed runs file
        def runs = prepare_run_specs(read_json(file(final_params.runs)))
        // process all probes
        def probe_results = process_probes_for_all_runs(
            data_dir,
            results_dir,
            config_dir,
            runs,
            probe_steps)

        if (probe_steps.contains('tPrime_helper')) {
            def tprime_inputs = probe_results
            | groupTuple(by: [3,5,6,8]) // group by run_folder, run_name, gate, triggers

            tprime_inputs.subscribe { log.debug "TPrime input: $it" }

            process_tprime(
                data_dir,
                results_dir,
                config_dir,
                tprime_inputs.map { it[3] }, // run folder
                tprime_inputs.map { it[5] }, // run name
                tprime_inputs.map { it[6] }, // gate name
                tprime_inputs.map { it[7] }, // probes
                tprime_inputs.map { it[8] }, // triggers
            ) | view
        }
    }

    if (final_params.recordings) {
        // if the recordings parameter is specified
        // read and process the recording specs from the specified file
        def recordings = prepare_recording_specs(read_json(file(final_params.recordings)))
        def recording_results = process_all_recordings(
            results_dir,
            config_dir,
            recordings,
            recording_steps)
        
        recording_results | view
    }

}

def create_ks_params(steps) {
    [
        ks_copy_results: steps.contains('kilosort_postprocessing') ||
                         steps.contains('noise_templates'),
    ]
}
