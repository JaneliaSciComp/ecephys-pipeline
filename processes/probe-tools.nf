include {
    filter_config;
    config_file;
} from '../lib/probe_utils'

include {
    read_json;
    write_json;
} from '../lib/utils'

process create_probe_config {
    container = params.ecephys_modules_container
    cpus 1

    input:
    tuple val(probe_data_dir),
          val(probe_data_file),
          val(probe_meta_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers),
          val(probe_type),
          // region specific parameters
          val(probe_ks_th),
          val(probe_ref_per_ms),
          // kilosort
          val(probe_ks_output_dir),
          val(probe_ks_working_dir),
          // catgt
          val(probe_catgt_output_dir),
          val(probe_stream_params),
          val(probe_catgt_cmd),
          val(probe_catgt_extract_string),
          // tprime
          val(im_ex_list),
          val(ni_ex_list),
          val(to_stream_sync_params),
          val(ni_stream_sync_params)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def probe_config_dir = file(probe_config_file).parent
    def args_list = [
        create_arg('--npx_dir', probe_data_dir),
        create_arg('--probe_data', probe_data_file),
        create_arg('--probe_meta', probe_meta_file),
        create_arg('--output_config_file', probe_config_file),
        create_arg('--kilosort_output_dir', probe_ks_output_dir),
        create_arg('--ks_working_dir', probe_ks_working_dir),
        create_arg('--ks_ver', params.ks_ver),
        create_bool_arg('--ks_copy_results', params.ks_copy_results),
        create_arg('--ks_remove_dups', params.ks_remove_dups),
        create_arg('--ks_save_rez', params.ks_save_rez),
        create_arg('--ks_copy_fproc', params.ks_copy_fproc),
        create_arg('--ks_minfr_goodchannels', params.ks_minfr_goodchannels),
        create_arg('--ks_whitening_radius_um', params.ks_whitening_radius_um),
        create_arg('--ks_th', probe_ks_th),
        create_arg('--ks_csb_seed', params.ks_csb_seed),
        create_arg('--ks_lt_seed', params.ks_lt_seed),
        create_arg('--ks_template_radius_um', params.ks_template_radius_um),
        create_arg('--catgt_run_name', run_name),
        create_arg('--probe_type', probe_type),
        create_arg('--gate_string', gate),
        create_arg('--trigger_string', triggers),
        create_arg('--probe_string', probe),
        create_arg('--catgt_stream_params', probe_stream_params),
        create_arg('--catgt_car_mode',  params.catgt_car_mode),
        create_arg('--catgt_loccar_min', params.catgt_loccar_min),
        create_arg('--catgt_loccar_max', params.catgt_loccar_max),
        create_arg('--catgt_cmd', probe_catgt_cmd),
        create_arg('--catgt_extract_string', probe_catgt_extract_string),
        create_arg('--catgt_output_dir', probe_catgt_output_dir),
        create_arg('--event_ex_param_str', params.event_ex_cmd_arg),
        create_arg('--c_waves_snr_um', params.c_waves_snr_um),
        create_arg('--ref_per_ms', probe_ref_per_ms),
        create_arg('--im_ex_list', im_ex_list),
        create_arg('--ni_ex_list', ni_ex_list),
        create_arg('--sync_period', params.sync_period),
        create_arg("--to_stream_sync_params", to_stream_sync_params),
        create_arg("--ni_stream_sync_params", ni_stream_sync_params)
    ]
    def args = args_list.join(' ')
    """
    umask 000
    mkdir -p ${probe_config_dir}
    python -m ecephys_spike_sorting.helpers.create_input_config ${args}
    """
}

process run_catgt {
    container { params.catgt_container }
    cpus { params.catgt_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)
          
    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'catGT_helper',
        probe_config_file,
        probe_folder_name,
        [
            'directories',
            'catGT_helper_params',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

process run_kilosort {
    container { params.kilosort_container }
    cpus { params.ks_cpus }
    accelerator 1
    label 'withGPU'

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'kilosort_helper',
        probe_config_file,
        probe_folder_name,
        [
            'kilosort_helper_params',
            'directories',
            'ephys_params',
            'common_files'
        ]
    )
    """
    ${code}
    """
}

process run_kilosort_post_process {
    container { params.ecephys_modules_container }
    cpus 1

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'kilosort_postprocessing',
        probe_config_file,
        probe_folder_name,
        [
            'ks_postprocessing_params',
            'directories',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

process run_noise_templates {
    container { params.ecephys_modules_container }
    cpus { params.noise_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'noise_templates',
        probe_config_file,
        probe_folder_name,
        [
            'noise_waveform_params',
            'directories',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

process run_mean_waveforms {
    container { params.cwaves_container }
    cpus { params.waveforms_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'mean_waveforms',
        probe_config_file,
        probe_folder_name,
        [
            'waveform_metrics',
            'mean_waveform_params',
            'cluster_metrics',
            'directories',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

process run_psth_events {
    container { params.ecephys_modules_container }
    cpus { params.events_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'psth_events',
        probe_config_file,
        probe_folder_name,
        [
            'psth_events',
            'directories',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

process run_quality_metrics {
    container { params.ecephys_modules_container }
    cpus { params.metrics_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          val(triggers)

    script:
    def code = create_code_block(
        'quality_metrics',
        probe_config_file,
        probe_folder_name,
        [
            'quality_metrics_params',
            'waveform_metrics',
            'cluster_metrics',
            'directories',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

process run_tprime {
    container { params.tprime_container }
    cpus { params.tprime_cpus }

    input:
    tuple val(run_config_file),
          val(run_folder_name),
          val(run_name)

    output:
    tuple val(run_config_file),
          val(run_folder_name),
          val(run_name)

    script:
    def code = create_code_block(
        'tPrime_helper',
        run_config_file,
        run_folder_name,
        [
            'tPrime_helper_params',
            'catGT_helper_params',
            'directories',
            'ephys_params'
        ]
    )
    """
    ${code}
    """
}

def create_arg(arg_flag, arg_value) {
    arg_value == null || "${arg_value}" == ''
        ? ''
        : "${arg_flag} ${arg_value}"
}

def create_bool_arg(arg_flag, arg_value) {
    arg_value ? arg_flag : ''
}

def create_code_block(module_name,
                      all_config_filename,
                      module_config_folder_name,
                      module_config_fields) {
    def config_dir = file(all_config_filename).parent
    def config = read_json(all_config_filename)
    def module_config = filter_config(config, module_config_fields)
    def module_input_file = config_file(config_dir, module_config_folder_name, module_name, 'input')
    write_json(module_config, module_input_file)
    def module_output_file = config_file(config_dir, module_config_folder_name, module_name, 'output')
    def ks_working_dir = config.directories.kilosort_output_tmp
    """
    umask 000
    mkdir -p ${ks_working_dir}
    echo python \
        -m ecephys_spike_sorting.modules.${module_name} \
        --input_json ${module_input_file} \
        --output_json ${module_output_file}
    """
}