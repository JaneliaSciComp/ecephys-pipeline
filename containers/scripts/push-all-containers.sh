DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh

docker push registry.int.janelia.org/janeliascicomp/ecephys-modules:${ECEPHYS_CONTAINERS_VERSION}
docker push registry.int.janelia.org/janeliascicomp/catgt:${ECEPHYS_CONTAINERS_VERSION}
docker push registry.int.janelia.org/janeliascicomp/cwaves:${ECEPHYS_CONTAINERS_VERSION}
docker push registry.int.janelia.org/janeliascicomp/tprime:${ECEPHYS_CONTAINERS_VERSION}
docker push registry.int.janelia.org/janeliascicomp/kilosort:${ECEPHYS_CONTAINERS_VERSION}
docker push registry.int.janelia.org/janeliascicomp/pykilosort:${ECEPHYS_CONTAINERS_VERSION}
