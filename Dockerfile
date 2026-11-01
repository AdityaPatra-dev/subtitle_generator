# Production Dockerfile for AI Subtitle Generator CLI
FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    ffmpeg \
    libsqlite3-0 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy compiled native CLI binary
COPY build/cli/subtitle-generator /usr/local/bin/subtitle-generator
RUN chmod +x /usr/local/bin/subtitle-generator

# Standard media mounting paths
WORKDIR /media
RUN mkdir -p /media/input /media/output

ENTRYPOINT ["subtitle-generator"]
CMD ["--help"]
