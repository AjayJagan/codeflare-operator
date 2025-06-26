# Build the manager binary
FROM registry.access.redhat.com/ubi8/go-toolset:1.23 AS builder

ARG TARGETOS TARGETARCH

USER root

# Install system dependencies
RUN dnf upgrade -y && dnf install -y \
    gcc \
    make \
    openssl-devel \
    git \
    && dnf clean all && rm -rf /var/cache/yum

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
COPY ./Makefile ./Makefile
RUN go mod download

# Copy the Go sources
COPY main.go main.go
COPY pkg/ pkg/

USER root
RUN CGO_ENABLED=1 GOOS=linux GOARCH=${TARGETARCH:-amd64} make go-build-for-image

FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
WORKDIR /
COPY --from=builder /workspace/manager .

USER 65532:65532
ENTRYPOINT ["/manager"]
