import os
import sys
import argparse
from .create_input_json import createInputJson
from . import SpikeGLX_utils


def main(argv):
    parser = argparse.ArgumentParser(description='Create input json tool')

    parser.add_argument('probe_path', help='Probe path')
    parser.add_argument('input_json', help='JSON input file path')
    parser.add_argument('output_path', help='Output path path')
    parser.add_argument('--ks_output_path', help='Kilosort output path')
    parser.add_argument('--csb_seed', type=int, default=1, help='Run seed')
    parser.add_argument('--ks_working_dir', 'Kilosort working directory')
    parser.add_argument('--ks_copy_results', action='store_true',
                        help='Make a copy of the kilosort results for postprocessing')

    args = parser.parse_args()

    npx_directory = os.path.dirname(args.probe_path)
    name = os.path.basename(args.probe_path)
    baseName = SpikeGLX_utils.ParseTcatName(name)

    info = createInputJson(args.input_json,
                           npx_directory=npx_directory,
                           continuous_file=os.path.join(npx_directory, name),
                           spikeGLX_data='True',
                           kilosort_output_directory=args.output_path,
                           ks_make_copy=args.ks_copy_results,
                           extracted_data_directory=npx_directory,
                           noise_template_use_rf=False,
                           CSBseed=args.csb_seed)
    print(info)


if __name__ == '__main__':
    main(sys.argv[1:])
