def default_params() {
    params = [:]

    params.out = ''
    params.config = ''
    params.crepo = ''
    params.csb_seed = 101

    return params
}

def get_params(Map params) {
    final_params = [:]

    final_params.input_path = params.in
    final_params.output_path = params.out != '' ? params.out : params.in
    final_params.config_path = params.config != '' ? params.config : final_params.output_path
    final_params.containersRepo = params.crepo == '' || params.crepo.endsWith('/') ? params.crepo : "${params.crepo}/"
    final_params.csb_seed = params.csb_seed

    return final_params
}
