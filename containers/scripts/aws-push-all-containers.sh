DIR=$(cd "$(dirname "$0")"; pwd)

source ${DIR}/container-versions.sh

RUNCMD=
if [[ "$1" == "-n" ]]; then
    RUNCMD=echo
fi

$RUNCMD docker tag ecephys-modules:${ECEPHYS_VERSION} public.ecr.aws/janeliascicomp/ecephys/ecephys-modules:${ECEPHYS_VERSION}
$RUNCMD docker tag catgt:${CATGT_VERSION} public.ecr.aws/janeliascicomp/ecephys/catgt:${CATGT_VERSION}
$RUNCMD docker tag cwaves:${CWAVES_VERSION} public.ecr.aws/janeliascicomp/ecephys/cwaves:${CWAVES_VERSION}
$RUNCMD docker tag tprime:${TPRIME_VERSION} public.ecr.aws/janeliascicomp/ecephys/tprime:${TPRIME_VERSION}
$RUNCMD docker tag kilosort:${KILOSORT_VERSION} public.ecr.aws/janeliascicomp/ecephys/kilosort:${KILOSORT_VERSION}
$RUNCMD docker tag pykilosort:${PYKILOSORT_VERSION} public.ecr.aws/janeliascicomp/ecephys/pykilosort:${PYKILOSORT_VERSION}

$RUNCMD docker push public.ecr.aws/janeliascicomp/ecephys/ecephys-modules:${ECEPHYS_VERSION}
$RUNCMD docker push public.ecr.aws/janeliascicomp/ecephys/catgt:${CATGT_VERSION}
$RUNCMD docker push public.ecr.aws/janeliascicomp/ecephys/cwaves:${CWAVES_VERSION}
$RUNCMD docker push public.ecr.aws/janeliascicomp/ecephys/tprime:${TPRIME_VERSION}
$RUNCMD docker push public.ecr.aws/janeliascicomp/ecephys/kilosort:${KILOSORT_VERSION}
$RUNCMD docker push public.ecr.aws/janeliascicomp/ecephys/pykilosort:${PYKILOSORT_VERSION}
