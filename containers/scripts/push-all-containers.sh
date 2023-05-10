DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh
source ${DIR}/set-args.sh

$RUNCMD docker push ${REGISTRY}/ecephys-modules:${ECEPHYS_VERSION}
$RUNCMD docker push ${REGISTRY}/catgt:${CATGT_VERSION}
$RUNCMD docker push ${REGISTRY}/cwaves:${CWAVES_VERSION}
$RUNCMD docker push ${REGISTRY}/tprime:${TPRIME_VERSION}
$RUNCMD docker push ${REGISTRY}/kilosort:${KILOSORT_VERSION}
$RUNCMD docker push ${REGISTRY}/pykilosort:${PYKILOSORT_VERSION}
