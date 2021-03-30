#!/usr/bin/env bash

_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

pushd "${_dir}/../blog"

docker build -t gcr.io/tk8-cluster/blog .
docker push gcr.io/tk8-cluster/blog
kubectl rollout restart deployment blog -n blog

popd