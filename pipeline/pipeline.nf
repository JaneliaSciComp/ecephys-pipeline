#!/usr/bin/env nextflow

/*
    Ecephys spike sorting

    Parameters:
*/
nextflow.enable.dsl=2

include { default_params; get_params } from './lib/params_utils.nf'
include { 
    probe_str; 
    probe_name;
    config_file;
    filter_config;
    read_config;
    write_config 
} from './lib/probe_utils.nf'

final_params = get_params(params + default_params())

inputDir = file(final_params.input_path)
outputDir = file(final_params.output_path)
configDir = file(final_params.config_path)
ksWorkingDir = file(final_params.ks_working_dir)

if( !outputDir.exists() ) {
    outputDir.mkdirs()
}
if( !configDir.exists() ) {
    configDir.mkdirs()
}

def global_config(configDir, probeName) {
    return config_file(configDir, probeName, 'all', 'config')
}

process kilosortConfig {
    container = "${final_params.containersRepo}ecephys${final_params.ecephys_version}"

    input:
    tuple val(probe), val(probeFile)

    output:
    tuple val(probe), val(probeFile)

    script:
    probeName = probe_name(probe)
    kilosortInputConfig = global_config(configDir, probeName)
    probeStr = probe_str(probe)
    kilosortOutputDir = file("${outputDir}/${probeName}/imec${probeStr}_ks2")
    """
    umask 000
    python \
        -m ecephys_spike_sorting.helpers.create_input_config \
        ${probeFile} \
        ${kilosortInputConfig} \
        ${kilosortOutputDir} \
        --csb_seed ${final_params.csb_seed} \
        --ks_working_path ${ksWorkingDir}/${probeName} \
        --ks_copy_results
    """
}

process kilosort {
    container = "${final_params.containersRepo}ecephys${final_params.ecephys_version}"

    label 'requireGPU'

    input:
    tuple val(probe), val(probeFile)

    output:
    tuple val(probe), val(probeName)

    script:
    probeName = probe_name(probe)
    configFile = global_config(configDir, probeName)
    config = read_config(configFile)
    kilosortConfig = filter_config(config, [
        'kilosort_helper_params',
        'directories',
        'ephys_params',
        'common_files'
    ])

    inputConfigFile = config_file(configDir, probeName, 'kilosort', 'input')
    write_config(kilosortConfig, inputConfigFile)
    outputConfigFile = config_file(configDir, probeName, 'kilosort', 'output')
    """
    umask 000
    mkdir -p ${ksWorkingDir}
    python \
        -m ecephys_spike_sorting.modules.kilosort_helper \
        --input_json ${inputConfigFile} \
        --output_json ${outputConfigFile}
    """
}

process kilosortPostProcessing {
    container = "${final_params.containersRepo}ecephys:1.0"

    input:
    tuple val(probe), val(probeFile)

    output:
    tuple val(probe), val(probeName)

    script:
    probeName = probe_name(probe)
    configFile = global_config(configDir, probeName)
    config = read_config(configFile)
    kilosortPostProcessingConfig = filter_config(config, [
        'ks_postprocessing_params',
        'directories',
        'ephys_params'
    ])

    inputConfigFile = config_file(configDir, probeName, 'kilosort_postprocessing', 'input')
    write_config(kilosortPostProcessingConfig, inputConfigFile)
    outputConfigFile = config_file(configDir, probeName, 'kilosort_postprocessing', 'output')
    """
    umask 000
    python \
        -m ecephys_spike_sorting.modules.kilosort_postprocessing \
        --input_json ${inputConfigFile} \
        --output_json ${outputConfigFile}
    """
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
