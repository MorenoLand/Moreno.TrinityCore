#!/bin/bash
# MorenoCore4 Build Script
# Supports: Ubuntu/Debian, CentOS/RHEL/Fedora, Arch Linux
# Usage: sudo ./build.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
INSTALL_PREFIX="${INSTALL_PREFIX:-/root/Wotlk}"
BUILD_TYPE="${BUILD_TYPE:-Release}"
BUILD_THREADS="${BUILD_THREADS:-$(nproc)}"

echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}MorenoCore4 Build Script${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: This script must be run as root${NC}"
    echo "Please run: sudo ./build.sh"
    exit 1
fi

# Detect distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        DISTRO=$ID
        VERSION=$VERSION_ID
    elif [ -f /etc/redhat-release ]; then
        DISTRO="rhel"
    elif [ -f /etc/arch-release ]; then
        DISTRO="arch"
    else
        DISTRO="unknown"
    fi

    echo -e "${YELLOW}Detected OS: $DISTRO $VERSION${NC}"
}

# Install dependencies based on distro
install_dependencies() {
    echo -e "\n${GREEN}Installing dependencies...${NC}"

    case $DISTRO in
        ubuntu|debian)
            apt-get update
            apt-get install -y \
                git cmake make gcc g++ clang \
                libssl-dev libmysqlclient-dev libreadline-dev \
                zlib1g-dev libbz2-dev libboost-all-dev \
                mysql-server unrar unzip
            ;;

        fedora)
            dnf install -y \
                git cmake make gcc gcc-c++ clang \
                openssl-devel mysql-devel readline-devel \
                zlib-devel bzip2-devel boost-devel \
                mysql-server unrar unzip
            ;;

        centos|rhel)
            # Enable EPEL repository for additional packages
            yum install -y epel-release
            yum install -y \
                git cmake3 make gcc gcc-c++ \
                openssl-devel mysql-devel readline-devel \
                zlib-devel bzip2-devel boost-devel \
                mysql-server unrar unzip
            # Use cmake3 on CentOS/RHEL
            ln -sf /usr/bin/cmake3 /usr/bin/cmake 2>/dev/null || true
            ;;

        arch|manjaro)
            pacman -Syu --noconfirm
            pacman -S --noconfirm \
                git cmake make gcc clang \
                openssl mariadb-libs readline \
                zlib bzip2 boost boost-libs \
                mariadb unrar unzip
            ;;

        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
            echo "Please install dependencies manually:"
            echo "  - git, cmake, make, gcc, g++/clang"
            echo "  - libssl-dev, libmysqlclient-dev, libreadline-dev"
            echo "  - zlib-dev, libbz2-dev, boost (1.67+)"
            exit 1
            ;;
    esac

    echo -e "${GREEN}Dependencies installed successfully!${NC}"
}

# Check if we're already in the repo
check_repo() {
    if [ ! -f "CMakeLists.txt" ] || [ ! -d "src" ]; then
        echo -e "${RED}Error: This script must be run from the MorenoCore4 directory${NC}"
        echo "Current directory: $(pwd)"
        exit 1
    fi

    echo -e "${GREEN}Repository found: $(pwd)${NC}"
}

# Build the project
build_project() {
    echo -e "\n${GREEN}Configuring build...${NC}"

    # Create build directory
    mkdir -p build
    cd build

    # Clean previous CMake cache if requested
    if [ "$CLEAN_BUILD" = "1" ]; then
        echo -e "${YELLOW}Performing clean build...${NC}"
        rm -rf CMakeCache.txt CMakeFiles
    fi

    # Configure with CMake
    cmake .. \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DCONF_DIR="$INSTALL_PREFIX" \
        -DTOOLS=0 \
        -DWITH_WARNINGS=1 \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE"

    echo -e "\n${GREEN}Building servers (this may take 15-30 minutes)...${NC}"
    echo -e "${YELLOW}Using $BUILD_THREADS threads${NC}"

    # Build
    make -j"$BUILD_THREADS" authserver worldserver

    echo -e "\n${GREEN}Build completed successfully!${NC}"
}

