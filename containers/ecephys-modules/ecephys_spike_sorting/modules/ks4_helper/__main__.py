import ast
import numpy as np
import os
import time
import shutil

from argschema import ArgSchemaParser

from kilosort import run_kilosort, io
from kilosort.parameters import DEFAULT_SETTINGS

from ...common.SGLXMetaToCoords import readMeta, MetaToCoords

from pathlib import Path


def _string_as_list_param(dict, param, default_val):
    v = dict.get(param, default_val)
    if v is None:
        return None
    else:
        return ast.literal_eval(v if ',' in v else v.replace(' ', ',', 1))

def _get_ks_params(meta_file, settings_from_json):
    """
    Create kilosort parameters from the probe metadata and
    from the input JSON
    """
    probe_meta = readMeta(meta_file)
    
    # in run_kilosort, the settings dictionary is merged with the dictionary
    # DEFAULT_SETTINGS. Here, only set settings passed from the pipeline params
    # and read from metadata.
    settings = DEFAULT_SETTINGS    
    settings['n_chan_bin'] = int(probe_meta.get('nSavedChans'))
    settings['fs'] = float(probe_meta.get('imSampRate')) # sample rate
    # all other user setting coming from the json, and 
    settings = {**settings, **settings_from_json}

    return dict(settings)

def _fix_phy_params(output_dir, dat_path, dat_name, chan_phy_binary,
                    sample_rate):
    """
    Writes a new params.py file.
    dat_path will be set to a relative path from output_dir to
    dat_path/dat_name
    sample rate will be written out to sufficient digits to be used
    """
    shutil.copy(os.path.join(output_dir, 'params.py'),
                os.path.join(output_dir, 'old_params.py'))

    # create a relative path if possible, otherwise use the full path to the data
    try:
        relPath = os.path.relpath(dat_path, output_dir)
        new_path = os.path.join(relPath, dat_name)
    except ValueError:
        new_path = os.path.join(dat_path, dat_name)
    
    new_path = new_path.replace('\\', '/')

    paramLines = list()

    with open(os.path.join(output_dir, 'old_params.py'), 'r') as f:
        currLine = f.readline()

        while currLine != '':  # The EOF char is an empty string
            if 'dat_path' in currLine:
                currLine = "dat_path = '" + new_path + "'\n"
            elif 'n_channels_dat' in currLine:
                currLine = "n_channels_dat = " + repr(chan_phy_binary) + "\n"
            elif 'sample_rate' in currLine:
                currLine = (f'sample_rate = {sample_rate:.12f}\n')
            paramLines.append(currLine)
            currLine = f.readline()

    with open(os.path.join(output_dir, 'params.py'), 'w') as fout:
        for line in paramLines:
            fout.write(line)
            
def run_ks4(args):
     
    """
    Run full spike sorting pipeline on specified data.
     
     Set up call to kilosort 4 call run_kilosort.run_kilosort
     
     Comments on the parameters and call from teh ks4 code:
         
     run_kilosort(settings, probe=None, probe_name=None, filename=None,
                  data_dir=None, file_object=None, results_dir=None,
                  data_dtype=None, do_CAR=True, invert_sign=False, device=None,
                  progress_bar=None, save_extra_vars=False):
    
     
     Parameters
     ----------
     settings : dict
         Specifies a number of configurable parameters used throughout the
         spike sorting pipeline. See `kilosort/parameters.py` for a full list of
         available parameters.
         NOTE: `n_chan_bin` must be specified here, but all other settings are
               optional.
     probe : dict; optional.
         A Kilosort4 probe dictionary, as returned by `kilosort.io.load_probe`.
     probe_name : str; optional.
         Filename of probe to use, within the default `PROBE_DIR`. Only include
         the filename without any preceeding directories. Will ony be used if
         `probe is None`. Alternatively, the full filepath to a probe stored in
         any directory can be specified with `settings = {'probe_path': ...}`.
         See `kilosort.utils` for default `PROBE_DIR` definition.
     filename: str or Path; optional.
         Full path to binary data file. If specified, will also set
         `data_dir = filename.parent`.
     data_dir : str or Path; optional.
         Specifies directory where binary data file is stored. Kilosort will
         attempt to find the binary file. This works best if there is exactly one
         file in the directory with a .bin, .bat, .dat, or .raw extension.
         Only used if `filename is None`.
         Also see `kilosort.io.find_binary`.
     file_object : array-like file object; optional.
         Must have 'shape' and 'dtype' attributes and support array-like
         indexing (e.g. [:100,:], [5, 7:10], etc). For example, a numpy
         array or memmap. Must specify a valid `filename` as well, even though
         data will not be directly loaded from that file.
     results_dir : str or Path; optional.
         Directory where results will be stored. By default, will be set to
         `data_dir / 'kilosort4'`.
     data_dtype : str or type; optional.
         dtype of data in binary file, like `'int32'` or `np.uint16`. By default,
         dtype is assumed to be `'int16'`.
     do_CAR : bool; default=True.
         If True, apply common average reference during preprocessing
         (recommended).
     invert_sign : bool; default=False.
         If True, flip positive/negative values in data to conform to standard
         expected by Kilosort4.
     device : torch.device; optional.
         CPU or GPU device to use for PyTorch calculations. By default, PyTorch
         will use the first detected GPU. If no GPUs are detected, CPU will be
         used. To set this manually, specify `device = torch.device(<device_name>)`.
         See PyTorch documentation for full description.
     progress_bar : tqdm.std.tqdm or QtWidgets.QProgressBar; optional.
         Used by sorting steps and GUI to track sorting progress. Users should
         not need to specify this.
     save_extra_vars : bool; default=False.
         If True, save tF and Wall to disk after sorting.
    """   
    
    start = time.time()
    print('ecephys spike sorting: ks4 helper module')
        
    input_file_name = args['ephys_params']['ap_band_file']
    input_file = Path(input_file_name)

    ks_output_dir_name = args['directories']['kilosort_output_directory']
    ks_output_dir = Path(ks_output_dir_name)
    ks_output_dir.mkdir(parents=True, exist_ok=True)

    meta_file = input_file.with_suffix('.meta')
    meta_name = meta_file.stem
    chanmap_filename = meta_name + '_chanMap.mat'
    chanmap_file = os.path.join(ks_output_dir, chanmap_filename)
    # generate chanMap file
    MetaToCoords(metaFullPath=meta_file, outType=1,
                 destFullPath=str(chanmap_file))

    # make a copy of the chanMap file to the binary directory; serves as a record
    # simplfies re-running the sorter outside of the pipeline.
    shutil.copy(chanmap_file, os.path.join(input_file.parent, chanmap_filename))
    ks4_prb = io.load_probe(os.path.join(input_file.parent, chanmap_filename))
    
    settings_from_json = args['ks4_helper_params']
    settings = _get_ks_params(meta_file, settings_from_json)
    print(repr(settings))
