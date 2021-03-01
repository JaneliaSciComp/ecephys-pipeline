
include {
    get_run_folder_name;
    get_probe_folder_name;
    get_probe_data_filename;
} from '../lib/probe_utils'

include {
    create_probe_config;
} from '../processes/probe-tools' addParams(params)

workflow process_runs {
    take:
    data_dir
    results_dir
    config_dir
    working_dir
    runs
    
    main:
    def probes_inputs = prepare_probes_input(data_dir, runs)
    def probe_config = probes_inputs 
    | map { probe_input ->
        def run_name = probe_input[0]
        def gate = probe_input[1]
        def probe = probe_input[2]
        def trigger = probe_input[4]
        def run_folder_name = get_run_folder_name(run_name, gate)
        def probe_folder_name = get_probe_folder_name(run_name, gate, probe)
        def probe_data_file = get_probe_data_filename(
            run_name,
            gate,
            probe,
            trigger,
            '.ap.bin'
        )
        def probe_meta_file = get_probe_data_filename(
            run_name,
            gate,
            probe,
            trigger,
            '.ap.meta'
        )
        [
            run_name,
            run_folder_name,
            probe_folder_name,
            "${data_dir}/${run_folder_name}/${probe_folder_name}/${probe_data_file}",
            results_dir,
            config_dir,
            working_dir,
            'imec',
            'ks2',
        ]
    } | create_probe_config
    emit:
    res = probe_config
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
            .collect {
                def probe = it[0]
                def region =  it[1]
                [
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
    println "!!! data dir $data_dir"
    println "!!! dir $probe_trials_dir"
    def pfile_pattern = java.util.regex.Pattern.compile("${run_folder_name}_t(\\d+).imec${probe}.ap.bin")
    def trials = []
    probe_trials_dir.eachFileMatch(pfile_pattern) { f ->
        def match_res = f.name =~ pfile_pattern
        trials << (match_res[0][1] as int)
    }
    return trials
}
