include {
    extract_basename;
    extract_probe;
    global_config;
} from '../lib/probe_utils'

include {
    create_probe_config;
    wait_for_config;
} from '../processes/probe-tools'

include {
    get_key_value_or_default_key;
} from '../lib/params_utils'

/**
* Process all recordings
*/
workflow process_all_recordings {
    take:
    results_dir
    config_dir
    recordings
    steps

    main:
    def recordings_inputs = prepare_recordings_inputs(recordings)
    def config_output = recordings_inputs
    | map { recording_input ->
        def recording_bin_file = file(recording_input[0])
        def region = recording_input[1]
        def recording_dir = recording_bin_file.parent
        def recording_name = recording_bin_file.name
        def ext_index = recording_name.lastIndexOf('.')
        def recording_meta_file
        if (ext_index == -1) {
            recording_meta_file = "${recording_dir}/${recording_name}.meta"
        } else {
            recording_meta_file = "${recording_dir}/${recording_name.substring(0,ext_index)}.meta"
        }
        def recording_basename = extract_basename(recording_name)
        def recording_config_file = global_config(config_dir, recording_basename)
        def probe = extract_probe(recording_name)
        def ks_output_dir = "${results_dir}/${recording_basename}/imec${probe}_ks2"
        def ks_working_dir = "${params.ks_working_dir}/${recording_basename}_imec${probe}_ks2"
        def ks_th = "'${get_key_value_or_default_key(params.ks_thresholds_by_region, region, 'default_value')}'"
        def ref_per_ms = "'${get_key_value_or_default_key(params.ref_per_ms_by_region, region, 'default_value')}'"

        def r = [
            recording_dir,
            recording_bin_file,
            recording_meta_file,
            recording_config_file,
            '', // run_folder_name,
            "${recording_basename}_imec${probe}",
            recording_basename,
            '', // gate
            probe,
            '', // triggers
            '', // probe_type
            ks_th,
            ref_per_ms,
            ks_output_dir,
            ks_working_dir,
            results_dir, //  catgt_output_dir
            '', // probe_stream_params
            '', // probe_catgt_cmd
            '', // probe_catgt_extract_string
            '', // im_ex_list
            '', // ni_ex_list
            '', // to_stream_sync_params
            '', // ni_stream_sync_params
        ]
        log.debug "Recording config params: $r"
        r
    }
    | create_probe_config
    | wait_for_config

    def ks_input = config_output
    def ks_output
    if (probe_steps.contains('kilosort_helper')) {
        ks_output = ks_input | run_kilosort
    } else {
        ks_output = ks_input
    }

    def ks_post_input = ks_output
    def ks_post_output
    if (probe_steps.contains('kilosort_postprocessing')) {
        ks_post_output = ks_post_input | run_kilosort_post_process
    } else {
        ks_post_output = ks_post_input
    }

    emit:
    done = config_output
}

def prepare_recordings_inputs(recordings) {
    Channel.fromList(recordings)
    | map { recording_spec ->
        [
            recording_spec.recording_path,
            recording_spec.region,
        ]
    }
}
