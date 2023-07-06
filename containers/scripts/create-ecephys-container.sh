DIR=$(cd "$(dirname "$0")"; pwd)
# to build without cache, add option --no-cache

source ${DIR}/container-versions.sh

RUNCMD=
if [[ "$1" == "-n" ]]; then
    RUNCMD=echo
fi

$RUNCMD docker build --no-cache \
    -t ecephys-modules:${ECEPHYS_VERSION} \
    -t registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION} \
    containers/ecephys-modules


