DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh

docker build \
    -t matlab-oraclelinux8:2020b \
    -t registry.int.janelia.org/janeliascicomp/matlab-oraclelinux8:2020b \
    --build-arg LICENSE_SERVER=27000@e05u04.int.janelia.org \
    containers/matlab-oraclelinux8

docker build \
    -t registry.int.janelia.org/janeliascicomp/ecephys-modules:${ECEPHYS_CONTAINERS_VERSION} \
    -t ecephys-modules:${ECEPHYS_CONTAINERS_VERSION} \
    containers/ecephys-modules

docker build \
    -t registry.int.janelia.org/janeliascicomp/catgt:${ECEPHYS_CONTAINERS_VERSION} \
    -t catgt:${ECEPHYS_CONTAINERS_VERSION} \
    containers/catgt

docker build \
    -t registry.int.janelia.org/janeliascicomp/cwaves:${ECEPHYS_CONTAINERS_VERSION} \
    -t cwaves:${ECEPHYS_CONTAINERS_VERSION} \
    containers/cwaves

docker build \
    -t registry.int.janelia.org/janeliascicomp/tprime:${ECEPHYS_CONTAINERS_VERSION} \
    -t tprime:${ECEPHYS_CONTAINERS_VERSION} \
    containers/tprime

docker build \
    -t registry.int.janelia.org/janeliascicomp/kilosort:${ECEPHYS_CONTAINERS_VERSION} \
    -t kilosort:${ECEPHYS_CONTAINERS_VERSION} \
    containers/kilosort

docker build \
    -t registry.int.janelia.org/janeliascicomp/pykilosort:${ECEPHYS_CONTAINERS_VERSION} \
    -t pykilosort:${ECEPHYS_CONTAINERS_VERSION} \
    containers/pykilosort
