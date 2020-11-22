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
    input_config;
    output_config 
} from './lib/probe_utils.nf'

final_params = get_params(params + default_params())

inputDir = file(final_params.input_path)
outputDir = file(final_params.output_path)
configDir = file(final_params.config_path)

if( !outputDir.exists() ) {
    outputDir.mkdirs()
}
if( !configDir.exists() ) {
    configDir.mkdirs()
}

process kilosortConfig {
    container = "${final_params.containersRepo}ecephys:1.0"

    input:
    tuple val(probe), val(probeFile)

    output:
    tuple val(probe), val(probeFile)

    script:
    probeName = probe_name(probe)
    kilosortInputConfig = input_config(configDir, probeName)
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
        --ks_copy_results
    """
}

process kilosort {
    container = "${final_params.containersRepo}ecephys:1.0"

    label 'requireGPU'

    input:
    tuple val(probe), val(probeFile)

    output:
    tuple val(probe), val(probeName)

    script:
    probeName = probe_name(probe)
    kilosortInputConfig = input_config(configDir, probeName)
    kilosortOutputConfig = output_config(configDir, probeName)
    """
    umask 000
    python \
        -m ecephys_spike_sorting.modules.kilosort_helper \
        --input_json ${kilosortInputConfig} \
        --output_json ${kilosortOutputConfig}
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
    kilosortInputConfig = input_config(configDir, probeName)
    kilosortOutputConfig = output_config(configDir, probeName)
    """
    umask 000
    python \
        -m ecephys_spike_sorting.modules.kilosort_postprocessing \
        --input_json ${kilosortInputConfig} \
        --output_json ${kilosortOutputConfig}
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
