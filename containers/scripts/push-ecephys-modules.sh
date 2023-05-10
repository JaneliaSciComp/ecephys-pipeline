DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh
source ${DIR}/set-args.sh

$RUNCMD docker push ${REGISTRY}/ecephys-modules:${ECEPHYS_VERSION}
