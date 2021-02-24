#!/usr/bin/env nextflow

/*
    Ecephys spike sorting

    Parameters:
*/
nextflow.enable.dsl=2

include {
    default_params;
    get_value_or_default;
} from './lib/params_utils.nf'

include {
    probe_str;
    probe_name;
    config_file;
    filter_config;
    read_config;
    write_config 
} from './lib/probe_utils.nf'

final_params = default_params() + params

input_dir = final_params.in
output_dir = get_value_or_default(final_params, 'out', input_dir)
config_dir = get_value_or_default(final_params, 'config', output_dir)

steps = get_list_or_default(final_params, 'steps', [])

ks_working_dir = get_value_or_default(final_params, 'ks_working_dir', '/tmp/kilosort_datatemp')

if( !outputDir.exists() ) {
    outputDir.mkdirs()
}

if( !configDir.exists() ) {
    configDir.mkdirs()
}


workflow {
    probes_to_process = Channel
                        .fromPath("$inputDir/*.bin")
                        .map { f -> [f.name, f] }

    ks_configs = kilosortConfig(probes_to_process)
    ks_res = kilosort(ks_configs)
    res = kilosortPostProcessing(ks_res)

    res.view {it -> println("!!!!! IT is $it")}
}
