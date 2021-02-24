include {
    probe_str;
    probe_name;
    global_config;
    write_config;
} from '../lib/probe_utils'

process kilosort_config {
    container = params.kilosort_container
    cpus { params.ks_config_cpus }

    input:
    tuple val(probe),
          val(probe_file),
          val(config_dir),
          val(csb_seed),
          val(ks_working_dir),
          val(output_dir)

    output:
    tuple val(probe), val(probe_file)

    script:
    def pname = probe_name(probe)
    def kilosort_input_config = global_config(config_dir, pname)
    def pstr = probe_str(probe)
    def kilosort_output_dir = "${output_dir}/${pname}/imec${pstr}_ks2"
    """
    umask 000
    python \
        -m ecephys_spike_sorting.helpers.create_input_config \
        ${probe_file} \
        ${kilosort_input_config} \
        ${kilosort_output_dir} \
        --csb_seed ${csb_seed} \
        --ks_working_path ${ks_working_dir}/${pname} \
        --ks_copy_results
    """
}

process kilosort {
    container = params.kilosort_container
    cpus { params.ks_cpus }

    label 'withGPU'

    input:
    tuple val(probe), 
          val(probe_file),
          val(ks_working_dir),
          val(config_dir)

    output:
    tuple val(probe),
          val(probe_file),
          val(kilosort_input_file),
          val(kilosort_output_file)

    script:
    def pname = probe_name(probe)
    def config_file = global_config(config_dir, pname)
    def config = read_config(config_file)
    def kilosort_config = filter_config(config, [
        'kilosort_helper_params',
        'directories',
        'ephys_params',
        'common_files'
    ])

    def kilosort_input_file = config_file(config_dir, pname, 'kilosort', 'input')
    write_config(kilosort_config, kilosort_input_file)
    kilosort_output_file = config_file(config_dir, pname, 'kilosort', 'output')
    """
    umask 000
    mkdir -p ${ks_working_dir}/${pname}
    python \
        -m ecephys_spike_sorting.modules.kilosort_helper \
        --input_json ${kilosort_input_config_file} \
        --output_json ${kilosort_output_file}
    """
}

process kilosort_post_processing {
    container = params.kilosort_container
    cpus { params.ks_post_cpus }

    input:
    tuple val(probe),
          val(probe_file),
          val(config_dir)

    output:
    tuple val(probe),
          val(probe_file),
          val(ks_post_proc_input_file),
          val(ks_post_proc_output_file)


    script:
    def pname = probe_name(probe)
    def config_file = global_config(config_dir, pname)
    def config = read_config(config_file)
    def kilosort_post_processing_config = filter_config(config, [
        'ks_postprocessing_params',
        'directories',
        'ephys_params'
    ])

    ks_post_proc_input_file = config_file(config_dir, pname, 'kilosort_postprocessing', 'input')
    write_config(kilosort_post_processing_config, ks_post_proc_input_file)
    ks_post_proc_output_file = config_file(configDir, probeName, 'kilosort_postprocessing', 'output')
    """
    umask 000
    python \
        -m ecephys_spike_sorting.modules.kilosort_postprocessing \
        --input_json ${ks_post_proc_input_file} \
        --output_json ${ks_post_proc_output_file}
    """
}
