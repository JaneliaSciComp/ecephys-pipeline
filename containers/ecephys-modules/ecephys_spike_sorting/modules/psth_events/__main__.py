from argschema import ArgSchemaParser
import os
import subprocess
import time
import shutil
import fnmatch
from ...common.utils import catGT_ex_params_from_str

import numpy as np


def get_psth_events(args):

    # simple function to read in extracted edges file created by CatGT
    # then write out a file of events, formatted as csv, to the
    # kilosort_output directory which contains the phy files

    # assumes that CatGT was run using -prb_fld, so extracted SY edges
    # reside in the directory with the binary data and extracted NI edges
    # reside in the parent of that folder

    # TODO -- this function needst to be moved to TPrime_helper
    # Can't run safely before all probes are run.
    print('ecephys spike sorting: PSTH events module')

    input_file = args['ephys_params']['ap_band_file']  # this is the CatGT processed file
    extract_str = args['psth_events']['event_ex_param_str']

    # stream names for each js
    stream_name = []
    stream_name.append('nidq')
    stream_name.append('obx')
    stream_name.append('imec')
    stream_fileid = []
    stream_fileid.append('.nidq.')
    stream_fileid.append('.obx.')
    stream_fileid.append('.ap.')
    
    # get extraction parameters, build name for output file
    ex_type, stream_index, prb_index, ex_name_str = catGT_ex_params_from_str(extract_str)
    prb = str(prb_index)

    prb_fld, bin_name = os.path.split(input_file)
    run_fld, prb_fld_name = os.path.split(prb_fld)
    parent_fld, run_fld_name = os.path.split(run_fld)
    
    # scan through the probe folders to get the probe indicies
    run_name = args['ephys_params']['run_name'] + '_g' + args['ephys_params']['gate_string']
    prb_fld_wild = run_name + '_imec*'
    lowest_prb_index = -1
    for pdir in os.listdir(run_fld):
        if fnmatch.fnmatch(pdir,prb_fld_wild):
            im_pos = pdir.find('_imec')
            curr_prb_str = pdir[im_pos+5:len(pdir)]
            curr_prb_index = int(curr_prb_str)
            if curr_prb_index > lowest_prb_index:
                lowest_prb_index = curr_prb_index
    
            
    #scan through the probe folders to get the probe indicies

    if 'x' in extract_str:
        # edge file from CatGT 3.0 or later
        # params for analog: js, ip, word, thresh1, thresh2, duration
        # params for digital: js, ip, word (or -1)
        if stream_index == 0:
            # nidq stream, extracted edge folders in lowest index probe folder
            ex_file_name = run_name + '_tcat.nidq.' + ex_name_str + '.txt'
            file_list = os.listdir(run_fld)
            flt_list = fnmatch.filter(file_list, ex_file_name)      
            if len(flt_list) != 1:
                print('No edge file or multiple files for psth events\n' )
                return 
            ex_path = os.path.join(run_fld, flt_list[0])
        else:
            # for other streams, the extract files are assumed to be in probe folders
            match_str = run_name + '_tcat.' + stream_name[stream_index] + prb + stream_fileid[stream_index] + ex_name_str + '.txt'
            ex_prb_fld_name = run_name + '_' + stream_name[stream_index] + prb
            file_list = os.listdir(os.path.join(run_fld, ex_prb_fld_name))
            flt_list = fnmatch.filter(file_list,match_str)
            if len(flt_list) != 1:
                print('No edge file or multiple files for psth events\n' )
                return              
            ex_file_name = flt_list[0]                       
            ex_path = os.path.join(run_fld, ex_prb_fld_name, ex_file_name)
            


    # the CatGT extracted edge files are a single column with </n>
    # event viewer needs .csv
    edgeTimes = np.zeros((0), dtype='float')
    with open(ex_path, 'r') as inFile:
        line = inFile.readline()
        while line != '':  # The EOF char is an empty string
            currEdge = float(line)
            edgeTimes = np.append(edgeTimes, currEdge)
            line = inFile.readline()

    # The output should be saved with the phy output, where the event viewer
    # plugin can read it

    phy_dir = args['directories']['kilosort_output_directory']
    event_path = os.path.join(phy_dir, 'events.csv')
    nEvent = len(edgeTimes)
    with open(event_path, 'w') as outfile:
        for i in range(0, nEvent-1):
            outfile.write(f'{edgeTimes[i]:.6f},')
        outfile.write(f'{edgeTimes[nEvent-1]:.6f}')

    return {'message': event_path}  # empty manifest


def main():

    from ._schemas import InputParameters, OutputParameters

    """Main entry point:"""
    mod = ArgSchemaParser(schema_type=InputParameters,
                          output_schema_type=OutputParameters)

    print('ecephys spike sorting: Start PSTH events module')
    start = time.time()
    output = get_psth_events(mod.args)
    execution_time = time.time() - start
    print('total time: ' + str(np.around(execution_time, 2)) + ' seconds')
    output.update({"execution_time": execution_time})  # -- update execution time

    output.update({"input_parameters": mod.args})
    if "output_json" in mod.args:
        mod.output(output, indent=2)
    else:
        print(mod.get_output_json(output))


if __name__ == "__main__":
    main()
