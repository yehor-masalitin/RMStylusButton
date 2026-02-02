#!/bin/bash
set -e

# Docker build script for reMarkable cross-compilation on macOS

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="remarkable-builder"
TOOLCHAINS_DIR="$SCRIPT_DIR/toolchains"

echo "=== reMarkable Docker Build Script ==="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker Desktop."
    exit 1
fi

# Function to build Docker image
build_image() {
    echo "Building Docker image with reMarkable SDK..."
    echo ""
    
    # Check if toolchains directory exists
    if [ ! -d "$TOOLCHAINS_DIR" ]; then
        echo "Error: toolchains/ directory not found."
        echo ""
        echo "Please create it and download the SDK:"
        echo "  1. mkdir -p toolchains"
        echo "  2. Download SDK from: https://developer.remarkable.com/links"
        echo "  3. Place the .sh file in toolchains/"
        echo ""
        exit 1
    fi
    
    # Find SDK files in toolchains directory
    SDK_FILES=("$TOOLCHAINS_DIR"/*.sh)
    
    if [ ! -f "${SDK_FILES[0]}" ]; then
        echo "Error: No SDK (.sh) file found in toolchains/ directory."
        echo ""
        echo "Please download the SDK:"
        echo "  1. Visit: https://developer.remarkable.com/links"
        echo "  2. Download the appropriate SDK for your device"
        echo "  3. Place it in the toolchains/ folder"
        echo ""
        echo "Example for reMarkable 2:"
        echo "  toolchains/remarkable-production-image-5.4.107-rm2-public-x86_64-toolchain.sh"
        exit 1
    fi
    
    # Check if multiple SDKs exist
    local SDK_FILE
    local SDK_BASENAME
    
    if [ ${#SDK_FILES[@]} -eq 1 ]; then
        # Only one SDK found
        SDK_FILE="${SDK_FILES[0]}"
        SDK_BASENAME=$(basename "$SDK_FILE")
        
        echo "Found SDK: $SDK_BASENAME"
        echo ""
        read -p "Use this SDK? (y/n): " confirm
        
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "Build cancelled."
            exit 0
        fi
    else
        # Multiple SDKs found - show menu
        echo "Found ${#SDK_FILES[@]} SDKs in toolchains/:"
        echo ""
        
        local i=1
        for sdk in "${SDK_FILES[@]}"; do
            echo "  $i) $(basename "$sdk")"
            ((i++))
        done
        
        echo ""
        read -p "Select SDK (1-${#SDK_FILES[@]}): " selection
        
        # Validate selection
        if ! [[ "$selection" =~ ^[0-9]+$ ]] || [ "$selection" -lt 1 ] || [ "$selection" -gt ${#SDK_FILES[@]} ]; then
            echo "Error: Invalid selection."
            exit 1
        fi
        
        # Get selected SDK (arrays are 0-indexed)
        SDK_FILE="${SDK_FILES[$((selection-1))]}"
        SDK_BASENAME=$(basename "$SDK_FILE")
        
        echo ""
        echo "Selected: $SDK_BASENAME"
    fi
    
    echo ""
    echo "Building Docker image..."
    
    # Build with SDK file as build argument
    # Use --platform linux/amd64 for Apple Silicon Macs (reMarkable SDK is x86_64 only)
    docker build \
        --platform linux/amd64 \
        --build-arg SDK_FILE="toolchains/$SDK_BASENAME" \
        -t "$IMAGE_NAME" \
        "$SCRIPT_DIR"
    
    echo ""
    echo "✓ Docker image built successfully: $IMAGE_NAME"
}

# Function to compile the project
compile() {
    echo "Compiling project in Docker container..."
    
    docker run --rm \
        -v "$SCRIPT_DIR:/project" \
        -w /project \
        "$IMAGE_NAME" \
        bash -c "source /opt/remarkable-sdk/environment-setup-* && make clean && make"
    
    echo ""
    echo "✓ Build complete!"
    echo "✓ Binary: RMStylusButton/RMStylusButton"
    echo "✓ Tarball: RMStylusButton.tar.gz"
    echo ""
    echo "You can now copy RMStylusButton.tar.gz to your reMarkable device."
}

# Function to verify the binary
verify() {
    if [ -f "$SCRIPT_DIR/RMStylusButton/RMStylusButton" ]; then
        echo ""
        echo "Binary information:"
        file "$SCRIPT_DIR/RMStylusButton/RMStylusButton"
    fi
}

# Main menu
case "${1:-}" in
    build-image)
        build_image
        ;;
    compile)
        compile
        verify
        ;;
    all)
        build_image
        compile
        verify
        ;;
    clean)
        echo "Cleaning build artifacts..."
        make clean
        echo "✓ Clean complete"
        ;;
    shell)
        echo "Starting interactive shell in Docker container..."
        docker run --rm -it \
            -v "$SCRIPT_DIR:/project" \
            -w /project \
            "$IMAGE_NAME" \
            /bin/bash
        ;;
    *)
        echo "Usage: $0 {build-image|compile|all|clean|shell}"
        echo ""
        echo "Commands:"
        echo "  build-image  - Build the Docker image with SDK"
        echo "  compile      - Compile the project using Docker"
        echo "  all          - Build image and compile"
        echo "  clean        - Clean build artifacts"
        echo "  shell        - Open interactive shell in container"
        echo ""
        echo "Quick start:"
        echo "  1. Download SDK to toolchains/ folder"
        echo "  2. ./docker-build.sh build-image"
        echo "  3. ./docker-build.sh compile"
        exit 1
        ;;
esac
