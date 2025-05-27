#!/bin/sh
# deploy.sh - Automates the deployment of Kubernetes resources for the automationsaan project
#
# This script applies all required Kubernetes manifests in the correct order:
# 1. Creates the namespace (namespace.yaml) to logically isolate resources.
# 2. Creates the Docker registry secret (secret.yaml) for pulling private images (e.g., from JFrog).
# 3. Deploys the application (deployment.yaml) to manage pods and containers.
# 4. Exposes the application via a Service (service.yaml) for network access.

kubectl apply -f namespace.yaml      # Ensure the namespace exists before deploying other resources
kubectl apply -f secret.yaml         # Create the image pull secret for private registry authentication
kubectl apply -f deployment.yaml     # Deploy the application pods
kubectl apply -f service.yaml        # Expose the application via a Kubernetes Service