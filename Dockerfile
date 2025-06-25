# Build the manager binary

# BEGIN -- workaround lack of go-toolset for golang 1.23
ARG GOLANG_IMAGE=docker.io/library/golang:1.23
FROM ${GOLANG_IMAGE} AS golang

FROM registry.access.redhat.com/ubi8/ubi@sha256:19eae3d00adb37538a62b9bd093fd1e01dc6197f1925e960224244a1ed52bfb5 AS builder
ARG GOLANG_VERSION=1.23.0

ARG TARGETOS TARGETARCH
# RUN echo "GOOS=${TARGETOS} GOARCH=${TARGETARCH}"

# Install system dependencies
RUN dnf upgrade -y && dnf install -y \
    gcc \
    make \
    openssl-devel \
    git \
    && dnf clean all && rm -rf /var/cache/yum

# Install Go
ENV PATH=/usr/local/go/bin:$PATH

COPY --from=golang /usr/local/go /usr/local/go
# End of Go versioning workaround

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum
COPY ./Makefile ./Makefile
RUN go mod download

# Copy the Go sources
COPY main.go main.go
COPY pkg/ pkg/

# Build
USER root
RUN CGO_ENABLED=1 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH} make go-build-for-image

FROM registry.access.redhat.com/ubi8/ubi-minimal:8.8
WORKDIR /
COPY --from=builder /workspace/manager .

USER 65532:65532
ENTRYPOINT ["/manager"]
