# Force x86_64 platform (required for reMarkable SDK on Apple Silicon Macs)
FROM --platform=linux/amd64 ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install basic dependencies
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    file \
    make \
    tar \
    gzip \
    python3 \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Create working directory
WORKDIR /build

# Copy and install reMarkable SDK from toolchains folder
# Download SDK from: https://developer.remarkable.com
# Place the .sh file in the toolchains/ folder before building
ARG SDK_FILE
COPY ${SDK_FILE} /tmp/sdk-installer.sh

# Install the SDK
RUN chmod +x /tmp/sdk-installer.sh && \
    /tmp/sdk-installer.sh -d /opt/remarkable-sdk -y && \
    rm /tmp/sdk-installer.sh

# Set up environment variables for the SDK
# These will be sourced when the container runs
ENV SDK_ENV_FILE=/opt/remarkable-sdk/environment-setup-cortexa53-crypto-remarkable-linux

# Create entrypoint script
RUN echo '#!/bin/bash\n\
if [ -f "$SDK_ENV_FILE" ]; then\n\
    source "$SDK_ENV_FILE"\n\
fi\n\
exec "$@"' > /entrypoint.sh && chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/bin/bash"]
