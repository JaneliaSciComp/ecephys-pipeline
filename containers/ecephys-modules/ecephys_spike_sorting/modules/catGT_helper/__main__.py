from argschema import ArgSchemaParser
import os
import sys
import subprocess
import time
import shutil

import numpy as np
from pathlib import Path

from ...common.utils import read_probe_json, get_repo_commit_date_and_hash, rms


def run_CatGT(args):

    print('ecephys spike sorting: CatGT helper module', sys.platform)

    catGTPath = args['catGT_helper_params']['catGTPath']
    if sys.platform.startswith('win'):
        os_str = 'win'
        # build windows command line
        catGTexe_fullpath = catGTPath.replace('\\', '/') + "/runit.bat"
    elif sys.platform.startswith('linux'):
        os_str = 'linux'
        catGTexe_fullpath = catGTPath.replace('\\', '/') + "/runit.sh"
    else:
        print('unknown system, cannot run CatGt')

    cmd_parts = list()

    cmd_parts.append(catGTexe_fullpath)
    cmd_parts.append('-dir=' + args['directories']['npx_directory'])
    cmd_parts.append('-run=' + args['catGT_helper_params']['run_name'])
    cmd_parts.append('-g=' + args['catGT_helper_params']['gate_string'])
    cmd_parts.append('-t=' + args['catGT_helper_params']['trigger_string'])
    cmd_parts.append('-prb=' + args['catGT_helper_params']['probe_string'])
    cmd_parts.append(args['catGT_helper_params']['stream_string'])
    # common average referencing
    car_mode = args['catGT_helper_params']['car_mode']
    if car_mode == 'loccar':
        inner_site = args['catGT_helper_params']['loccar_inner']
        outer_site = args['catGT_helper_params']['loccar_outer']
        cmd_parts.append('-loccar=' + repr(inner_site) + ',' + repr(outer_site))
    elif car_mode == 'gbldmx':
        cmd_parts.append('-gbldmx')
    elif car_mode == 'gblcar':
        cmd_parts.append('-gblcar')
    cmd_parts.append(args['catGT_helper_params']['cmdStr'])
    
    # To avoid potential collisions of different jobs writeing to the _ct_offsets and _fyi files
    # call CatGT WITHOUT the -out_prb_fld option, and create a destination folder with 
    # the probe name
    runName_gate = args['catGT_helper_params']['run_name'] + '_g' + \
            args['catGT_helper_params']['gate_string']
    catgt_runName = 'catgt_' + runName_gate
    catgt_runDir = os.path.join(
            args['directories']['extracted_data_directory'], catgt_runName)    
    prbName = runName_gate + '_imec' + args['catGT_helper_params']['probe_string']   
    catgt_prbDir = os.path.join(catgt_runDir, prbName)
    
    # create the catgt run dirctory if it does not exist
    if not ( os.path.isdir(catgt_runDir) ):
        os.mkdir(catgt_runDir)
    
    # create the probe directory if it does not exist, and set as catgt destination
    if not ( os.path.isdir(catgt_prbDir) ):
        os.mkdir(catgt_prbDir)
    
    cmd_parts.append('-dest=' + catgt_prbDir)

    print('CatGT command line:',  cmd_parts)

    start = time.time()
    subprocess.call(cmd_parts)

    execution_time = time.time() - start

    # copy CatGT log file, which will be in the directory with the calling
    # python scripte, to the destination directory
    logPath = os.getcwd()
    logName = 'CatGT.log'


    # build name for log copy
    catgt_logName = catgt_runName
    if 'ap' in args['catGT_helper_params']['stream_string']:
        prb_title = ParseProbeStr(args['catGT_helper_params']['probe_string'])
        catgt_logName = catgt_logName + '_prb' + prb_title
    if 'ni' in args['catGT_helper_params']['stream_string']:
        catgt_logName = catgt_logName + '_ni'
    catgt_logName = catgt_logName + '_CatGT.log'

    shutil.copyfile(os.path.join(logPath, logName),
                    os.path.join(catgt_prbDir, catgt_logName))
    

    # run_name = args['catGT_helper_params']['run_name'] + '_g' + args['catGT_helper_params']['gate_string']
    # fyi_path = os.path.join(catgt_runDir, (run_name + '_fyi.txt'))
    # if Path(fyi_path).is_file():
    #     new_name = run_name + '_prb' + prb_title + '_fyi.txt'
    #     new_path = os.path.join(catgt_runDir, new_name)
    #     shutil.copyfile(fyi_path, new_path)
    
    # all_fyi_path =  os.path.join(catgt_runDir, (run_name + '_all_fyi.txt'))
    # temp_path = os.path.join(catgt_runDir, 'temp.txt')
    # if Path(fyi_path).is_file():        
    #     if Path(all_fyi_path).is_file():
    #         # append current fyi
    #         if os_str == 'linux':
    #             cat_fyi_cmd = 'cat ' + all_fyi_path + ' ' + fyi_path + ' > ' + temp_path
    #         else:
    #             cat_fyi_cmd = 'type ' + all_fyi_path + ' ' + fyi_path + ' > ' + temp_path
    #         print(cat_fyi_cmd)
    #         subprocess.Popen(cat_fyi_cmd, shell='False').wait()
    #         os.remove(all_fyi_path)
    #         shutil.copyfile(temp_path, all_fyi_path)
    #         os.remove(temp_path)
    #     else:
    #         # copy current fyi to all_fyi
    #         shutil.copyfile(fyi_path, all_fyi_path)                    
            

    print('total time: ' + str(np.around(execution_time, 2)) + ' seconds')

    return {"execution_time": execution_time}  # output manifest


def ParseProbeStr(probe_string):

    # from a probe_string in a CatGT command line
    # create a title for the log file which inludes all the
    # proceessed probes

    str_list = probe_string.split(',')
    prb_title = ''
    for substr in str_list:
        if (substr.find(':') > 0):
            # split at colon
            subsplit = substr.split(':')
            for i in range(int(subsplit[0]), int(subsplit[1]) + 1):
                prb_title = prb_title + '_' + str(i)
        else:
            # just append this string
            prb_title = prb_title + '_' + substr

    return prb_title


def main():

    from ._schemas import InputParameters, OutputParameters

    """Main entry point:"""
    mod = ArgSchemaParser(schema_type=InputParameters,
                          output_schema_type=OutputParameters)

    output = run_CatGT(mod.args)

    output.update({"input_parameters": mod.args})
    if "output_json" in mod.args:
        mod.output(output, indent=2)
    else:
        print(mod.get_output_json(output))


if __name__ == "__main__":
    main()
