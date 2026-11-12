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
NAME=cmake-3.23.2
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

cd ${NAME}

echo "CMake: Applying patches..."
${PATCH?} -p1 < ${SRCDIR}/../dist/gcc16.patch
# Some (ancient but still used) versions of patch don't support the
# patch format used here but also don't report an error using the exit
# code. So we use this patch to test for this
${PATCH?} -p1 < ${SRCDIR}/../dist/patchtest.patch
if [ ! -e .patch_tmp ]; then
    echo 'BEGIN ERROR'
    echo 'The version of patch is too old to understand this patch format.'
    echo 'Please set the PATCH environment variable to a more recent '
    echo 'version of the patch command.'
    echo 'END ERROR'
    exit 1
fi
rm -f .patch_tmp

echo "CMake: Configuring..."

# force build with gcc and not $CC which may be across compiler
export CC=gcc
export CFLAGS=-O2
export CXX=g++
export CXXFLAGS=-O2
unset LIBS
./configure --prefix=${INSTALL_DIR}

echo "CMake: Building..."
${MAKE}

echo "CMake: Installing..."
${MAKE} install
popd

echo "CMake: Cleaning up..."
rm -rf ${BUILD_DIR}

date > ${DONE_FILE}
echo "CMake: Done."
