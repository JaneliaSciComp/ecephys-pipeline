docker build \
    -t matlab-oraclelinux8:2022 \
    -t janeliascicomp/matlab-oraclelinux8:2022 \
    -t registry.int.janelia.org/janeliascicomp/matlab-oraclelinux8:2022 \
    --build-arg LICENSE_SERVER=27000@vm7142.int.janelia.org \
    containers/matlab-oraclelinux8
