DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh

RUNCMD=
if [[ "$1" == "-n" ]]; then
    RUNCMD=echo
fi


$RUNCMD docker push registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION}
