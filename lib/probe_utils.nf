def extract_probe(tcat_name) {
    def tcat_index = tcat_name.indexOf('_tcat')
    def tcat_name_parts
    if (tcat_index == -1) {
        tcat_name_parts = tcat_name.split("\\.")
    } else {
        tcat_name_parts = tcat_name.substring(tcat_index).split("\\.")
    }
    if (tcat_name_parts.size() > 1) {
        def im_str = tcat_name_parts[1]
        if (im_str.length() <= 4)
            return ''   // 3A data, no probe index
        else
            return im_str.substring(4)
    } else
        return ''
}

/**
* Extracts the recording name by dropping the .ap.{bin|meta} and _tcat
*/
def extract_basename(tcat_name) {
    def tcat_name_parts = tcat_name.split('\\.')
    tcat_name_parts
        .findAll {
            it != 'ap' && it != 'bin' && it != 'meta'
        }
        .collect {
            it.replace('_tcat', '')
        }.join('_')
}

def global_config(config_dir, pname) {
    return config_file(config_dir, pname, 'all', 'config')
}

def config_file(config_dir, pname, step, type) {
    return file("${config_dir}/${pname}-${step}-${type}.json")
}

def filter_config(config, fields) {
    return config.subMap(fields)
}

// Each run_spec is a list of 4 strings:
//   undecorated run name (no g/t specifier, the run field in CatGT)
//   gate index, as a string (e.g. '0')
//   triggers to process/concatenate, as a string e.g. '0,400', '0,0 for a single file
//           can replace first limit with 'start', last with 'end'; 'start,end'
//           will concatenate all trials in the probe folder
//   probes to process, as a string, e.g. '0', '0,3', '0:3'
//   brain regions, list of strings, one per probe, to set region specific params
//           these strings must match a key in the param dictionaries above.
// [
//    {
//       "name": "SC024_092319_NP1.0_Midbrain",
//       "gateIndex": "0",
//       "triggers": "0,9",
//       "probes": "0,1",
//       "regions": [ "cortex", "medulla" ]
//    }
// ]
def prepare_run_specs(run_specs) {
    run_specs.collect { run_entry ->
        [
            name: run_entry.name,
            gate: run_entry.gateIndex,
            probe_list: parse_probe_list(run_entry.probes),
            triggers_range: parse_triggers(run_entry.triggers),
            probe_region_list: run_entry.regions, // there must be one region for each entry from probe_list
        ]
    }
}

def parse_probe_list(pstr) {
    def pstr_elems = pstr.tokenize(',')
    def probe_list = []
    pstr_elems.each { probe ->
        if (probe.indexOf(':') != -1) {
            def range_parts = probe.split(':')
            def s = range_parts[0] as int
            def e = range_parts[1] as int
            probe_list.addAll(s..(e+1))
        } else {
            probe_list << (probe as int)
        }
    }
    probe_list
}

def parse_triggers(tstr) {
    def trigger_boundaries = tstr.split(',')
    def start_elem = trigger_boundaries[0]
    def end_elem = trigger_boundaries[1]
    def start = start_elem == 'start' ? -1 : start_elem as int
    def end = end_elem == 'end' ? -1 : end_elem as int
    return [start, end]
}

// Each recording specify the full path to the binary and the region
// [
//    {
//       "binaryLocation": "/test_data/SC011_022319_g0_tcat.imec3.ap.bin",
//       "region": "default"
//    }
// ]
def prepare_recording_specs(recording_specs) {
    recording_specs.collect { recording_entry ->
        [
            recording_path: recording_entry.binaryLocation,
            region: recording_entry.region,
        ]
    }
}

def get_run_folder_name(run_name, gate) {
    "${run_name}_g${gate}"
}

def get_probe_folder_name(run_name, gate, probe) {
    def run_folder_name = get_run_folder_name(run_name, gate)
    "${run_folder_name}_imec${probe}"
}

def get_probe_data_filename(run_name, gate, probe, trigger, file_type) {
    def run_folder_name = get_run_folder_name(run_name, gate)
    "${run_folder_name}_t${trigger}.imec${probe}${file_type}"
}
