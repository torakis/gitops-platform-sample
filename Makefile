# gitops-platform-sample — Make targets for local development
# Usage: make <target>

CLUSTER_NAME ?= gitops-sample
REPO_ROOT   := $(shell pwd)

.PHONY: local-kind-up local-k3d-up argocd-install bootstrap bootstrap-argocd deploy-dev deploy-staging deploy-prod logs destroy check-prereqs port-forward print-hosts help

help:
	@echo "gitops-platform-sample — Make targets"
	@echo ""
	@echo "  make local-kind-up   Create kind cluster + nginx ingress"
	@echo "  make local-k3d-up    Create k3d cluster"
	@echo "  make argocd-install  Install Argo CD via Helm (kind)"
	@echo "  make bootstrap      Build images + load into cluster"
	@echo "  make bootstrap-argocd  Apply Argo CD local bootstrap"
	@echo "  make deploy-dev     Apply dev overlay"
	@echo "  make deploy-staging  Apply staging overlay (create orders-db-secret first)"
	@echo "  make deploy-prod    Apply prod overlay (create orders-db-secret first)"
	@echo "  make logs           Tail orders-api logs"
	@echo "  make destroy        Delete kind/k3d cluster"
	@echo "  make check-prereqs  Verify required tools"
	@echo "  make port-forward   Start Argo CD + app port-forwards in background"
	@echo "  make print-hosts    Show /etc/hosts entries to add"

local-kind-up:
	./scripts/kind-bootstrap.sh

local-k3d-up:
	./scripts/k3d-up.sh

argocd-install:
	./scripts/argocd-install.sh

bootstrap:
	./scripts/build-images-local.sh

bootstrap-argocd:
	./scripts/bootstrap.sh

deploy-dev:
	./scripts/apply-dev-k3d.sh

deploy-staging:
	./scripts/apply-staging.sh

deploy-prod:
	./scripts/apply-prod.sh

logs:
	kubectl logs -n dev deployment/orders-api -f

destroy:
	kind delete cluster --name $(CLUSTER_NAME) 2>/dev/null || \
	k3d cluster delete $(CLUSTER_NAME) 2>/dev/null || \
	echo "Cluster $(CLUSTER_NAME) not found or already deleted"

check-prereqs:
	./scripts/check-prereqs.sh

port-forward:
	./scripts/port-forward.sh

print-hosts:
	./scripts/generate-local-hosts.sh
