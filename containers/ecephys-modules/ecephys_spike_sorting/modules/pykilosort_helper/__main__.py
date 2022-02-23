import numpy as np
import os
import time
import shutil

from argschema import ArgSchemaParser

from ibllib.io import spikeglx
from ibllib.ephys import spikes, neuropixel

from pykilosort import add_default_handler, run, Bunch
from pykilosort.params import KilosortParams

from pathlib import Path


def get_ks_params(probe, preprocessing_function='kilosort2', ibl_neuropixel_version=1):
    neuropixel_header = neuropixel.trace_header(version=ibl_neuropixel_version)

    probe.Nchan = int(probe.nSavedChans)
    probe.xc = neuropixel_header['x']
    probe.yc = neuropixel_header['y']
    probe.kcoords = np.zeros(probe.Nchan-1)

    params = KilosortParams()
    params.preprocessing_function = preprocessing_method
    params.probe = probe

    return dict(params)



def run_kilosort(args):

    print('ecephys spike sorting: kilosort helper module')

    print('master branch -- single main KS2/KS25/KS3')

    input_file_name = args['ephys_params']['ap_band_file']
    input_file = Path(input_file_name)

    ks_output_dir_name = args['directories']['kilosort_output_directory']
    ks_output_dir = Path(ks_output_dir_name)
    ks_output_dir.mkdir(parents=True, exist_ok=True)

    start = time.time()

    # read meta data which is already of type Bunch
    md = spikeglx.read_meta_data(input_file_name.with_suffix('.meta'))
    preprocessing_function = args['pykilosort_helper_params']['preprocessing_function']
    ibl_neuropixel_version = args['pykilosort_helper_params']['ibl_neuropixel_version']

    params = get_ks_params(md,
                           preprocessing_method=preprocessing_method,
                           ibl_neuropixel_version=ibl_neuropixel_version)
    run(input_file, output_dir=ks_output_dir, **ks_params)

    execution_time = time.time() - start

    print('kilsort run time: ' + str(np.around(execution_time, 2)) + ' seconds')
    print()

    return {
        'execution_time': execution_time,
    }  # output manifest



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
