
include {
    get_run_folder_name;
    get_probe_folder_name;
    get_probe_data_filename;
    global_config;
} from '../lib/probe_utils'

include {
    create_probe_config;
    run_catgt;
    run_kilosort;
    run_kilosort_post_process;
    run_noise_templates;
    run_mean_waveforms;
    run_psth_events;
    run_quality_metrics;
    run_tprime;
} from '../processes/probe-tools' addParams(params)

include {
    get_key_value_or_default_key;
} from '../lib/params_utils'

include {
    index_channel;
} from '../lib/utils'

/**
* Process all probes from all given runs
*/
workflow process_probes_for_all_runs {
    take:
    data_dir
    results_dir
    config_dir
    runs
    probe_steps
    
    main:
    def probes_inputs = prepare_probes_input(data_dir, runs)
    def probe_config_output = probes_inputs
    | map { probe_input ->
        def probe_index = probe_input[0]
        def run_name = probe_input[1]
        def gate = probe_input[2]
        def probe = probe_input[3]
        def region = probe_input[4]
        def first_trigger = probe_input[5]
        def last_trigger = probe_input[6]
        def triggers = "${first_trigger}:${last_trigger}"
        def run_folder_name = get_run_folder_name(run_name, gate)
        def probe_folder_name = get_probe_folder_name(run_name, gate, probe)
        def probe_data_name = get_probe_data_filename(
            run_name,
            gate,
            probe,
            first_trigger,
            '.ap.bin'
        )
        def probe_meta_name = get_probe_data_filename(
            run_name,
            gate,
            probe,
            first_trigger,
            '.ap.meta'
        )
        def probe_data_dir = "${data_dir}/${run_folder_name}/${probe_folder_name}"
        def probe_data_file = "${probe_data_dir}/${probe_data_name}"
        def probe_meta_file = "${probe_data_dir}/${probe_meta_name}"
        def probe_config_file = global_config("${config_dir}/${run_folder_name}/${probe_folder_name}", probe_folder_name)
        def probe_ks_th = "'${get_key_value_or_default_key(params.ks_thresholds_by_region, region, 'default_value')}'"
        def probe_ref_per_ms = "'${get_key_value_or_default_key(params.ref_per_ms_by_region, region, 'default_value')}'"
        def probe_ks_output_dir = "${results_dir}/${probe_folder_name}/imec_${probe}_ks2"
        def probe_ks_working_dir = "${params.ks_working_dir}/${probe_folder_name}"
        def probe_catgt_output_dir = "${results_dir}/${run_folder_name}/${probe_folder_name}"
        def probe_stream_params
        def probe_sync_extract_flags = "SY=${probe},${params.probe_sync_ch_values}"
        def probe_catgt_extract_string
        if (params.ni_present && probe_index == 0) {
            // if this is the first probe proceessed, process the ni stream with it
            probe_stream_params = "'ap -ni'" // this will be hyphenated by the config tool
            probe_catgt_extract_string = "'${probe_sync_extract_flags} -${params.ni_extract_cmd_args}'"
        } else {
            probe_stream_params = 'ap' // this will be hyphenated by the config tool
            probe_catgt_extract_string = "'${probe_sync_extract_flags}'"
        }
        def probe_catgt_cmd = "'${params.catgt_cmd_args}'"
        def im_ex_list = ''
        def ni_ex_list = "'${params.ni_extract_cmd_args}'"
        def to_stream_sync_params = params.to_stream_sync_cmd_args
        def ni_stream_sync_params = params.has_aux_data ? params.ni_stream_sync_cmd_args : ''
        def r = [
            data_dir,
            probe_data_file,
            probe_meta_file,
            probe_config_file,
            run_folder_name,
            probe_folder_name,
            run_name,
            gate,
            probe,
            triggers,
            probe_ks_th,
            probe_ref_per_ms,
            probe_ks_output_dir,
            probe_ks_working_dir,
            probe_catgt_output_dir,
            probe_stream_params,
            probe_catgt_cmd,
            probe_catgt_extract_string,
            im_ex_list,
            ni_ex_list,
            to_stream_sync_params,
            ni_stream_sync_params,
        ]
        log.debug "Probe config params: $r"
        r
    }
    | create_probe_config

    def catgt_input = probe_config_output 
    def catgt_output
    if (probe_steps.contains('catGT_helper')) {
        catgt_output = catgt_input | run_catgt
    } else {
        catgt_output = catgt_input
    }

    def ks_input = catgt_output
    def ks_output
    if (probe_steps.contains('kilosort_helper')) {
        if (probe_steps.contains('kilosort_postprocessing')) {
            ks_output = ks_input | run_kilosort | run_kilosort_post_process
        } else {
            ks_output = ks_input | run_kilosort
        }
    } else {
        ks_output = ks_input
    }

    def noise_templates_input = ks_output
    def noise_templates_output
    if (probe_steps.contains('noise_templates')) {
        noise_templates_output = noise_templates_input | run_noise_templates
    } else {
        noise_templates_output = noise_templates_input
    }

    def psth_events_input = noise_templates_output
    def psth_events_output
    if (probe_steps.contains('psth_events')) {
        psth_events_output = psth_events_input | run_psth_events
    } else {
        psth_events_output = psth_events_input
    }

    def mean_waveforms_input = psth_events_output
    def mean_waveforms_output
    if (probe_steps.contains('mean_waveforms')) {
        mean_waveforms_output = mean_waveforms_input | run_mean_waveforms
    } else {
        mean_waveforms_output = psth_events_input
    }

    def quality_metrics_input = mean_waveforms_output
    def quality_metrics_output
    if (probe_steps.contains('quality_metrics')) {
        quality_metrics_output = quality_metrics_input | run_quality_metrics
    } else {
        quality_metrics_output = psth_events_input
    }

    emit:
    res = quality_metrics_output
}

