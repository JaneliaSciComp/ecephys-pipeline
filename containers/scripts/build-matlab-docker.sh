docker build \
    -t matlab-oraclelinux8:2020b \
    -t janeliascicomp/matlab-oraclelinux8:2020b \
    -t registry.int.janelia.org/janeliascicomp/matlab-oraclelinux8:2020b \
    --build-arg LICENSE_SERVER=27000@vm7142.int.janelia.org \
    containers/matlab-oraclelinux8