#    print(repr(ks4_prb))
    
    run_kilosort(settings, 
                 probe=ks4_prb, 
                 filename=input_file,
                 results_dir=ks_output_dir,
                 data_dtype='int16', 
                 do_CAR=settings.get('car'), 
                 save_extra_vars=settings.get('save_extra_vars'),
                 clear_cache=True,
                 save_preprocessed_copy=True,
                 verbose_console=True)
#
    # make sure the params file for phy has the correct number of channels
    # to match the input binary. This is likely not necessary for KS4.
    chan_phy_binary = args['ephys_params']['num_channels']
    _fix_phy_params(ks_output_dir, input_file.parent, input_file.name,
                       chan_phy_binary, args['ephys_params']['sample_rate'])

    if args['ks4_helper_params']['ks_make_copy']:
        # get the kilsort output directory name
        phyName = ks_output_dir.stem
        # build a name for the copy
        copy_dir = os.path.join(ks_output_dir.parent, phyName + '_orig')
        # check for whether the directory is already there; if so, delete it
        if os.path.exists(copy_dir):
            shutil.rmtree(copy_dir)
        # make a copy of output_dir
        shutil.copytree(ks_output_dir, copy_dir)

    execution_time = time.time() - start

    print('kilsort run time: ' + str(np.around(execution_time, 2)) + ' seconds')
    print()

    return {
        'execution_time': execution_time,
    }  # output manifest
# def _get_ks_params(meta_file, params_dict):
#     """
#     Create kilosort parameters from the probe metadata and
#     from the input JSON
#     """
#     probe_meta = readMeta(meta_file)
#     params = KilosortParams()

#     params.preprocessing_function = params_dict.get('preprocessing_function', False)
#     params.seed = params_dict.get('seed', 42)
#     params.ks2_mode = params_dict.get('ks2_mode', False)
#     params.perform_drift_registration = params_dict.get('perform_drift_registration',
#                                                         True)
#     params.do_whitening = True
#     params.car = params_dict.get('car', False)
#     params.fs = probe_meta.get('imSampRate', 30000)  # sample rate
#     params.n_channels = int(probe_meta.get('nSavedChans'))
#     params.save_temp_files = params_dict.get('save_temp_files', True)
#     if params_dict.get('doFilter'):
#         params.fshigh = params_dict.get('fshigh')
#         params.fslow = params_dict.get('fslow')
#     else:
#         # skip filtering
#         params.fshigh = None
#         params.fslow = None
#     params.minfr_goodchannels = params_dict.get('minfr_goodchannels', 0.1)
#     params.genericSpkTh = params_dict.get('ThPre', 8.0)
#     params.nblocks = params_dict.get('nblocks', 5)
#     params.overwrite = True if params_dict.get('copy_fproc') else False
#     params.sig_datashift = params_dict.get('sig_datashift', 20.0)
#     params.deterministic_mode = params_dict.get('deterministic_mode', True)
#     params.datashift = params_dict.get('datashift')
#     params.Th = _string_as_list_param(params_dict, 'Th', '[10, 4]')
#     params.ThPre = params_dict.get('ThPre', 8)
#     params.lam = params_dict.get('lam', 10)
#     params.AUCsplit = params_dict.get('AUCsplit', 0.9)
#     params.minFR = params_dict.get('minFR', 0.02)
#     params.momentum = _string_as_list_param(params_dict,
#                                             'momentum', '[20,400]')
#     params.output_filename = params_dict.get('fproc')
#     params.sigmaMask = params_dict.get('sigmaMask', 30)
#     params.whiteningRange = params_dict.get('whiteningRange', 32)

