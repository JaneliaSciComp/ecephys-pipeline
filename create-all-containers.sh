docker build \
    -t matlab-centos8:2020b \
    -t registry.int.janelia.org/janeliascicomp/matlab-centos8:2020b \
    --build-arg LICENSE_SERVER=27000@e05u04.int.janelia.org \
    containers/matlab-dockerfile-centos8

docker build \
    -t registry.int.janelia.org/janeliascicomp/ecephys-modules:1.0.0 \
    -t ecephys-modules:1.0.0 \
    containers/ecephys-modules

docker build \
    -t registry.int.janelia.org/janeliascicomp/catgt:1.0.0 \
    -t catgt:1.0.0 \
    containers/catgt

docker build \
    -t registry.int.janelia.org/janeliascicomp/cwaves:1.0.0 \
    -t cwaves:1.0.0 \
    containers/cwaves

docker build \
    -t registry.int.janelia.org/janeliascicomp/tprime:1.0.0 \
    -t tprime:1.0.0 \
    containers/tprime

docker build \
    -t registry.int.janelia.org/janeliascicomp/kilosort:1.0.0 \
    -t kilosort:1.0.0 \
    containers/kilosort
