from argschema.schemas import DefaultSchema
from argschema.fields import Nested, InputDir, OutputDir, String, Float, Dict, Int, NumpyArray, Bool


def noOpValidate(value):
    # This is a no-op validator because Schema tries to validate inputDir types 
    # even if validate is set to None
    None


class EphysParams(DefaultSchema):
    sample_rate = Float(required=True, default=30000.0,
                        help='Sample rate of Neuropixels AP band continuous data')
    lfp_sample_rate = Float(require=True, default=2500.0,
                            help='Sample rate of Neuropixels LFP band continuous data')
    bit_volts = Float(required=True, default=0.195,
                      help='Scalar required to convert int16 values into microvolts')
    num_channels = Int(required=True, default=384,
                       help='Total number of channels in binary data files')
    reference_channels = NumpyArray(required=False, default=[
                                    36, 75, 112, 151, 188, 227, 264, 303, 340, 379], help='Reference channels on Neuropixels probe (numbering starts at 0)')
    template_zero_padding = Int(required=True,
                                default=21, help='Zero-padding on templates output by Kilosort')
    vertical_site_spacing = Float(required=False, default=20e-6,
                                  help='Vertical site spacing in meters')
    probe_type = String(required=False, default='NP1', help='3A, 3B2, NP1')
    # putting the run_name and gate_string in the common ephys params
    # so that they could be accessible to other modules,
    # but unlike the catGT module here they are not mandatory
    run_name = String(required=False, allow_none=True,
                      help='undecorated run name (no g or t indices')
    gate_string = String(required=False, default='0', help='gate string')
    lfp_band_file = String(required=False,
                           help='Location of LFP band binary file')
    ap_band_file = String(required=False,
                          allow_none=True,  # tprime does not use ap_band so we should allow nulls (cg)
                          help='Location of AP band binary file')
    reorder_lfp_channels = Bool(required=False, default=True,
                                help='Should we fix the ordering of LFP channels (necessary for 3a probes following extract_from_npx modules)')
    cluster_group_file_name = String(required=False,
                                     default='cluster_group.tsv')


class Directories(DefaultSchema):
    ecephys_directory = InputDir(
        help='Location of the ecephys_spike_sorting directory containing modules directory')
    npx_directory = InputDir(help='Location of raw neuropixels binary files')
    kilosort_output_directory = OutputDir(
        help='Location of Kilosort output files')
    extracted_data_directory = OutputDir(
        help='Location for NPX/CatGT processed files')
    kilosort_output_tmp = OutputDir(validate=None, help='Location for temporary KS output')


class CommonFiles(DefaultSchema):
    probe_json = String(help='Location of probe JSON file')
    settings_json = String(
        help='Location of settings JSON written by extract_from_npx module')


class WaveformMetricsFile(DefaultSchema):
    waveform_metrics_file = String(help='Location of waveform metrics CSV')


class ClusterMetricsFile(DefaultSchema):
    cluster_metrics_file = String(help='Location of cluster metrics CSV')
