---
title: "Docker Multi Arch Advanced"
date: 2024-09-25T11:20:46+02:00
#draft: true
---

## Cross compile to multiple architectures

We'll use Go as an example, because the compiler easily supports cross compilation.
The goal is to run the compiler on our native architecture - which is fast.
Then, we copy the built executable into an architecture specific image.

```Dockerfile
# Run the builder on the native architecture of the building computer
FROM --platform=$BUILDPLATFORM golang AS builder

# Copy EzBackup and fetch dependencies as source files
WORKDIR /build/
COPY . /build/
RUN go mod download

# Architecture to build the executable for (set by "buildx")
# This is where the build process splits, everything before this is cached/executed once!
# TODO DOes this make sense? WOuldn't we also want to cross-compile for each and _then_ simply copy to each platform?
ARG TARGETOS TARGETARCH

# Build
RUN GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/tool

# Create final platform-specific image
FROM scratch
COPY --from=builder /out/ /app/
ENTRYPOINT ["/app/tool"]
CMD ["--help"]
```

The above file uses the `BUILDPLATFORM`, `TARGETOS` and `TARGETARCH`.
These are set by [Docker itself](todo-ref) and can be used in our build process.
This makes the Dockerfile more flexible, it works the same whether we run it on our ARM based MacOS or the x86 based GitHub runner.

The `--platform=$BUILDPLATFORM` instruction at the start of our file instructs `docker buildx` to start the build _only_ on our native architecture.
This happens even if multiple architectures are specified with the `--platforms` argument to buildx.

The next step defines two build arguments `TARGETOS` and `TARGETARCH`.
These do NOT need to be specified manually, as mentioned above.
From here, the build process splits off into one for each combination of these two variables. 
--- TODO verify this is true, rather than just the cache being reused from the intial run)


## Different base-images

```Dockerfile
# Different source images for each platform
# Stolen from https://github.com/docker/buildx/discussions/1928
FROM --platform=linux/amd64 ghcr.io/gotify/server AS build-amd64
FROM --platform=linux/arm64 ghcr.io/gotify/server-arm64 AS build-arm64
FROM --platform=linux/arm/v7 ghcr.io/gotify/server-arm7 AS build-arm

# Run the actual build for the specific platform
FROM build-$TARGETARCH
# NOTE: Need to re-declare this to make available _inside_ image build
ARG TARGETARCH

# TODO just added here to keep consistency - does this work?
RUN GOARCH=$TARGETARCH go build -o /out/tool
```

This is a similar situation as above, but we need to use a different base image for each architecture.
This could be because we need different libraries for runtime or because the base image is from a time when multi arch images weren't available yet.

We'll initially define which image to use for which platform and give them a name.
The name is then dynamically built using the `TARGETARCH` variable.

To use the `TARGETARCH` variable in the `RUN` instruction, we need to [define it again](https://docs.docker.com/reference/dockerfile/#scope) with `ARG`:

> An `ARG` instruction goes out of scope at the end of the build stage where it was defined. To use an argument in multiple stages, each stage must include the `ARG` instruction.

A new stage is started with the `FROM build-$TARGETARCH` instruction, so we need to repeat `ARG` again.

### References

- https://docs.docker.com/build/building/multi-platform/#cross-compilation
- https://www.docker.com/blog/multi-arch-build-and-images-the-simple-way/

- Contribute to Gotify? https://github.com/gotify/server/issues/257
