#!/usr/bin/env bash

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pushd "${_dir}/.."

docker build -t gcr.io/tk8-cluster/blog .
docker push gcr.io/tk8-cluster/blog

popd