workflow process_tprime {
    take:
    data_dir
    results_dir
    config_dir
    run_folder_name_input
    run_name_input
    gate_input
    probes_input
    triggers_input

    main:
    def tprime_output = index_channel(run_folder_name_input)
    | join(index_channel(run_name_input))
    | join(index_channel(gate_input))
    | join(index_channel(probes_input))
    | join(index_channel(triggers_input))
    | map {
        println "!!! $it"
        def run_folder_name = it[1]
        def run_name = it[2]
        def gate = it[3]
        def probes = it[4]
        def triggers = it[5]

        def probes_sync_ch_args = probes.withIndex()
            .collect { prbIdxPair ->
                def prb = prbIdxPair[0]
                def index = prbIdxPair[1]
                def dashPrefix = index == 0 ? '' : '-'
                "${dashPrefix}SY=${prb},${params.probe_sync_ch_values}"
            }
            .join(' ')
        def im_ex_list = "'${probes_sync_ch_args}'"
        def ni_ex_list = "'${params.ni_extract_cmd_args}'"
        def run_data_dir = "${data_dir}/${run_folder_name}"
        def run_config_file = global_config("${config_dir}/${run_folder_name}", run_folder_name)

        def r = [
            run_data_dir,
            '', // probe_data_file
            '', // probe_meta_file
            run_config_file,
            run_folder_name,
            '', // probe_folder_name
            run_name,
            gate,
            '', // probe
            triggers,
            '',
            '', // probe_ref_per_ms
            run_data_dir, // ks_output_dir
            params.ks_working_dir, // ks_working_dir
            run_data_dir,//  catgt_output_dir,
            '', // probe_stream_params
            '', // probe_catgt_cmd
            '', // probe_catgt_extract_string
            im_ex_list,
            ni_ex_list, // ni_ex_list
            '', // to_stream_sync_params
            '', // ni_stream_sync_params
        ]
        log.debug "TPrime config params: $r"
        r
    }
    | create_probe_config
    | map {
        [
            it[1], // run_config_file
            it[2], // run_folder_name
            it[4], // run_name
        ]
    }
    | run_tprime

    emit:
    res = tprime_output
}

def prepare_probes_input(data_dir, runs) {
    Channel.fromList(runs)
    | filter { it.probe_list } // only run specs with probes
    | flatMap { run_spec ->
        def run_folder_name = "${run_spec.name}_g${run_spec.gate}"
        def first_trigger = run_spec.triggers_range[0]
        def last_trigger = run_spec.triggers_range[1]
        if (first_trigger == -1 || last_trigger == -1) {
            def trials = get_probe_trials(data_dir, run_spec.name, run_spec.gate, run_spec.probe_list.first())
            if (first_trigger == -1) {
                first_trigger = trials.min()
            }
            if (last_trigger == -1) {
                last_trigger = trials.max()
            }
        }
        [ run_spec.probe_list, run_spec.probe_region_list]
            .transpose()
            .withIndex()
            .collect {
                def probe = it[0][0]
                def region =  it[0][1]
                def probe_index = it[1]
                [
                    probe_index,
                    run_spec.name, // run name
                    run_spec.gate, // gate
                    probe, // probe
                    region, // region
                    first_trigger, // first trigger
                    last_trigger // last trigger
                ]
            }
    }
}

def get_probe_trials(data_dir, run_name, gate, probe) {
    def run_folder_name = "${run_name}_g${gate}"
    def probe_folder_name = "${run_folder_name}_imec${probe}"
    def probe_trials_dir = file("${data_dir}/${run_folder_name}/${probe_folder_name}")
    def pfile_pattern = java.util.regex.Pattern.compile("${run_folder_name}_t(\\d+).imec${probe}.ap.bin")
    def trials = []
    probe_trials_dir.eachFileMatch(pfile_pattern) { f ->
        def match_res = f.name =~ pfile_pattern
        trials << (match_res[0][1] as int)
    }
    return trials
}
