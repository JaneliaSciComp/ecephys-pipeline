
include {
    get_run_folder_name;
    get_probe_folder_name;
    get_probe_data_filename;
    global_config;
} from '../lib/probe_utils'

include {
    create_probe_config;
    run_cagt;
} from '../processes/probe-tools' addParams(params)

include {
    get_key_value_or_default_key;
    get_module_container;
} from '../lib/params_utils'

/**
* Process all probes from all given runs
*/
workflow process_probes_for_all_runs {
    take:
    data_dir
    results_dir
    config_dir
    working_dir
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
        def trigger = probe_input[5]
        def run_folder_name = get_run_folder_name(run_name, gate)
        def probe_folder_name = get_probe_folder_name(run_name, gate, probe)
        def probe_data_name = get_probe_data_filename(
            run_name,
            gate,
            probe,
            trigger,
            '.ap.bin'
        )
        def probe_meta_name = get_probe_data_filename(
            run_name,
            gate,
            probe,
            trigger,
            '.ap.meta'
        )
        def probe_data_file = "${data_dir}/${run_folder_name}/${probe_folder_name}/${probe_data_name}"
        def probe_meta_file = "${data_dir}/${run_folder_name}/${probe_folder_name}/${probe_meta_name}"
        def probe_config_file = global_config("${config_dir}/${run_folder_name}/${probe_folder_name}", probe_folder_name)
        def probe_ks_th = "'${get_key_value_or_default_key(params.ks_thresholds_by_region, region, 'default_value')}'"
        def probe_ref_per_ms = "'${get_key_value_or_default_key(params.ref_per_ms_by_region, region, 'default_value')}'"
        def probe_ks_output_dir = "${results_dir}/imec_${probe}_ks2"
        def probe_catgt_output_dir = "${results_dir}/${run_folder_name}/${probe_folder_name}"
        def probe_stream_params
        def probe_sync_extract_flags = "SY=${probe},${params.probe_sync_ch_values}"
        def probe_catgt_extract_string
        if (params.ni_present && probe_index == 0) {
            // if this is the first probe proceessed, process the ni stream with it
            probe_stream_params = "'ap -ni'" // this will be hyphenated by the config tool
            probe_catgt_extract_string = "'${probe_sync_extract_flags} ${params.ni_extract_cmd_args}'"
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
            probe_data_file,
            probe_meta_file,
            probe_config_file,
            run_folder_name,
            probe_folder_name,
            run_name,
            gate,
            probe,
            probe_ks_th,
            probe_ref_per_ms,
            probe_ks_output_dir,
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

    def cagt_input = probe_config_output 
    | map {
        println "!!!!!! IT: $it"
        def probe_step = 'catGT_helper'
        def run_this_step = probe_steps.contains(probe_step)
        def step_container = get_module_container(params, probe_step)
        def step_attrs = get_key_value_or_default_key(params.config_attrs_by_module, probe_step, 'default_value')
        def step_cpu = get_key_value_or_default_key(params.cpu_requirements_by_module, probe_step, 'default_value')
        def step_gpu = get_key_value_or_default_key(params.gpu_requirements_by_module, probe_step, 'default_value')
        println "!!!!!!! STEP $probe_step FOUND: $run_this_step, $step_container $step_attrs $step_cpu $step_gpu"
        def r = it + [ run_this_step ]
        println "!!!!!! R = $r"
        r
    }
    def cagt_output = run_cagt(cagt_input)

    // def ks_output = cagt_output 
    // | map {
    //     println "!!!!!! IT: $it"
    //     def probe_step = 'kilosort_helper'
    //     def run_this_step = probe_steps.contains(probe_step)
    //     def step_container = get_module_container(params, probe_step)
    //     def step_attrs = get_key_value_or_default_key(params.config_attrs_by_module, probe_step, 'default_value')
    //     def step_cpu = get_key_value_or_default_key(params.cpu_requirements_by_module, probe_step, 'default_value')
    //     def step_gpu = get_key_value_or_default_key(params.gpu_requirements_by_module, probe_step, 'default_value')
    //     println "!!!!!!! STEP $probe_step FOUND: $run_this_step, $step_container $step_attrs $step_cpu $step_gpu"
    //     it + [ run_this_step,
    //         step_container,
    //         step_attrs,
    //         step_cpu,
    //         step_gpu
    //     ]
    // } 

    emit:
    res = cagt_output
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
