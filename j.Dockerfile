# Thanks to https://github.com/chemidy/smallest-secured-golang-docker-image
#
# STEP 1 build executable binary
#
FROM golang:alpine as builder

# Set the current working directory inside the container
WORKDIR /app

# Copy app files
COPY . /app

# 1. Install git, ca-certs, and timezone data
# 2. Write commit hash to a file
# 3. Build the static binary
RUN apk update \
    && apk add --no-cache \
      git \
      ca-certificates \
      tzdata \
    && update-ca-certificates \
    && git rev-parse --short HEAD > commit \
    && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build \
      -ldflags='-w -s -extldflags "-static"' \
      -mod=readonly \
      -a \
      -o yourapp .

#
# STEP 2 build small image
#
FROM scratch

# Copy zoneinfo for time zone support
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
# Copy ca-certs for SSL support
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
# Copy binary and app files
COPY --from=builder /app/yourapp /yourapp
COPY --from=builder /app/commit /commit

ENTRYPOINT ["/yourapp"]
