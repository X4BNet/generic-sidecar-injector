FROM golang:1-alpine AS build

WORKDIR /sidecarinjector
COPY go.mod go.sum ./

RUN go mod download

COPY . ./
COPY pkg ./pkg

RUN apk --no-cache add git

RUN GIT_HASH=$(git rev-parse --short HEAD) && GIT_TAG=$(git tag | tail -1) && \
    CGO_ENABLED=0 && GOOS=linux && GOARCH=amd64 && \
    echo "GIT_HASH=$GIT_HASH" && echo "GIT_TAG=$GIT_TAG" && \
    go build -ldflags  "-X 'github.com/salesforce/generic-sidecar-injector/pkg/metrics.gitHash=$GIT_HASH' -X 'github.com/salesforce/generic-sidecar-injector/pkg/metrics.gitTag=$GIT_TAG' -s" -installsuffix cgo -o sidecarinjector ./cmd/sidecarinjector

FROM golang:1-alpine
COPY --from=build /sidecarinjector/sidecarinjector /sidecarinjector
ENV PATH="/:${PATH}" \
    GOGC=20
CMD ["/sidecarinjector"]