#     return dict(params)


# def _fix_phy_params(output_dir, dat_path, dat_name, chan_phy_binary,
#                     sample_rate):
#     """
#     Writes a new params.py file.
#     dat_path will be set to a relative path from output_dir to
#     dat_path/dat_name
#     sample rate will be written out to sufficient digits to be used
#     """
#     shutil.copy(os.path.join(output_dir, 'params.py'),
#                 os.path.join(output_dir, 'old_params.py'))

#     relPath = os.path.relpath(dat_path, output_dir)
#     new_path = os.path.join(relPath, dat_name)
#     new_path = new_path.replace('\\', '/')

#     paramLines = list()

#     with open(os.path.join(output_dir, 'old_params.py'), 'r') as f:
#         currLine = f.readline()

#         while currLine != '':  # The EOF char is an empty string
#             if 'dat_path' in currLine:
#                 currLine = "dat_path = '" + new_path + "'\n"
#             elif 'n_channels_dat' in currLine:
#                 currLine = "n_channels_dat = " + repr(chan_phy_binary) + "\n"
#             elif 'sample_rate' in currLine:
#                 currLine = (f'sample_rate = {sample_rate:.12f}\n')
#             paramLines.append(currLine)
#             currLine = f.readline()

#     with open(os.path.join(output_dir, 'params.py'), 'w') as fout:
#         for line in paramLines:
#             fout.write(line)


# def run_kilosort(args):

#     print('ecephys spike sorting: kilosort helper module')

#     print('master branch -- single main KS2/KS25/KS3')

#     input_file_name = args['ephys_params']['ap_band_file']
#     input_file = Path(input_file_name)

#     ks_output_dir_name = args['directories']['kilosort_output_directory']
#     ks_output_dir = Path(ks_output_dir_name)
#     ks_output_dir.mkdir(parents=True, exist_ok=True)

#     ks_tmp_output_dir_name = args['directories']['kilosort_output_tmp']
#     ks_tmp_output_dir = Path(ks_tmp_output_dir_name)
#     ks_tmp_output_dir.mkdir(parents=True, exist_ok=True)

#     start = time.time()
#     meta_file = input_file.with_suffix('.meta')
#     meta_name = meta_file.stem
#     chanmap_filename = meta_name + '_chanMap.mat'
#     chanmap_file = os.path.join(ks_output_dir, chanmap_filename)
#     # generate chanMap file
#     MetaToCoords(metaFullPath=meta_file, outType=1,
#                  destFullPath=str(chanmap_file))

#     pyks_params = args['pykilosort_helper_params']
#     ks_params = _get_ks_params(meta_file, pyks_params)
#     run(input_file,
#         output_dir=ks_output_dir,
#         dir_path=ks_tmp_output_dir,
#         probe_path=str(chanmap_file),
#         **ks_params)

#     if pyks_params.get('copy_fproc'):
#         fproc_path_str = pyks_params['fproc']
#         fproc_path = ks_tmp_output_dir / '.kilosort' / Path(input_file).stem/'proc.dat'
#         # make a new name for the processed file based on the original
#         # binary and metadata files
#         fp_save_name = meta_name + '_ksproc.bin'
#         shutil.copy(fproc_path, os.path.join(ks_output_dir.parent, fp_save_name))
#         cm_path = os.path.join(ks_output_dir, 'channel_map.npy')
#         cm = np.load(cm_path)
#         chan_phy_binary = cm.size
#         _fix_phy_params(ks_output_dir, ks_output_dir.parent, fp_save_name,
#                         chan_phy_binary, args['ephys_params']['sample_rate'])
#     else:
#         chan_phy_binary = args['ephys_params']['num_channels']
#         _fix_phy_params(ks_output_dir, input_file.parent, input_file.name,
#                        chan_phy_binary, args['ephys_params']['sample_rate'])

#     if ks_tmp_output_dir != ks_output_dir:
#         try:
#             print('Remove KS temporary dir %s' % ks_tmp_output_dir)
#             shutil.rmtree(ks_tmp_output_dir)
#         except OSError as e:
#             print('Error: %s : %s' % (ks_tmp_output_dir, e.strerror))

#     execution_time = time.time() - start

#     print('kilsort run time: ' + str(np.around(execution_time, 2)) + ' seconds')
#     print()

#     return {
#         'execution_time': execution_time,
#     }  # output manifest


def main():

    from ._schemas import InputParameters, OutputParameters

    """Main entry point:"""
    mod = ArgSchemaParser(schema_type=InputParameters,
                          output_schema_type=OutputParameters)

    output = run_kilosort(mod.args)

    output.update({"input_parameters": mod.args})
    if "output_json" in mod.args:
        mod.output(output, indent=2)
    else:
        print(mod.get_output_json(output))


if __name__ == "__main__":
    main()
