include {
    extract_basename;
    extract_gate;
    extract_probe;
    get_kilosort_helper_module;
    global_config;
    processingErrorsFoundClosure;
} from '../lib/probe_utils'

include {
    create_probe_config;
    run_kilosort;
    run_kilosort_post_process;
    run_noise_templates;
    run_mean_waveforms;
    run_psth_events;
    run_quality_metrics;
    wait_for_config;
} from '../processes/probe_tools'

include {
    get_key_value_or_default_key;
} from '../lib/params_utils'

include {
    check_errors as check_ks_errors;
    check_errors as check_ks_post_errors;
    check_errors as check_noise_errors;
    check_errors as check_psth_errors;
    check_errors as check_mean_waveforms_errors;
    check_errors as check_quality_errors;
} from './check_errors_workflow'

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
        def config_name = "${recording_basename}_${params.sort_out_tag}"
        def recording_config_file = global_config(config_dir, config_name)      
        def gate = extract_gate(recording_name)
        def probe = extract_probe(recording_name)
        def ks_output_dir = "${results_dir}/${recording_basename}/imec${probe}_${params.sort_out_tag}"
        //def probe_ks_output_dir = "${results_dir}/catgt_${run_folder_name}/${probe_folder_name}/imec${probe}_${params.sort_out_tag}"
        def ks_th = "'${get_key_value_or_default_key(params.ks_thresholds_by_region, region, 'default_value')}'"
        def ref_per_ms = "'${get_key_value_or_default_key(params.ref_per_ms_by_region, region, 'default_value')}'"
        def rec_ks_working_dir = "${params.ks_working_dir}/${recording_name}_${params.sort_out_tag}"
	    def sort_out_tag = params.sort_out_tag

        def r = [
            -1,  // there's no probe index
            params.probe_config_json,
            recording_dir,
            recording_bin_file,
            recording_meta_file,
            recording_config_file,
            '', // run_folder_name,
            config_name,   //used to name the config files
            recording_basename,
            gate, // gate
            probe,
            '', // triggers
            '', // probe_type
            ks_th,
            ref_per_ms,
            ks_output_dir,
            rec_ks_working_dir,
            results_dir, //  catgt_output_dir
            '', // probe_stream_params
            '', // probe_catgt_cmd
            '', // probe_catgt_extract_string
            '', // im_ex_list
            '', // ni_ex_list
            '', // to_stream_sync_params
            '', // ni_stream_sync_params
	        sort_out_tag, 
        ]
        log.debug "Recording config params: $r"
        r
    }
    | create_probe_config
    | wait_for_config

    def errors_output = Channel.of()

    def ks_input = config_output
    def ks_output
    if (steps.contains('kilosort_helper')) {
        def process_input = ks_input | filter(processingErrorsFoundClosure('Kilosort'))
        def process_output = process_input | run_kilosort
        def process_errors

        (ks_output, process_errors) = check_ks_errors(get_kilosort_helper_module(params.with_pyks, params.with_ks4), process_input, process_output)
        errors_output = errors_output.concat(process_errors)
    } else {
        ks_output = ks_input
    }

    def ks_post_input = ks_output
    def ks_post_output
    if (steps.contains('kilosort_postprocessing')) {
        def process_input = ks_post_input | filter(processingErrorsFoundClosure('Kilosort PostProcess'))
        def process_output = process_input | run_kilosort_post_process
        def process_errors

        (ks_post_output, process_errors) = check_ks_post_errors('kilosort_postprocessing', process_input, process_output)
        errors_output = errors_output.concat(process_errors)
    } else {
        ks_post_output = ks_post_input
    }

    def noise_templates_input = ks_post_output
    def noise_templates_output
    if (steps.contains('noise_templates')) {
        def process_input = noise_templates_input | filter(processingErrorsFoundClosure('Noise templates'))
        def process_output = process_input | run_noise_templates
        def process_errors

        (noise_templates_output, process_errors) = check_noise_errors('noise_templates', process_input, process_output)
        errors_output = errors_output.concat(process_errors)
    } else {
        noise_templates_output = noise_templates_input
    }

    def psth_events_input = noise_templates_output
    def psth_events_output
    if (steps.contains('psth_events')) {
        def process_input = psth_events_input | filter(processingErrorsFoundClosure('PSTH Events'))
        def process_output = process_input | run_psth_events
        def process_errors

        (psth_events_output, process_errors) = check_psth_errors('psth_events', process_input, process_output)
        errors_output = errors_output.concat(process_errors)
    } else {
        psth_events_output = psth_events_input
    }

    def mean_waveforms_input = psth_events_output
    def mean_waveforms_output
    if (steps.contains('mean_waveforms')) {
        def process_input = mean_waveforms_input | filter(processingErrorsFoundClosure('Mean Waveforms'))
        def process_output = process_input | run_mean_waveforms
        def process_errors

        (mean_waveforms_output, process_errors) = check_mean_waveforms_errors('mean_waveforms', process_input, process_output)
        errors_output = errors_output.concat(process_errors)
    } else {
        mean_waveforms_output = mean_waveforms_input
    }

    def quality_metrics_input = mean_waveforms_output
    def quality_metrics_output
    if (steps.contains('quality_metrics')) {
        def process_input = quality_metrics_input | filter(processingErrorsFoundClosure('Quality Metrics'))
        def process_output = process_input | run_quality_metrics
        def process_errors

        (quality_metrics_output, process_errors) = check_quality_errors('quality_metrics', process_input, process_output)
        errors_output = errors_output.concat(process_errors)
    } else {
        quality_metrics_output = quality_metrics_input
    }

    emit:
    res = quality_metrics_output
    errors = errors_output
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
