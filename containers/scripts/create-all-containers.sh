TOOLS_VERSION=1.0.1
docker build \
    -t matlab-centos8:2020b \
    -t registry.int.janelia.org/janeliascicomp/matlab-centos8:2020b \
    --build-arg LICENSE_SERVER=27000@e05u04.int.janelia.org \
    containers/matlab-dockerfile-centos8

docker build \
    -t registry.int.janelia.org/janeliascicomp/ecephys-modules:${TOOLS_VERSION} \
    -t ecephys-modules:${TOOLS_VERSION} \
    containers/ecephys-modules

docker build \
    -t registry.int.janelia.org/janeliascicomp/catgt:${TOOLS_VERSION} \
    -t catgt:${TOOLS_VERSION} \
    containers/catgt

docker build \
    -t registry.int.janelia.org/janeliascicomp/cwaves:${TOOLS_VERSION} \
    -t cwaves:${TOOLS_VERSION} \
    containers/cwaves

docker build \
    -t registry.int.janelia.org/janeliascicomp/tprime:${TOOLS_VERSION} \
    -t tprime:${TOOLS_VERSION} \
    containers/tprime

docker build \
    -t registry.int.janelia.org/janeliascicomp/kilosort:${TOOLS_VERSION} \
    -t kilosort:${TOOLS_VERSION} \
    containers/kilosort
