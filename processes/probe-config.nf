include {
    probe_str;
    probe_name;
    global_config;
} from '../lib/probe_utils'

process create_probe_config {
    container = params.ecephys_modules_container
    cpus { params.probe_config_cpus }

    input:
    tuple val(probe),
          val(probe_file),
          val(config_dir),
          val(output_dir),
          val(output_name_prefix), // such as 'imec'
          val(output_name_suffix), // such as 'ks2'
          val(working_dir)

    output:
    tuple val(probe), val(probe_file), val(probe_config_file), val(probe_output_dir)

    script:
    def pname = probe_name(probe)
    probe_config_file = global_config(config_dir, pname)
    def pstr = probe_str(probe)
    probe_output_dir = "${output_dir}/${pname}/${output_name_prefix}${pstr}${output_name_suffix}"
    def ks_copy_flag = params.ks_copy_results ? '--ks_copy_results' : ''
    """
    umask 000
    python \
        -m ecephys_spike_sorting.helpers.create_input_config \
        ${probe_file} \
        ${probe_config_file} \
        ${probe_output_dir} \
        --probe_working_path ${working_dir}/${pname} \
        ${ks_copy_flag} \
        --ks_ver ${params.ks_ver} \
        --ks_csb_seed ${params.ks_csb_seed} \
        --catgt_run_name ${params.catgt_run_name}
    """
}
