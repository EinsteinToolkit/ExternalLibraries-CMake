#! /bin/bash

################################################################################
# Build
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

# Set locations
THORN=CMake
NAME=cmake-3.14.2
SRCDIR="$(dirname $0)"
BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
if [ -z "${CMAKE_INSTALL_DIR}" ]; then
    INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
else
    echo "BEGIN MESSAGE"
    echo "Installing CMake into ${CMAKE_INSTALL_DIR}"
    echo "END MESSAGE"
    INSTALL_DIR=${CMAKE_INSTALL_DIR}
fi
DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
CMAKE_DIR=${INSTALL_DIR}

echo "CMake: Preparing directory structure..."
cd ${SCRATCH_BUILD}
mkdir build external done 2> /dev/null || true
rm -rf ${BUILD_DIR} ${INSTALL_DIR}
mkdir ${BUILD_DIR} ${INSTALL_DIR}

# Build core library
echo "CMake: Unpacking archive..."
pushd ${BUILD_DIR}
${TAR?} xf ${SRCDIR}/../dist/${NAME}.tar

echo "CMake: Configuring..."
cd ${NAME}

# force build with gcc and not $CC which may be across compiler
CFLAGS=-O2
CXXFLAGS=-O2
unset LD
unset LDFLAGS
unset LIBS
./configure CXX=g++ CC=gcc --prefix=${INSTALL_DIR}

echo "CMake: Building..."
${MAKE}

echo "CMake: Installing..."
${MAKE} install
popd

echo "CMake: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "CMake: Done."
