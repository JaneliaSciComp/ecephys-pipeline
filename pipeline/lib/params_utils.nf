def default_params() {
    params = [:]

    params.out = ''
    params.config = ''
    params.crepo = 'registry.int.janelia.org/janeliascicomp/'
    params.ecephys_version = '1.0'
    params.csb_seed = 101
    params.ks_working_dir = '/tmp/kilosort_datatemp'
    params.runtime_opts = ''

    return params
}

def get_params(Map params) {
    final_params = [:]

    final_params.input_path = params.in
    final_params.output_path = params.out != '' ? params.out : params.in
    final_params.config_path = params.config != '' ? params.config : final_params.output_path
    final_params.containersRepo = params.crepo == '' || params.crepo.endsWith('/') ? params.crepo : "${params.crepo}/"
    final_params.ecephys_version = params.ecephys_version == '' ? '' : ":${params.ecephys_version}"
    final_params.csb_seed = params.csb_seed
    final_params.ks_working_dir = params.ks_working_dir

    return final_params
}
