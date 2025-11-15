#!/bin/bash

echo "=== Deployer .NET MVC App till Kubernetes ==="

# Kontrollera att vi är anslutna till rätt kluster
echo "Nuvarande kontext:"
kubectl config current-context

read -p "Är detta rätt kluster? (ja/nej): " answer
if [ "$answer" != "ja" ]; then
    echo "Avbryter deployment"
    exit 1
fi

# Skapa namespace
echo ""
echo "Skapar namespace..."
kubectl apply -f ../k8s-manifests/namespace.yaml

# Skapa ConfigMap
echo ""
echo "Skapar ConfigMap..."
kubectl apply -f ../k8s-manifests/configmap.yaml

# Deploya applikationen
echo ""
echo "Deployer applikation..."
kubectl apply -f ../k8s-manifests/deployment.yaml

# Skapa Service
echo ""
echo "Skapar Service..."
kubectl apply -f ../k8s-manifests/service.yaml

# Vänta på att pods ska bli redo
echo ""
echo "Väntar på att pods ska bli redo..."
kubectl wait --for=condition=ready pod -l app=dotnet-app -n dotnet-app --timeout=120s

# Visa status
echo ""
echo "=== Deployment klar! ==="
echo ""
echo "Status:"
kubectl get all -n dotnet-app

echo ""
echo "För att få Load Balancer URL, kör:"
echo "kubectl get svc dotnet-service -n dotnet-app"