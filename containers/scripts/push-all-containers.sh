DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh

RUNCMD=
if [[ "$1" == "-n" ]]; then
    RUNCMD=echo
fi


$RUNCMD docker push registry.int.janelia.org/ecephys/ecephys-modules:${ECEPHYS_VERSION}
$RUNCMD docker push registry.int.janelia.org/ecephys/catgt:${CATGT_VERSION}
$RUNCMD docker push registry.int.janelia.org/ecephys/cwaves:${CWAVES_VERSION}
$RUNCMD docker push registry.int.janelia.org/ecephys/tprime:${TPRIME_VERSION}
$RUNCMD docker push registry.int.janelia.org/ecephys/kilosort:${KILOSORT_VERSION}
$RUNCMD docker push registry.int.janelia.org/ecephys/pykilosort:${PYKILOSORT_VERSION}
