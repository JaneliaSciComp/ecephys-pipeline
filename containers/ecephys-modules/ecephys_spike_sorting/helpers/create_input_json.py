import os
import io
import json
import sys

if sys.platform == 'linux':
    import pwd
from . import SpikeGLX_utils

import numpy as np


def create_samba_directory(samba_server, samba_share):

    if sys.platform == 'linux':
        proc_owner_uid = str(pwd.getpwnam(os.environ['USER']).pw_uid)
        share_string = 'smb-share:server={},share={}'.format(
            samba_server, samba_share)
        data_dir = os.path.join('/', 'var', 'run', 'user',
                                proc_owner_uid, 'gvfs', share_string)
    else:
        data_dir = r'\\' + os.path.join(samba_server, samba_share)

    return data_dir


def createInputJson(default_config,
                    output_file,
                    npx_directory=None,
                    continuous_file=None,
                    spikeGLX_data=True,
                    input_meta_path=None,
                    extracted_data_directory=None,
                    kilosort_output_directory=None,
                    ks_make_copy=False,
                    probe_type='',
                    gate_string='0',
                    trigger_string='0,0',
                    probe_string='0',
                    catGT_run_name=None,
                    catGT_stream_string='-ap',
                    catGT_car_mode='gblcar',
                    catGT_loccar_min_um=40,
                    catGT_loccar_max_um=160,
                    catGT_cmd_string = '-prb_fld -out_prb_fld',
                    catGT_maxZ_um = -1,
                    event_ex_param_str='',
                    tPrime_im_ex_list='',
                    tPrime_ni_ex_list='',
                    sync_period=1.0,
                    toStream_sync_params='',
                    niStream_sync_params='',
                    sort_out_tag='ks2',
                    tPrime_3A=False,
                    toStream_path_3A=None,
                    fromStream_list_3A=None,
                    ks_ver='2.0',  # must equal '3.0', '2.5' or '2.0', and match the kiilosort_repository
                    ks_doFilter=0,
                    ks_mask_bad_channels=True,
                    ks_mode=False,
                    ks_drift_registration=True,
                    ks_sigma_mask=30,
                    ks_fshigh=150,
                    ks_fslow=None,
                    ks_car=0,
                    ks_save_temp_files=True,
                    ks_deterministic=True,
                    ks_nblocks=5,
                    ks_remDup=0,
                    ks_finalSplits=1,
                    ks_labelGood=1,
                    ks_saveRez=1,
                    ks_copy_fproc=0,
                    ks_minfr_goodchannels=0.1,
                    ks_whiteningRadius_um=163,
                    ks_Th='[10,4]',
                    ks_CSBseed=1,
                    ks_LTseed=1,
                    ks_template_from_data = True,
                    ks_templateRadius_um=163,
                    ks_tmin = 0,
                    ks_tmax = -1,
                    ks_working_dir='/tmp/kilosort_datatemp',
                    ks_maxNeighbors=64, # 64 for standard build of KS
                    pyks_preprocessing_function='kilosort2',
                    pyks_alf_location='',
                    ks4_Th_universal=9.0,
                    ks4_Th_learned=8.0,
                    ks4_duplicate_spike_ms=0.25,
                    ks4_min_template_size_um=10,                  
                    c_Waves_snr_um=160,
                    qm_isi_thresh=1.5/1000,
                    include_pcs=True,
                    ):

    # hard coded paths to code on your computer and system
    kilosort_repository = '/app/kilosort-{}'.format(ks_ver)

    # KS 3.0 does not yet output pcs.
    if ks_ver == '3.0':
        include_pcs = False  # set to false for KS2ver = '3.0'

    # for config files and kilosort working space
    kilosort_output_tmp = ks_working_dir

    # derived directory names

    if kilosort_output_directory is None \
            and extracted_data_directory is None \
            and npx_directory is None:
        raise Exception('Must specify at least one output directory')

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
        if input_meta_path is not None:
            probe_type, sample_rate, num_channels, reference_channels, \
             uVPerBit, vpitch, hpitch,nColumn, nAP, nSY, useGeom = \
             SpikeGLX_utils.EphysParams(input_meta_path)
            print('SpikeGLX params read from meta')
            print('probe type: {:s}, sample_rate: {:.5f}, num_channels: {:d}, uVPerBit: {:.4f}'.format
                  (probe_type, sample_rate, num_channels, uVPerBit))
            probe_sampling_info = {
                'probe_type': probe_type,
                'sample_rate': sample_rate,
                'lfp_sample_rate': sample_rate / 12,
                'num_channels': num_channels,
                'bit_volts': uVPerBit,
                'reference_channels':reference_channels
            }
        else:
            probe_sampling_info = {}
            uVPerBit = 2.34375  # default gain - needed by ks2 params
            if probe_type:
                probe_sampling_info['probe_type'] = probe_type

        print('kilosort output directory: ', kilosort_output_directory)

    else:
        print('only SpikeGLX data is supported at this time')

    # CatGT needs the inner and outer redii for local common average referencing
    # specified in sites
    catGT_loccar_min_sites = int(
        round(catGT_loccar_min_um/vpitch))
    catGT_loccar_max_sites = int(
        round(catGT_loccar_max_um/vpitch))
    # print('loccar min: ' + repr(catGT_loccar_min_sites))

    # whiteningRange is the number of sites used for whitening in KIlosort
    # preprocessing. Calculate the number of sites within the user-specified
    # whitening radius for this probe geometery
    # for a Np 1.0 probe, 163 um => 32 sites
    nrows = np.sqrt((np.square(ks_whiteningRadius_um) - np.square(hpitch)))/vpitch 
    ks_whiteningRange = int(round(2*nrows*nColumn))
    if ks_whiteningRange > 384:
        ks_whiteningRange = 384

    # nNeighbors is the number of sites kilosort includes in a template.
    # Calculate the number of sites within that radisu.
    nrows = np.sqrt((np.square(ks_whiteningRadius_um) - np.square(hpitch)))/vpitch                     
    ks_nNeighbors = int(round(2*nrows*nColumn))
    if ks_nNeighbors > ks_maxNeighbors:
        ks_nNeighbors = ks_maxNeighbors
    print('ks_nNeighbors: ' + repr(ks_nNeighbors))

    c_waves_radius_sites = int(round(c_Waves_snr_um/vpitch))
    # Create string designating temporary output file for KS2 (gets inserted into KS2 config.m file)
    # full path for temp whitened data file
    fproc = os.path.join(kilosort_output_tmp, 'temp_wh.dat')
    fproc_forward_slash = fproc.replace('\\', '/')
    fproc_str = "'" + fproc_forward_slash + "'"
    ap_band_file = continuous_file
    # continuous file may be null so test it (cg)
    if continuous_file is not None:
        lfp_band_file = continuous_file.replace('.ap.bin', '.lf.bin')
    else:
        print('No continuous file found', npx_directory)
        lfp_band_file = os.path.join(extracted_data_directory,
                                    'continuous',
                                    'Neuropix-' + acq_system + '-100.1',
                                    'continuous.dat')

    kilosort_parent_dir, kilosort_dirname = os.path.split(kilosort_output_directory)
       
    # get KS4 params from the KS2,2.5,3.0 versions
    th_list_str = ks_Th[1:len(ks_Th)-1]   #strip square brackets
    th_list = th_list_str.split(',')
    ks4_Th_universal = int(th_list[0])
    ks4_Th_learned = int(th_list[1])

    dictionary = {}
    dictionary['directories'] = default_config['directories'] | {
        "npx_directory": npx_directory,
        "extracted_data_directory": extracted_data_directory,
        "kilosort_output_directory": kilosort_output_directory,
        "kilosort_output_tmp": kilosort_output_tmp,
    }
    dictionary['common_files'] = default_config['common_files'] | {
        "settings_json": npx_directory,
        "probe_json": os.path.join(kilosort_parent_dir,'probe_json.json'),
    }
    dictionary['ephys_params'] = default_config['ephys_params'] | {
        "run_name": catGT_run_name,
        "gate_string": gate_string,
        "ap_band_file": ap_band_file,
        "lfp_band_file": lfp_band_file,
    } | probe_sampling_info
    dictionary['kilosort_helper_params'] = default_config['kilosort_helper_params'] | {
        'matlab_home_directory': kilosort_output_tmp,
        'kilosort_repository': kilosort_repository,
        'spikeGLX_data': spikeGLX_data,
        'ks_make_copy': ks_make_copy,
        'ks_mask_bad_channels': ks_mask_bad_channels,
        'kilosort2_params': default_config['kilosort_helper_params']['kilosort2_params'] | {
            'KSver': ks_ver,
            # these are expressed as int rather than Bool for matlab compatability
            'remDup': ks_remDup,
            'finalSplits': ks_finalSplits,
            'labelGood': ks_labelGood,
            'saveRez': ks_saveRez,
            'copy_fproc': ks_copy_fproc,
            'fproc': fproc_str,
            'minfr_goodchannels': ks_minfr_goodchannels,
            'Th': ks_Th,
            "gain": uVPerBit,
            'CSBseed': ks_CSBseed,
            'LTseed': ks_LTseed,
            'sigmaMask': ks_sigma_mask,
            'fshigh': ks_fshigh,
            'whiteningRange': ks_whiteningRange,
            'nNeighbors': ks_nNeighbors,
            'doFilter': ks_doFilter,
            'CAR': 1 if ks_car else 0,
        }
    }
    dictionary['pykilosort_helper_params'] = default_config['pykilosort_helper_params'] | {
        'preprocessing_function': pyks_preprocessing_function,
        'alf_location': '' if pyks_alf_location is None else pyks_alf_location,
        'seed': ks_CSBseed,
        'Th': ks_Th,
        'minfr_goodchannels': ks_minfr_goodchannels,
        'whiteningRange': ks_whiteningRange,
        'copy_fproc': ks_copy_fproc,
        'fproc': fproc_str,
        'ks2_mode': ks_mode,
        'perform_drift_registration': ks_drift_registration,
        'car': True if ks_car else False,
        'sigmaMask': ks_sigma_mask,
        'fshigh': ks_fshigh,
        'fslow': ks_fslow,
        'save_temp_files': ks_save_temp_files,
        'deterministic_mode': ks_deterministic,
        'nblocks': ks_nblocks,
        'doFilter': ks_doFilter,
    }
  
    dictionary['ks4_helper_params'] = default_config['ks4_helper_params'] | {
            'do_CAR' :  True if ks_car == 0 else False,
            'save_extra_vars' : include_pcs,    # to save Wall and pc features
            'doFilter' : ks_doFilter,        # not yet used
            'ks_make_copy': ks_make_copy,
            'save_preprocessed_copy': bool(ks_copy_fproc),
            # ks4_params are limited to members of the KS4 'settings' list
            'ks4_params' : default_config['ks4_helper_params']['ks4_params'] | {           
                    'Th_universal' : ks4_Th_universal,
                    'Th_learned' : ks4_Th_learned,  
                    'duplicate_spike_ms' : ks4_duplicate_spike_ms,
                    'nblocks' : ks_nblocks,
                    'sig_interp' : 20.0,
                    'whitening_range' : ks_whiteningRange,
                    'min_template_size' : ks4_min_template_size_um,
                    'template_sizes' : 5,
                    'templates_from_data' : ks_template_from_data,
                    'nearest_chans' : 10,
                    'nearest_templates' : 100,
                    'ccg_threshold' : 0.25,
                    'acg_threshold' : 0.20,
                    'cluster_init_seed' : ks_CSBseed,
                    'tmin' : ks_tmin,
                    'tmax' : ks_tmax
            }
    }
    
    dictionary['ks_postprocessing_params'] = default_config['ks_postprocessing_params'] | {
        "include_pcs": include_pcs,
    }
    dictionary['waveform_metrics'] = default_config['waveform_metrics'] | {
        "waveform_metrics_file": os.path.join(kilosort_output_directory, 'waveform_metrics.csv'),          
    }
    dictionary['cluster_metrics'] = default_config['cluster_metrics'] | {
        "cluster_metrics_file": os.path.join(kilosort_output_directory, 'metrics.csv'),
    }
    dictionary['extract_from_npx_params'] = default_config['extract_from_npx_params'] | {
        "npx_directory": npx_directory,
        "settings_xml": npx_directory,
    }
    dictionary['depth_estimation_params'] = default_config['depth_estimation_params'] | {
        "figure_location": os.path.join(kilosort_parent_dir, 'probe_depth.png'),
    }
    dictionary['median_subtraction_params'] = default_config['median_subtraction_params'] | {
    }
    dictionary['mean_waveform_params'] = default_config['mean_waveform_params'] | {
        "mean_waveforms_file": os.path.join(kilosort_output_directory, 'mean_waveforms.npy'),
        "snr_radius": c_waves_radius_sites
    }
    dictionary['noise_waveform_params'] = default_config['noise_waveform_params'] | {
    }
    dictionary['quality_metrics_params'] = default_config['quality_metrics_params'] | {
        "isi_threshold": qm_isi_thresh,
        "include_pcs": include_pcs # should this be set to True or be based on ks_ver?
    }
    dictionary['catGT_helper_params'] = default_config['catGT_helper_params'] | {
        "run_name": catGT_run_name,
        "gate_string": gate_string,
        "probe_string": probe_string,
        "trigger_string": trigger_string,
        "stream_string": catGT_stream_string,
        "car_mode": catGT_car_mode,
        "loccar_inner": catGT_loccar_min_sites,
        "loccar_outer": catGT_loccar_max_sites,
        "loccar_inner_um" : catGT_loccar_min_um,
        "loccar_outer_um" : catGT_loccar_max_um,
        "useGeom" : useGeom,
        "cmdStr": catGT_cmd_string,
    }
    dictionary['tPrime_helper_params'] = default_config['tPrime_helper_params'] | {
        "im_ex_list": tPrime_im_ex_list,
        "ni_ex_list": tPrime_ni_ex_list,
        "sync_period": sync_period,
        "toStream_sync_params": toStream_sync_params,
        "ni_sync_params": niStream_sync_params,
        "sort_out_tag": sort_out_tag,
	    "psth_ex_str": event_ex_param_str,
        "tPrime_3A": tPrime_3A,
        "toStream_path_3A": toStream_path_3A,
        "fromStream_list_3A": fromStream_list_3A,
    }
    dictionary['psth_events'] = default_config['psth_events'] | {
        "event_ex_param_str": event_ex_param_str,
    }

    with io.open(output_file, 'w', encoding='utf-8') as f:
        f.write(json.dumps(dictionary, ensure_ascii=False, sort_keys=True, indent=4))

    return dictionary
