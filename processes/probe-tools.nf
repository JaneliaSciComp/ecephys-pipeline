include {
    probe_str;
    probe_name;
    global_config;
} from '../lib/probe_utils'

include {
    read_json;
    write_json;
} from '../lib/utils'

process create_probe_config {
    container = params.ecephys_modules_container
    cpus 1

    input:
    tuple val(run_name),
          val(run_folder_name),
          val(probe_folder_name),
          val(probe_file),
          val(results_dir),
          val(config_dir),
          val(working_dir),
          val(output_name_prefix), // such as 'imec'
          val(output_name_suffix) // such as 'ks2'

    output:
    tuple val(run_folder_name),
          val(probe_folder_name),
          val(probe_file),
          val(probe_config_dir),
          val(probe_config_file),
          val(probe_results_dir)

    script:
    probe_config_dir = "${config_dir}/${run_folder_name}/${probe_folder_name}"
    probe_config_file = global_config(probe_config_dir, probe_folder_name)
    probe_results_dir = "${results_dir}/${run_folder_name}/${probe_folder_name}"
    args_list = [
        probe_file,
        probe_config_file,
        probe_results_dir,
        "--probe_working_path ${working_dir}/${probe_folder_name}",
        (params.ks_copy_results ? '--ks_copy_results' : ''),
        "--ks_ver ${params.ks_ver}",
        "--ks_csb_seed ${params.ks_csb_seed}",
        "--catgt_run_name ${run_name}",
    ]
    args = args_list.join(' ')
    """
    umask 000
    mkdir -p ${probe_config_dir}
    mkdir -p ${probe_results_dir}
    python -m ecephys_spike_sorting.helpers.create_input_config ${args}
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
    def config = read_json(config_file)
    def module_config = filter_config(config, module_config_attrs)
    def module_input_file = config_file(config_dir, pname, module_name, 'input')
    write_json(module_config, module_input_file)
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
