#!/usr/bin/env bash
set -e

echo "Checking Prerequisites..."

TOOLS=("docker" "kind" "kubectl" "helm" "terraform" "conftest" "git")

for tool in "${TOOLS[@]}"; do
    if ! command -v $tool &> /dev/null; then
        echo "ERROR: $tool is not installed or not in PATH."
        echo "Please install $tool to run this demo."
        exit 1
    else
        version=$("$tool" --version 2>&1 | head -n1)
        echo " - $tool found ($version)"
    fi
done

if ! docker info &> /dev/null; then
    echo "ERROR: Docker daemon is not running."
    exit 1
fi

echo "All prerequisites met."
