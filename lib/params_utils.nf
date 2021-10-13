include {
    read_json;
} from './utils'

def default_params() {
    [
        container_repo: 'registry.int.janelia.org/janeliascicomp',
        runtime_opts: '',
        lsf_opts: '',

        probe_config_json: '', // config template used for probe processing
        tprime_config_json: '', // config template used for tprime which aggregates all probes
        data_dir: '',
        results_dir: '',
        config_dir: '',
        runs: '',
        recordings: '',

        ref_per_ms_by_region: [
            default_value: 2.0,
            cortex: 2.0,
            medulla: 1.5,
            thalamus: 1.0,
        ],
        ks_thresholds_by_region: [
            default_value: '[9,9]',
            cortex: '[9,9]',
            medulla: '[9,9]',
            thalamus: '[9,9]',
        ],

        wait_for_config_sleep_secs: 2,
        wait_for_config_max_secs: 120,

        probe_type: 'NP1',
        probe_sync_ch_values: '-1,6,500', // used for building extract string for SYNC channel

        ks_csb_seed: 1,
        ks_lt_seed: 1,
        ks_copy_results: true,
        ks_ver: '3.0',
        ks_remove_dups: 0,
        ks_save_rez: 1,
        ks_copy_fproc: 0,
        ks_minfr_goodchannels: 0.1,
        ks_template_radius_um: 163,
        ks_whitening_radius_um: 163,
        ks_working_dir: '/tmp/kilosort_temp',

        process_lf: true, // this must be true if depth_estimation is run

        ni_present: true,
        ni_extract_cmd_args: '-XA=0,1,3,500 -XA=1,3,3,0 -XD=4,1,50 -XD=4,2,1.7 -XD=4,3,5',

        catgt_car_mode: 'gblcar', // must be 'None', 'gblcar', or 'loccar'
        catgt_cmd_args: '-prb_fld -out_prb_fld -apfilter=butter,12,300,10000 -gfix=0,0.10,0.02',
        catgt_loccar_min: 40,
        catgt_loccar_max: 160,

        event_ex_cmd_arg: 'XD=4,1,50',
        c_waves_snr_um: 160,

        catgt_cpus: 1,
        depth_estimation_cpus: 1,
        ks_cpus: 1,
        noise_cpus: 1,
        events_cpus: 1,
        waveforms_cpus: 1,
        metrics_cpus: 1,
        tprime_cpus: 1,

        sync_period: 1.0,
        has_aux_data: true,
        to_stream_sync_cmd_args: 'SY=0,-1,6,500', // SY=${probe_sync_ch_values}
        ni_stream_sync_cmd_args: 'XA=0,1,3,500',
    ]
}

def get_value_or_default(Map ps, String param, Object default_value) {
    if (ps[param])
        ps[param]
    else
        default_value
}

def get_list_or_default(Map ps, String param, List default_list) {
    def value
    if (ps[param])
        value = ps[param]
    else
        value = null
    return value
        ? value.tokenize(',').collect { it.trim() }
        : default_list
}

def get_map_or_default(Map ps, String param, Map default_map) {
    def value
    if (ps[param])
        value = ps[param]
    else
        value = null
    if (value instanceof Map) {
        return value
    } else if (value instanceof String) {
        return read_json(file(value))
    } else {
        return default_map
    }
}

def get_hyphenated_value_param(Map ps, String param) {
    def value = ps[param]
    if (value && value[0] != '-') {
        "-${value}"
    } else {
        value
    }
}

def catgt_modules_container_param(Map ps) {
    def catgt_container = ps.catgt_container
    if (!catgt_container)
        "${ps.container_repo}/catgt:1.0.1"
    else
        catgt_container
}

def cwaves_modules_container_param(Map ps) {
    def cwaves_container = ps.cwaves_container
    if (!cwaves_container)
        "${ps.container_repo}/cwaves:1.0.1"
    else
        cwaves_container
}

def ecephys_modules_container_param(Map ps) {
    def ecephys_modules_container = ps.ecephys_modules_container
    if (!ecephys_modules_container)
        "${ps.container_repo}/ecephys-modules:1.0.1"
    else
        ecephys_modules_container
}

def kilosort_container_param(Map ps) {
    def kilosort_container = ps.kilosort_container
    if (!kilosort_container)
        "${ps.container_repo}/kilosort:1.0.1"
    else
        kilosort_container
}

def tprime_modules_container_param(Map ps) {
    def tprime_container = ps.tprime_container
    if (!tprime_container)
        "${ps.container_repo}/tprime:1.0.1"
    else
        tprime_container
}

def get_key_value_or_default_key(Map m, Object k, Object default_key) {
    if (m.containsKey(k)) {
        m[k]
    } else {
        m[default_key]
    }
}
