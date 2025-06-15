#!/bin/bash
set -e

# Source the environment variables
source ./ci/build.env

# Read version from version.txt
if [[ -f "./ci/version.txt" ]]; then
  VERSION=$(cat ./ci/version.txt | tr -d '[:space:]')
else
  VERSION="1.0.0"
fi

# Encode apps.json as base64
APPS_JSON_BASE64=$(base64 -w 0 ./ci/apps.json)

# Print all values for debugging
echo "Using the following values:"
echo "REGISTRY: $REGISTRY"
echo "PROJECT_NAMESPACE: $PROJECT_NAMESPACE"
echo "IMAGE: $IMAGE"
echo "VERSION: $VERSION"
echo "FRAPPE_REPO: $FRAPPE_REPO"
echo "FRAPPE_VERSION: $FRAPPE_VERSION"
echo "PY_VERSION: $PY_VERSION"
echo "NODEJS_VERSION: $NODEJS_VERSION"
echo "DOCKERFILE: $DOCKERFILE"

# Verify the Dockerfile exists
if [ ! -f "builds/$DOCKERFILE" ]; then
  echo "::error::Dockerfile not found at builds/$DOCKERFILE"
  exit 1
fi

# Build and push the image
docker buildx build \
  --push \
  --platform linux/amd64 \
  --tag "$REGISTRY/$PROJECT_NAMESPACE/$IMAGE:$VERSION" \
  --tag "$REGISTRY/$PROJECT_NAMESPACE/$IMAGE:latest" \
  --build-arg "FRAPPE_PATH=$FRAPPE_REPO" \
  --build-arg "FRAPPE_BRANCH=$FRAPPE_VERSION" \
  --build-arg "PYTHON_VERSION=$PY_VERSION" \
  --build-arg "NODE_VERSION=$NODEJS_VERSION" \
  --build-arg "APPS_JSON_BASE64=$APPS_JSON_BASE64" \
  --build-arg "CACHE_BUST=$GITHUB_RUN_ID" \
  --label "org.opencontainers.image.source=https://github.com/$GITHUB_REPOSITORY" \
  --file "builds/$DOCKERFILE" \
  builds
