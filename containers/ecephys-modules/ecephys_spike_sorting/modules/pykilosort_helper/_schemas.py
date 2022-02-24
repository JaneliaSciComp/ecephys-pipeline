from argschema import ArgSchema, ArgSchemaParser 
from argschema.schemas import DefaultSchema
from argschema.fields import Nested, InputDir, String, Float, Dict, Int, Bool, NumpyArray
from ...common.schemas import EphysParams, Directories, CommonFiles


class PyKilosortHelperParameters(DefaultSchema):
    preprocessing_function = String(required=True, default='kilosort2', help='Preprocessing function')
    ibl_neuropixel_version = Float(required=True, default=1, help='Neuropixel version used by IBL. Valid values so far are: 1, 2, 2.4')
    alf_location = String(required=False, default='', help='ALF location under the results directory')


class InputParameters(ArgSchema):
    pykilosort_helper_params = Nested(PyKilosortHelperParameters)
    directories = Nested(Directories)
    ephys_params = Nested(EphysParams)
    common_files = Nested(CommonFiles)
    

class OutputSchema(DefaultSchema): 
    input_parameters = Nested(InputParameters, 
                              description=("Input parameters the module " 
                                           "was run with"), 
                              required=True) 
 
 
class OutputParameters(OutputSchema): 
    message = String()
    execution_time = Float()
    