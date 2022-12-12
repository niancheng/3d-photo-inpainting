#!/bin/bash

docker_dir="$(dirname $0)"

usage(){
    echo "usage: sh generate_runtime_docker.sh --SOME_ARG ARG_VALUE"
    echo "   ";
    echo "   --reg                 : registry (default docker.io)";
    echo "   --ns                  : namespace (default zhijiandocker)";
    echo "   --rep                 : repository (default 3d-photo-inpainting)";
    echo "   --ver                 : version (default 0.0.0)";
#    echo "   --env                 : running env (cpu/cuda10.1/cuda10.2/cuda11/cuda11.2)";
#    echo "   --trt                 : with TensorRT (default false, true/false)";
#    echo "   --py                  : python version (3.6/3.7/3.8) ";
#    echo "   --pd                  : paddle version (2.1.2/2.2.0/2.2.2/2.3.0)";
#    echo "   --sv                  : serving version (0.6.3/0.7.0/0.8.3/0.9.0";
    echo "   --ft                  : feature name (default run, env/run)";
    echo "   --name                : image name (default {namespace}/{repository}:{version}-{feature})";
#    echo "   --port                : port id (default 00)";
    echo "   -h | --help           : helper";
}

parse_args(){
    # positional args
    args=()

    # named args
    while [ "$1" != "" ]; do
        case "$1" in
            --reg )               registry="$2";          shift;;
            --ns )               namespace="$2";          shift;;
            --rep )               repository="$2";          shift;;
            --ver )               version="$2";          shift;;
            --env )            env="$2";     shift;;
            --trt )            trt="$2";     shift;;
            --py )           python="$2";      shift;;
            --pd )            paddle="$2";      shift;;
            --sv )        serving="$2";    shift;;
            --ft )              feature="$2";    shift;;
            --name )           image_name="$2";    shift;;
            --port )           port_id="$2";    shift;;
            -h | --help )         usage;            exit;; # quit and show usage
            * )                 args+=("$1")             # if no match, add it to the positional args
        esac
        shift # move to next kv pair
    done
    # restore positional args
    set -- "${args[@]}"

    # set positionals to vars
    positional_1="${args[0]}"
    positional_2="${args[1]}"

    # validate required args
#    if [[ -z "${namespace}" || -z "${repository}" || -z "${paddle}" || -z "${env}" || -z "${python}" || -z "${serving}" ]]; then
#        echo "Invalid arguments. namespace or repository or paddle or env or python or serving is missing."
#        usage
#        exit;
#    fi

    if [[ -z "${namespace}" ]]; then
        namespace="zhijiandocker"
        echo "version is not assigned, so it will be set ($namespace)."
    fi

    if [[ -z "${repository}" ]]; then
        repository="3d-photo-inpainting"
        echo "version is not assigned, so it will be set ($repository)."
    fi

    if [[ -z "${registry}" ]]; then
        repo="$namespace/$repository"
        registry="(NULL)"
        echo "registry is not assigned, so it will be set Default."
    else
        repo="$registry/$namespace/$repository"
    fi

    if [[ -z "${version}" ]]; then
        version="0.0.0"
        echo "version is not assigned, so it will be set ($version)."
    fi

    if [[ -z "${feature}" ]]; then
        feature="env"
        echo "feature is not assigned, so it will be set ($feature)."
    fi

#    if [[ -z "${trt}" ]]; then
#        trt="false"
#        echo "trt is not assigned, so it will be set ($trt)."
#    fi

    if [[ -z "${image_name}" ]]; then
        image_name="$repo:$version-$feature"
        echo "image_name is not assigned, so it will be set ($image_name)."
    fi

#    if [[ -z "${port_id}" ]]; then
#        port_id="00"
#        echo "port_id is not assigned, so it will be set ($port_id)."
#    fi
}

download(){
    export https_proxy=172.28.184.184:7890
    if [ ! -d "$docker_dir/hub/facebookresearch_WSL-Images_main" ]; then
        echo "Download https://github.com/facebookresearch/WSL-Images/zipball/main to $docker_dir/hub/main.zip"
        wget -q --show-progress -O "$docker_dir"/hub/main.zip https://github.com/facebookresearch/WSL-Images/zipball/main \
            && unzip -q "$docker_dir"/hub/main.zip -d "$docker_dir"/hub \
            && mv "$docker_dir"/hub/facebookresearch-WSL-Images* "$docker_dir"/hub/facebookresearch_WSL-Images_main \
            && rm -f "$docker_dir"/hub/main.zip
    fi


    if [ ! -f "$docker_dir/hub/checkpoints/ig_resnext101_32x8-c38310e5.pth" ]; then
        echo "Download https://download.pytorch.org/models/ig_resnext101_32x8-c38310e5.pth to $docker_dir/hub/checkpoints/ig_resnext101_32x8-c38310e5.pth"
        wget -q --show-progress -P "$docker_dir"/hub/checkpoints https://download.pytorch.org/models/ig_resnext101_32x8-c38310e5.pth
    fi
}

run(){
    parse_args "$@"

    base_image='pytorch/pytorch:1.12.1-cuda11.3-cudnn8-runtime'
    if [ $feature = 'env' ]; then
        entrypoint="run_xvfb.sh"
#    else
#        entrypoint="entrypoint\/startup.sh"
    fi

    sed -e "s|<<base_image>>|$base_image|g" \
        -e "s|<<entrypoint>>|$entrypoint|g" \
        "$docker_dir"/Dockerfile.template > "$docker_dir"/Dockerfile.tmp

    download
    cp "$docker_dir"/../requirements.txt "$docker_dir"/requirements.txt
    docker build -t "$image_name" -f "$docker_dir"/Dockerfile.tmp "$docker_dir"
}

run "$@"