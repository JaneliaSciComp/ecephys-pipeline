
additional_args=()

JANELIA_REGISTRY=registry.int.janelia.org/ecephys
AWS_REGISTRY=public.ecr.aws/janeliascicomp/ecephys

PLATFORM_ARG=
REGISTRY=${AWS_REGISTRY}

while [[ $# > 0 ]]; do
    key="$1"
    shift # past the key
    case ${key} in
        --use-janelia-registry)
            REGISTRY=${JANELIA_REGISTRY}
            ;;
        --platform)
            PLATFORM=$1
            shift
            PLATFORM_ARG="--platform=${PLATFORM}"
            ;;
        -n)
            RUNCMD=echo
            ;;
        -h)
            echo "$0 [--use-janelia-registry] [--platform <platform>] [-n] [-h]"
            exit 0
            ;;
        *)
            additional_args=($additional_args $key)
            ;;
    esac
done
