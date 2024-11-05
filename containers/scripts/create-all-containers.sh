DIR=$(cd "$(dirname "$0")"; pwd)
# to build without cache, add option --no-cache

source ${DIR}/container-versions.sh

RUNCMD=
if [[ "$1" == "-n" ]]; then
    RUNCMD=echo
fi

$RUNCMD docker build \
    -t ecephys-modules:${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION} \
    containers/ecephys-modules

$RUNCMD docker build \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/catgt:${CATGT_VERSION} \
    -t catgt:${CATGT_VERSION} \
    containers/catgt

$RUNCMD docker build \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/cwaves:${CWAVES_VERSION} \
    -t cwaves:${CWAVES_VERSION} \
    containers/cwaves

$RUNCMD docker build \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/tprime:${TPRIME_VERSION} \
    -t tprime:${TPRIME_VERSION} \
    containers/tprime

$RUNCMD docker build \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    --build-arg LICENSE_SERVER=27000@vm7142.int.janelia.org \
    -t registry.int.janelia.org/ecephys/kilosort:${KILOSORT_VERSION} \
    -t kilosort:${KILOSORT_VERSION} \
    containers/kilosort

$RUNCMD docker build \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/pykilosort:${PYKILOSORT_VERSION} \
    -t pykilosort:${PYKILOSORT_VERSION} \
    containers/pykilosort
    
$RUNCMD docker build \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/ks4:${KS4_VERSION} \
    -t ks4:${KS4_VERSION} \
    containers/ks4
