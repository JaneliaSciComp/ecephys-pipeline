include {
    probe_str;
    probe_name;
    global_config;
    read_config;
    write_config;
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

process run_module {
    container { module_container }
    cpus { module_cpus }
    label { with_gpu ? 'withGPU' : 'noGPU' }

    input:
    tuple val(probe), 
          val(probe_file),
          val(config_dir),
          val(working_dir),
          val(module_name),
          val(module_container),
          val(module_config_attrs),
          val(module_cpus),
          val(with_gpu)

    output:
    tuple val(probe),
          val(probe_file),
          val(module_input_file),
          val(module_output_file)

    script:
    def pname = probe_name(probe)
    def config_file = global_config(config_dir, pname)
    def config = read_config(config_file)
    def module_config = filter_config(config, module_config_attrs)
    def module_input_file = config_file(config_dir, pname, module_name, 'input')
    write_config(module_config, module_input_file)
    module_output_file = config_file(config_dir, pname, module_name, 'output')
    """
    umask 000
    mkdir -p ${working_dir}/${pname}
    python \
        -m ecephys_spike_sorting.modules.${module_name} \
        --input_json ${module_input_file} \
        --output_json ${module_output_file}
    """
}
