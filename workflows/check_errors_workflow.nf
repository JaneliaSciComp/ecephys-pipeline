include {
    check_module_output;
} from '../processes/probe_tools'

workflow check_errors {
    take:
    module_name
    input
    output

    main:
    def error_check_input = output
    | concat(input)
    | unique {
        def (probe_index, probe_data_file) = it
        return probe_data_file // use probe_data_file as the unique key
    }
    checked_output = check_module_output(module_name, error_check_input)

    errors_output = checked_output
    | filter {
      def errors_found = it[-1]
      return errors_found == 'true';
    }
    | map {
      it + [ module_name ]
    }

    emit:
    checked_output
    errors_output

}
