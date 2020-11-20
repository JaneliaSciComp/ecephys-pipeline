import os
import io
import json
import glob
import sys

if sys.platform == 'linux':
    import pwd
from . import SpikeGLX_utils


def createInputJson(output_file,
                    npx_directory=None,
                    continuous_file=None,
                    spikeGLX_data=True,
                    extracted_data_directory=None,
                    kilosort_output_directory=None,
                    ks_make_copy=False,
                    probe_type='3A',
                    catGT_run_name=None,
                    gate_string='0',
                    trigger_string='0,0',
                    probe_string='0',
                    catGT_stream_string='-ap',
                    catGT_cmd_string='-prb_fld -out_prb_fld -aphipass=300 -gbldmx -gfix=0.40,0.10,0.02',
                    catGT_gfix_edits=0,
                    noise_template_use_rf=True,
                    event_ex_param_str='XD=4,1,50',
                    sync_period=1.0,
                    toStream_sync_params='SY=0,384,6,500',
                    niStream_sync_params='XA=0,1,3,500',
                    toStream_path_3A=None,
                    fromStream_list_3A=None,
                    minfr_goodchannels=0.1,
                    whiteningRange=32,
                    CSBseed=1,
                    LTseed=1,
                    nNeighbors=32
                    ):

    # hard coded paths to code on your computer and system
    ecephys_directory = r'/app/ecephys_spike_sorting/ecephys_spike_sorting'
    kilosort_repository = r'/app/kilosort2'
    npy_matlab_repository = r'/app/npy-matlab'
    catGTPath = r'/app/CatGT'
    tPrime_path = r'/app/TPrime'
    cWaves_path = r'/app/C_Waves'

    master_file_path = r'/app/ecephys_spike_sorting/matlab'
    master_file_name = 'main_KS2_datashift.m'

    # for config files and kilosort working space
    kilosort_output_tmp = r'/tmp/kilosort_datatemp'

    # derived directory names

    modules_directory = os.path.join(ecephys_directory, 'modules')

    if kilosort_output_directory is None \
            and extracted_data_directory is None \
            and npx_directory is None:
        raise Exception('Must specify at least one output directory')

    # default ephys params. For spikeGLX, these get replaced by values read from metadata
    sample_rate = 30000
    num_channels = 384
    reference_channels = [191]
    uVPerBit = 2.34375
    acq_system = 'PXI'

    if spikeGLX_data:
        # location of the raw data is the continuous file passed from script
        # metadata file should be located in same directory
        #
        # kilosort output will be put in the same directory as the input raw data,
        # set in kilosort_output_directory passed from script
        # kilososrt postprocessing (duplicate removal) and identification of noise
        # clusters will act on phy output in the kilosort output directory
        #
        #
        if continuous_file is not None:
            probe_type, sample_rate, num_channels, uVPerBit = SpikeGLX_utils.EphysParams(
                continuous_file)
            print('SpikeGLX params read from meta')
            print('probe type: {:s}, sample_rate: {:.5f}, num_channels: {:d}, uVPerBit: {:.4f}'.format
                  (probe_type, sample_rate, num_channels, uVPerBit))
        print('kilosort output directory: ' + kilosort_output_directory)
        # set Open Ephys specific dictionary keys; can't be null and still
        # pass argshema parser, even when unused
        settings_json = npx_directory
        probe_json = npx_directory
        settings_xml = npx_directory

    else:
        # Data from Open Ephys; these params are sent manually from script
        if probe_type == '3A':
            acq_system = '3a'
            reference_channels = [36, 75, 112,
                                  151, 188, 227, 264, 303, 340, 379]
            uVPerBit = 2.34375      # for AP gain = 500
        elif (probe_type == 'NP1' or probe_type == '3B2'):
            acq_system = 'PXI'
            reference_channels = [191]
            uVPerBit = 2.34375      # for AP gain = 500
        elif (probe_type == 'NP21' or probe_type == 'NP24'):
            acq_system = 'PXI'
            reference_channels = [127]
            uVPerBit = 0.763      # for AP gain = 80, fixed in 2.0
        else:
            raise Exception('Unknown probe type')

        if npx_directory is not None:
            settings_xml = os.path.join(npx_directory, 'settings.xml')
            if extracted_data_directory is None:
                extracted_data_directory = npx_directory + '_sorted'
            probe_json = os.path.join(
                extracted_data_directory, 'probe_info.json')
            settings_json = os.path.join(
                extracted_data_directory, 'open-ephys.json')
        else:
            if extracted_data_directory is not None:
                probe_json = os.path.join(
                    extracted_data_directory, 'probe_info.json')
                settings_json = os.path.join(
                    extracted_data_directory, 'open-ephys.json')
                settings_xml = None
            else:
                settings_xml = None
                settings_json = None
                probe_json = None
                extracted_data_directory = kilosort_output_directory

        if kilosort_output_directory is None:
            kilosort_output_directory = os.path.join(
                extracted_data_directory, 'continuous', 'Neuropix-' + acq_system + '-100.0')

        if continuous_file is None:
            continuous_file = os.path.join(
                kilosort_output_directory, 'continuous.dat')

    # Create string designating temporary output file for KS2 (gets inserted into KS2 config.m file)
    # full path for temp whitened data file
    fproc = os.path.join(kilosort_output_tmp, 'temp_wh.dat')
    fproc_forward_slash = fproc.replace('\\', '/')
    fproc_str = "'" + fproc_forward_slash + "'"

    dictionary = \
        {
            "directories": {
                "ecephys_directory": ecephys_directory,
                "npx_directory": npx_directory,
                "extracted_data_directory": extracted_data_directory,
                "kilosort_output_directory": kilosort_output_directory,
                "kilosort_output_tmp": kilosort_output_tmp
            },

            "common_files": {
                "settings_json": settings_json,
                "probe_json": probe_json,
            },

            "ephys_params": {
                "probe_type": probe_type,
                "sample_rate": sample_rate,
                "lfp_sample_rate": 2500,
                "bit_volts": uVPerBit,
                "num_channels": num_channels,
                "reference_channels": reference_channels,
                "vertical_site_spacing": 10e-6,
                "ap_band_file": continuous_file,
                "lfp_band_file": os.path.join(extracted_data_directory, 'continuous', 'Neuropix-' + acq_system + '-100.1', 'continuous.dat'),
                "reorder_lfp_channels": True,
                "cluster_group_file_name": 'cluster_group.tsv'
            },

            "kilosort_helper_params": {

                "matlab_home_directory": "/usr/local/MATLAB",
                "kilosort_repository": kilosort_repository,
                "npy_matlab_repository": npy_matlab_repository,
                "master_file_path": master_file_path,
                "master_file_name": master_file_name,
                "kilosort_version": 2,
                "spikeGLX_data": True,
                "ks_make_copy": ks_make_copy,
                "surface_channel_buffer": 15,

                "kilosort2_params":
                {
                    "fproc": fproc_str,
                    "chanMap": "'chanMap.mat'",
                    "fshigh": 150,
                    "minfr_goodchannels": minfr_goodchannels,
                    "Th": '[10 4]',
                    "lam": 10,
                    "AUCsplit": 0.9,
                    "minFR": 1/50.,
                    "momentum": '[20 400]',
                    "sigmaMask": 30,
                    "ThPre": 8,
                    "gain": uVPerBit,
                    "CSBseed": CSBseed,
                    "LTseed": LTseed,
                    "whiteningRange": whiteningRange,
                    "nNeighbors": nNeighbors
                }
            }
        }

    with io.open(output_file, 'w', encoding='utf-8') as f:
        f.write(json.dumps(dictionary, ensure_ascii=False, sort_keys=True, indent=4))

    return dictionary
