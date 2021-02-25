
workflow process_runs {
    take:
    npx_dir
    runs
    
    main:
    def probes_inputs = prepare_probes_input(npx_dir, runs)
    emit:
    res = probes_inputs
}

def prepare_probes_input(npx_dir, runs) {
    Channel.fromList(runs)
    | filter { it.probe_list } // only run specs with probes
    | flatMap { run_spec ->
        def run_folder_name = "${run_spec.name}_g${run_spec.gate}"
        def first_trigger = run_spec.triggers_range[0]
        def last_trigger = run_spec.triggers_range[1]
        if (first_trigger == -1 || last_trigger == -1) {
            def trials = get_probe_trials(npx_dir, run_spec.name, run_spec.gate, run_spec.probe_list.first())
            if (first_trigger == -1) {
                first_trigger = trials.min()
            }
            if (last_trigger == -1) {
                last_trigger = trials.max()
            }
        }
        
        run_spec.probe_list.collect { probe ->
            def probe_folder_name = "${run_folder_name}_imec${probe}"
            def probe_data_name = get_probe_data_filename(run_spec.name, run_spec.gate, first_trigger, probe, ".ap.bin")
            def probe_meta_name = get_probe_data_filename(run_spec.name, run_spec.gate, first_trigger, probe, ".ap.meta")
            [
                run_spec.name, // run name
                run_folder_name, // run folder
                probe_folder_name, // probe folder
                probe_data_name, // first probe data
                probe_meta_name,
                "${first_trigger},${last_trigger}",
                "${npx_dir}/${run_folder_name}/${probe_folder_name}/${probe_data_name}",
                "${npx_dir}/${run_folder_name}/${probe_folder_name}/${probe_meta_name}",
            ]
        }
    }
}

def get_probe_trials(npx_dir, run_name, gate, probe) {
    def run_folder_name = "${run_name}_g${gate}"
    def probe_folder_name = "${run_folder_name}_imec${probe}"
    def probe_trials_dir = file("${npx_dir}/${run_folder_name}/${probe_folder_name}")
    def pfile_pattern = java.util.regex.Pattern.compile("${run_folder_name}_t(\\d+).imec${probe}.ap.bin")
    def trials = []
    probe_trials_dir.eachFileMatch(pfile_pattern) { f ->
        def match_res = f.name =~ pfile_pattern
        trials << (match_res[0][1] as int)
    }
    return trials
}

def get_probe_data_filename(run_name, gate, trigger, probe, file_ext) {
    def run_folder_name = "${run_name}_g${gate}"
    "${run_folder_name}_t${trigger}.imec${probe}${file_ext}"
}
