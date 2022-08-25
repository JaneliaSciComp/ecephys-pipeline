import json
import os
import sys
import argparse
from .create_input_json import createInputJson
from . import SpikeGLX_utils


def main(argv):
    def hyphenated(arg):
        # hyphenate the argument because argparse does not support single hyphenated values
        if arg == '' or arg is None or arg.startswith('-'):
            return arg
        else:
            return '-' + arg

    parser = argparse.ArgumentParser(description='Create input json tool', allow_abbrev=False)

    parser.add_argument('--default_config_template',
                        default='/app/config/default_ecephys_config.json',
                        help='Config template')
    parser.add_argument('--npx_dir', help='Data directory')
    parser.add_argument('--probe_data', help='Probe data file')
    parser.add_argument('--probe_meta', help='Probe metadata file')
    parser.add_argument('--output_config_file', help='Output config file path')
    parser.add_argument('--kilosort_output_dir', help='Kilosort output directory')
    parser.add_argument('--ks_working_dir', default='/tmp/kilosort_datatemp', help='Kilosort working dir')
    parser.add_argument('--ks_ver', default='2.0', help='Kilosort version')
    parser.add_argument('--with_ks_filter', action='store_true', help='If set kilosort will perform LF filter')
    parser.add_argument('--ks_copy_results', action='store_true',
                        help='Make a copy of the kilosort results for postprocessing')
    parser.add_argument('--ks_remove_dups', type=int, help='Kilosort remove duplicates')
    parser.add_argument('--ks_save_rez', type=int, help='Kilosort save res')
    parser.add_argument('--ks_copy_fproc', type=int, help='Kilosort copy fproc')
    parser.add_argument('--ks_minfr_goodchannels', type=float, help='Kilosort min frame')
    parser.add_argument('--ks_whitening_radius_um', type=int)
    parser.add_argument('--ks_th')
    parser.add_argument('--ks_csb_seed', type=int, default=1, help='Run seed')
    parser.add_argument('--ks_lt_seed', type=int, default=1, help='Run seed')
    parser.add_argument('--ks_template_radius_um', type=int, default=1, help='Run seed')
    parser.add_argument('--ks_max_neighbors', type=int, default=64)

    parser.add_argument('--ks_mode', action='store_true', help='Use ClusterSinglrBatches')
    parser.add_argument('--ks_no_drift_registration', action='store_true',
                        help='No electrode drift estimation and no registration')
    parser.add_argument('--ks_sigma_mask', type=float, default=30, help='constant for residual variance')
    parser.add_argument('--ks_fshigh', type=float, default=150, help='high pass filter')
    parser.add_argument('--ks_fslow', type=float, help='low pass filter')
    parser.add_argument('--ks_car', action='store_true', help='common average referencing')
    parser.add_argument('--ks_no_temp_files', action='store_true', help='Do not save temp files')
    parser.add_argument('--ks_non_deterministic', action='store_true', help='Use a stochastic process')
    parser.add_argument('--ks_nblocks', type=int, default=5, help='number of blocks used to segment probe')
    parser.add_argument('--pyks_preproc', default='kilosort2', help='PyyKilosort preprocessing function')
    parser.add_argument('--pyks_alf', default='', help='ALF location')
    parser.add_argument('--catgt_run_name', help='CatGT run name')
    parser.add_argument('--probe_type')
    parser.add_argument('--gate_string', default='0')
    parser.add_argument('--trigger_string')
    parser.add_argument('--probe_string')
    parser.add_argument('--catgt_stream_params', type=hyphenated)
    parser.add_argument('--catgt_car_mode', default='gbldmx')
    parser.add_argument('--catgt_loccar_min', type=float)
    parser.add_argument('--catgt_loccar_max', type=float)
    parser.add_argument('--catgt_cmd', type=hyphenated)
    parser.add_argument('--catgt_extract_string', type=hyphenated)
    parser.add_argument('--catgt_output_dir')
    parser.add_argument('--event_ex_param_str')
    parser.add_argument('--c_waves_snr_um', type=float)
    parser.add_argument('--ref_per_ms', type=float)
    parser.add_argument('--include_pcs', action='store_true', help='Include PCS; if KS3.0 is used this arg is ignored')
    parser.add_argument('--im_ex_list', type=hyphenated)
    parser.add_argument('--ni_ex_list', type=hyphenated)
    parser.add_argument('--sync_period', type=float)
    parser.add_argument('--to_stream_sync_params')
    parser.add_argument('--ni_stream_sync_params')
    parser.add_argument('--ks_output_tag')

    args = parser.parse_args()

    with open(args.default_config_template) as default_config_file:
        default_config = json.load(default_config_file)

    npx_directory = args.npx_dir
    if npx_directory is None and args.probe_data is not None:
        npx_directory = os.path.dirname(args.probe_data)

    if args.catgt_cmd and args.catgt_extract_string:
        catGT_cmd_string=args.catgt_cmd + ' ' + args.catgt_extract_string
    elif args.catgt_cmd:
        catGT_cmd_string=args.catgt_cmd
    elif args.catgt_extract_string:
        catGT_cmd_string = args.catgt_extract_string
    else:
        catGT_cmd_string = None

    if args.ref_per_ms is not None:
        qm_isi_thresh = args.ref_per_ms/1000
    else:
        qm_isi_thresh = None

    if args.kilosort_output_dir is not None:
        kilosort_output_directory = args.kilosort_output_dir
    else:
        kilosort_output_directory = ''
    info = createInputJson(
        default_config,
        args.output_config_file,
        npx_directory=npx_directory, 
	    continuous_file=args.probe_data,
        input_meta_path=args.probe_meta,
        spikeGLX_data=True,
        # KS args
		kilosort_output_directory=kilosort_output_directory,
        ks_working_dir=args.ks_working_dir,
        ks_ver=args.ks_ver,
        ks_doFilter=(1 if args.with_ks_filter else 0),
        ks_make_copy=args.ks_copy_results,
        ks_remDup=args.ks_remove_dups,
        ks_finalSplits=1,
        ks_labelGood=1,
        ks_saveRez=args.ks_save_rez,
        ks_copy_fproc=args.ks_copy_fproc,
        ks_minfr_goodchannels=args.ks_minfr_goodchannels,
        ks_whiteningRadius_um=args.ks_whitening_radius_um,
        ks_Th=args.ks_th,
        ks_CSBseed=args.ks_csb_seed,
        ks_LTseed=args.ks_lt_seed,
        ks_templateRadius_um=args.ks_template_radius_um,
        ks_maxNeighbors=args.ks_max_neighbors,
        # PyKS args
        pyks_preprocessing_function=args.pyks_preproc,
        pyks_alf_location=args.pyks_alf,
        ks_mode=args.ks_mode,
        ks_drift_registration=not args.ks_no_drift_registration,
        ks_sigma_mask=args.ks_sigma_mask,
        ks_fshigh=args.ks_fshigh,
        ks_fslow=args.ks_fslow,
        ks_car=args.ks_car,
        ks_save_temp_files=not args.ks_no_temp_files,
        ks_deterministic=not args.ks_non_deterministic,
        ks_nblocks=args.ks_nblocks,
        # CatGT args
        extracted_data_directory=args.catgt_output_dir,
        catGT_run_name=args.catgt_run_name,
        probe_type=args.probe_type,
        gate_string=args.gate_string,
        trigger_string=args.trigger_string,
        probe_string=args.probe_string,
        catGT_stream_string=args.catgt_stream_params,
        catGT_car_mode=args.catgt_car_mode,
        catGT_loccar_min_um=args.catgt_loccar_min,
        catGT_loccar_max_um=args.catgt_loccar_max,
        catGT_cmd_string=catGT_cmd_string,
        # C_Waves args
        event_ex_param_str=args.event_ex_param_str,
        c_Waves_snr_um=args.c_waves_snr_um,
        qm_isi_thresh=qm_isi_thresh,
        include_pcs=args.include_pcs,
        # TPrime args
        tPrime_im_ex_list=args.im_ex_list,
        tPrime_ni_ex_list=args.ni_ex_list,
        sync_period=args.sync_period,
        toStream_sync_params=args.to_stream_sync_params,
        niStream_sync_params=args.ni_stream_sync_params,
        ks_output_tag=args.ks_output_tag,
        tPrime_3A=False,
        toStream_path_3A=' ',
        fromStream_list_3A=list()
    )
    print(info)


if __name__ == '__main__':
    main(sys.argv[1:])
