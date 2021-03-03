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
    tuple val(probe_data_file),
          val(probe_meta_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe),
          // region specific parameters
          val(probe_ks_th),
          val(probe_ref_per_ms),
          // kilosort
          val(probe_ks_output_dir),
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
          val(probe)

    script:
    def probe_config_dir = file(probe_config_file).parent
    args_list = [
        '--probe_data', probe_data_file,
        '--probe_meta', probe_meta_file, 
        '--output_config_file', probe_config_file,
        '--kilosort_output_dir', probe_ks_output_dir,
        '--ks_ver', params.ks_ver,
        (params.ks_copy_results ? '--ks_copy_results' : ''),
        '--ks_remove_dups', params.ks_remove_dups,
        '--ks_save_rez', params.ks_save_rez,
        '--ks_copy_fproc', params.ks_copy_fproc,
        '--ks_minfr_goodchannels', params.ks_minfr_goodchannels,
        '--ks_whitening_radius_um', params.ks_whitening_radius_um,
        '--ks_th', probe_ks_th,
        '--ks_csb_seed', params.ks_csb_seed,
        '--ks_lt_seed', params.ks_lt_seed,
        '--ks_template_radius_um', params.ks_template_radius_um,
        '--catgt_run_name', run_name,
        '--gate', gate,
        '--probe', probe,
        '--catgt_stream_params', probe_stream_params,
        '--catgt_car_mode',  params.catgt_car_mode,
        '--catgt_loccar_min', params.catgt_loccar_min,
        '--catgt_loccar_max', params.catgt_loccar_max,
        '--catgt_cmd', probe_catgt_cmd,
        '--catgt_extract_string', probe_catgt_extract_string,
        '--catgt_output_dir', probe_catgt_output_dir,
        '--event_ex_param_str', params.event_ex_cmd_arg,
        '--c_waves_snr_um', params.c_waves_snr_um,
        '--ref_per_ms', probe_ref_per_ms,
        (im_ex_list ? "--im_ex_list ${im_ex_list}" : ''),
        (ni_ex_list ? "--ni_ex_list ${ni_ex_list}" : ''),
        '--sync_period', params.sync_period,
        (to_stream_sync_params ? "--to_stream_sync_params ${to_stream_sync_params}" : ''),
        (ni_stream_sync_params ? "--ni_stream_sync_params ${ni_stream_sync_params}" : ''),
    ]
    args = args_list.join(' ')
    """
    umask 000
    mkdir -p ${probe_config_dir}
    python -m ecephys_spike_sorting.helpers.create_input_config ${args}
    """
}

process run_cagt {
    container { params.catgt_container }
    cpus { params.catgt_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe)
          
    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe)

    script:
    def config = read_json(probe_config_file)
    def module_config = filter_config(config, [
        'directories',
        'catGT_helper_params',
        'ephys_params'
    ])
    def probe_config_dir = file(probe_config_file).parent
    def module_input_file = config_file(probe_config_dir, probe_folder_name, 'cagt', 'input')
    write_json(module_config, module_input_file)
    def module_output_file = config_file(probe_config_dir, probe_folder_name, 'cagt', 'output')
    """
    umask 000
    echo python \
        -m ecephys_spike_sorting.modules.catGT_helper \
        --input_json ${module_input_file} \
        --output_json ${module_output_file}
    """
}

process run_kilosort {
    container { params.kilosort_container }
    cpus { params.ks_cpus }

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe)

    script:
    def config = read_json(probe_config_file)
    def module_config = filter_config(config, [
        'kilosort_helper_params',
        'directories',
        'ephys_params',
        'common_files'
    ])
    def probe_config_dir = file(probe_config_file).parent
    def module_input_file = config_file(probe_config_dir, probe_folder_name, 'kilosort', 'input')
    write_json(module_config, module_input_file)
    def module_output_file = config_file(probe_config_dir, probe_folder_name, 'kilosort', 'output')
    """
    umask 000
    echo python \
        -m ecephys_spike_sorting.modules.kilosort_helper \
        --input_json ${module_input_file} \
        --output_json ${module_output_file}
    """
}
process run_kilosort_post_process {
    container { params.kilosort_container }
    cpus 1

    input:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe)

    output:
    tuple val(probe_data_file),
          val(probe_config_file),
          val(run_folder_name),
          val(probe_folder_name),
          val(run_name),
          val(gate),
          val(probe)

    script:
    def config = read_json(probe_config_file)
    def module_config = filter_config(config, [
        'ks_postprocessing_params',
        'directories',
        'ephys_params'
    ])
    def probe_config_dir = file(probe_config_file).parent
    def module_input_file = config_file(probe_config_dir, probe_folder_name, 'kilosort', 'input')
    write_json(module_config, module_input_file)
    def module_output_file = config_file(probe_config_dir, probe_folder_name, 'kilosort', 'output')
    """
    umask 000
    echo python \
        -m ecephys_spike_sorting.modules.kilosort_postprocessing \
        --input_json ${module_input_file} \
        --output_json ${module_output_file}
    """
}
