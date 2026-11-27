#!/usr/bin/env bash
# Deploy the SUT to a kind cluster and run the API suite against it (microservices testing on Kubernetes).
# Locally, stop the compose stack first: both use host ports 3001-3003 and 8080.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/tools/apache-maven-3.9.9/bin:$PATH"
cluster=bank-qa

docker build -q -t bank-qa/accounts:ci sut/accounts-service
docker build -q -t bank-qa/transfers:ci sut/transfers-service
docker build -q -t bank-qa/chat:ci -f sut/inquiry-chat/Dockerfile sut
docker build -q -t bank-qa/web:ci sut/web

kind get clusters | grep -qx "$cluster" || kind create cluster --name "$cluster" --config deploy/k8s/kind-config.yaml --wait 120s
for image in accounts transfers chat web; do kind load docker-image "bank-qa/$image:ci" --name "$cluster"; done
kubectl --context "kind-$cluster" apply -f deploy/k8s/sut.yaml
for deployment in postgres accounts transfers mock-llm chat web; do
  kubectl --context "kind-$cluster" rollout status "deployment/$deployment" --timeout=180s
done
kubectl --context "kind-$cluster" get pods -o wide

# kubectl inside the suite (resilience scenario) must talk to this cluster
kubectl config use-context "kind-$cluster"
SUT_RUNTIME=k8s scripts/run-suite.sh api local
