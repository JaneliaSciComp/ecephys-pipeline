DIR=$(cd "$(dirname "$0")"; pwd)
# to build without cache, add option --no-cache

source ${DIR}/container-versions.sh
source ${DIR}/set-args.sh

echo "Build containers/ecephys-modules"
$RUNCMD docker build \
    ${PLATFORM_ARG} \
    -t ${REGISTRY}/ecephys-modules:${ECEPHYS_VERSION} \
    containers/ecephys-modules

echo "Build containers/catgt"
$RUNCMD docker build \
    --build-arg ECEPHYS_CONTAINER_REPO=${REGISTRY} \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    ${PLATFORM_ARG} \
    -t ${REGISTRY}/catgt:${CATGT_VERSION} \
    containers/catgt

echo "Build containers/cwaves"
$RUNCMD docker build \
    --build-arg ECEPHYS_CONTAINER_REPO=${REGISTRY} \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    ${PLATFORM_ARG} \
    -t ${REGISTRY}/cwaves:${CWAVES_VERSION} \
    containers/cwaves

echo "Build containers/tprime"
$RUNCMD docker build \
    --build-arg ECEPHYS_CONTAINER_REPO=${REGISTRY} \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    ${PLATFORM_ARG} \
    -t ${REGISTRY}/tprime:${TPRIME_VERSION} \
    containers/tprime

echo "Build containers/kilosort"
$RUNCMD docker build \
    --build-arg ECEPHYS_CONTAINER_REPO=${REGISTRY} \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    ${PLATFORM_ARG} \
    -t ${REGISTRY}/kilosort:${KILOSORT_VERSION} \
    containers/kilosort

echo "Build containers/pykilosort"
$RUNCMD docker build \
    --build-arg ECEPHYS_CONTAINER_REPO=${REGISTRY} \
    --build-arg ECEPHYS_VERSION=${ECEPHYS_VERSION} \
    ${PLATFORM_ARG} \
    -t ${REGISTRY}/pykilosort:${PYKILOSORT_VERSION} \
    containers/pykilosort