# Install binaries
install_binaries() {
    echo -e "\n${GREEN}Installing binaries to $INSTALL_PREFIX...${NC}"

    # Install
    make install

    # Create required directories
    mkdir -p "$INSTALL_PREFIX/data" "$INSTALL_PREFIX/logs"

    # Copy configs if they don't exist
    if [ ! -f "$INSTALL_PREFIX/authserver.conf" ]; then
        cp "$INSTALL_PREFIX/authserver.conf.dist" "$INSTALL_PREFIX/authserver.conf"
        echo -e "${YELLOW}Created authserver.conf - please edit with your database credentials${NC}"
    fi

    if [ ! -f "$INSTALL_PREFIX/worldserver.conf" ]; then
        cp "$INSTALL_PREFIX/worldserver.conf.dist" "$INSTALL_PREFIX/worldserver.conf"
        echo -e "${YELLOW}Created worldserver.conf - please edit with your database credentials${NC}"
    fi

    echo -e "${GREEN}Installation completed!${NC}"
}

# Show binary info
show_info() {
    echo -e "\n${GREEN}======================================${NC}"
    echo -e "${GREEN}Build Summary${NC}"
    echo -e "${GREEN}======================================${NC}"

    if [ -f "$INSTALL_PREFIX/worldserver" ] && [ -f "$INSTALL_PREFIX/authserver" ]; then
        echo -e "${GREEN}Binaries installed:${NC}"
        ls -lh "$INSTALL_PREFIX/authserver" "$INSTALL_PREFIX/worldserver" | awk '{print "  " $9 ": " $5}'

        echo -e "\n${GREEN}Installation directory:${NC}"
        echo "  $INSTALL_PREFIX"

        echo -e "\n${YELLOW}Next steps:${NC}"
        echo "  1. Edit configuration files:"
        echo "     nano $INSTALL_PREFIX/worldserver.conf"
        echo "     nano $INSTALL_PREFIX/authserver.conf"
        echo ""
        echo "  2. Setup databases (see BUILD_INSTRUCTIONS.md)"
        echo ""
        echo "  3. Extract map data to $INSTALL_PREFIX/data/"
        echo ""
        echo "  4. Run servers:"
        echo "     cd $INSTALL_PREFIX"
        echo "     ./authserver"
        echo "     ./worldserver"
    else
        echo -e "${RED}Error: Binaries not found at $INSTALL_PREFIX${NC}"
        exit 1
    fi
}

# Main execution
main() {
    detect_distro

    # Parse command line arguments
    SKIP_DEPS=0
    CLEAN_BUILD=0

    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-deps)
                SKIP_DEPS=1
                shift
                ;;
            --clean)
                CLEAN_BUILD=1
                shift
                ;;
            --help)
                echo "Usage: sudo ./build.sh [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --skip-deps    Skip dependency installation"
                echo "  --clean        Perform clean build (remove CMake cache)"
                echo "  --help         Show this help message"
                echo ""
                echo "Environment variables:"
                echo "  INSTALL_PREFIX   Installation directory (default: /root/Wotlk)"
                echo "  BUILD_TYPE       Build type: Release or RelWithDebInfo (default: Release)"
                echo "  BUILD_THREADS    Number of build threads (default: nproc)"
                echo ""
                echo "Examples:"
                echo "  sudo ./build.sh                    # Full build with dependencies"
                echo "  sudo ./build.sh --skip-deps        # Build only (skip deps)"
                echo "  sudo ./build.sh --clean            # Clean build"
                echo "  sudo INSTALL_PREFIX=/opt/wow ./build.sh  # Custom install location"
                exit 0
                ;;
            *)
                echo -e "${RED}Unknown option: $1${NC}"
                echo "Run './build.sh --help' for usage information"
                exit 1
                ;;
        esac
    done

    check_repo

    if [ "$SKIP_DEPS" -eq 0 ]; then
        install_dependencies
    else
        echo -e "${YELLOW}Skipping dependency installation (--skip-deps)${NC}"
    fi

    build_project
    install_binaries
    show_info

    echo -e "\n${GREEN}All done! MorenoCore4 is ready.${NC}"
}

# Run main function
main "$@"
