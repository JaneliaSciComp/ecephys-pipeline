# Parameters

The pipeline supports many types of parameters for customization to your compute environment and data. These can all be specified on the command line using the standard syntax `--argument="value"` or `--argument "value"`. You can also use any option supported by Nextflow itself. Note that certain arguments (i.e. those interpreted by Nextflow) use a single dash instead of two.

## Environment Variables

You can export variables into your environment before calling the pipeline, or set them on the same line like this:

    TMPDIR=/opt/tmp ./examples/demo_small.sh /opt/demo_small

Note that the demo scripts set all these directories relative to the TMPDIR by default, so setting TMPDIR sets everything else to the same location.

| Variable   | Default | Description                                                                           |
|------------|---------|---------------------------------------------------------------------------------------|
| TMPDIR | /tmp | Directory used for temporary files by certain processes like MATLAB's MCR Cache. |
| SINGULARITY_TMPDIR | /tmp | Directory where Docker images are downlaoded and converted to Singularity Image Format. Needs to be large enough to accomodate several GB, so moving it out of /tmp is sometimes necessary. |
| SINGULARITY_CACHEDIR | $HOME/.singularity_cache | Directory where Singularity images are cached. This needs to be accessible from all nodes. |

## Global Parameters

| Argument   | Default | Description                                                                           |
|------------|---------|---------------------------------------------------------------------------------------|
| --data_dir | | Path to the directory containing SGLX runs. | 
| --results_dir | `data_dir` value | Path to the directory containing pipeline outputs. |
| --config_dir | `results_dir` value | Path where json config files for different steps are generated.|  
| --runs | | JSON file containing runs specs to be processed. |
| --probe_steps | `"catGT_helper, kilosort_helper, kilosort_postprocessing, noise_templates, psth_events,  mean_waveforms, quality_metrics, tPrime_helper"` | Comma separated list of steps to run for each probe|
| --runtime_opts | | Runtime options for Singularity must include mounts for any directory paths you are using. You can also pass the --nv flag here to make use of NVIDIA GPU resources. For example, `--nv -B /your/data/dir -B /your/output/dir` |
| --probe_type | `NP1` | |
| --ks_ver | 3.0 | Kilosort version |
| --ks_thresholds_by_region | `{ "default_value": "[9,9]", "cortex": "[9,9]", "medulla": "[9,9]", "thalamus": "[9,9]"}` | Kilosort threshold values defined based on the brain region. The default values are based on Kilosort v3, but they can be overwritten by setting the value for ks_thresholds_by_region to a JSON file |
| --ks_csb_seed | 1 | Kilosort csb seed |
| --ks_lt_seed | 1 | Kilosort lt seed |
| --ks_remove_dups |  0 | |
| --ks_save_rez |  1 | |
| --ks_copy_fproc |  0 | |
| --ks_minfr_goodchannels |  0.1 | |
| --ks_template_radius_um |  163 | |
| --ks_whitening_radius_um |  163 | |
| --catgt_car_mode | `gbldmx` | |
| --catgt_cmd_args | `"-prb_fld -out_prb_fld -aphipass=300 -gfix=0,0.10,0.02"` | |
| --catgt_loccar_min | 40 | |
| --catgt_loccar_max | 160 | |
| --ni_present | true | NI data is available |
| --ni_extract_cmd_args | `"-XA=0,1,3,500 -XA=1,3,3,0 -XD=4,1,50 -XD=4,2,1.7 -XD=4,3,5"` | |
| --event_ex_cmd_arg | `"XD=4,1,50"` | |
| --c_waves_snr_um | 160 | |
| --has_aux_data | true | |
| --sync_period | 1.0 | |
| --to_stream_sync_cmd_args | `"SY=0,-1,6,500"` | |
| --ni_stream_sync_cmd_args | `"XA=0,1,3,500"` | |
