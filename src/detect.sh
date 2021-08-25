#! /bin/bash

################################################################################
# Prepare
################################################################################

# Set up shell
if [ "$(echo ${VERBOSE} | tr '[:upper:]' '[:lower:]')" = 'yes' ]; then
    set -x                      # Output commands
fi
set -e                          # Abort on errors

. $CCTK_HOME/lib/make/bash_utils.sh

# Take care of requests to build the library in any case
CMAKE_DIR_INPUT=$CMAKE_DIR
if [ "$(echo "${CMAKE_DIR}" | tr '[a-z]' '[A-Z]')" = 'BUILD' ]; then
    CMAKE_BUILD=1
    CMAKE_DIR=
else
    CMAKE_BUILD=
fi

THORN=CMake

################################################################################
# Decide which libraries to link with
################################################################################

# Set up names of the libraries based on configuration variables. Also
# assign default values to variables.
# Try to find the library if build isn't explicitly requested
if [ -z "${CMAKE_BUILD}" ] && [ -z "${CMAKE_DIR}" ]; then
    # We cannot rely on the "which" command to be present,
    # as it is not installed by default in docker, etc.
    # So we use the builtin, hash. However, "hash -t" won't
    # do the job of "which" unless the location is already
    # hashed. So call "hash", then "hash -t".
    if CMAKE_PATH=$(hash cmake 2>/dev/null && hash -t cmake 2>/dev/null); then
       # TODO here is not really a good reason to strip of "bin" and it could
       # be "libexec" for all I know
       CMAKE_DIR=${CMAKE_PATH%/bin/cmake}
       echo "BEGIN MESSAGE"
       echo "Found CNake in ${CMAKE_DIR}"
       echo "END MESSAGE"
    else
        echo "BEGIN ERROR"
        echo "No cmake found in \$PATH"
        echo "END ERROR"
    fi
fi

# configure library if build was requested or is needed (no usable
# library found)
if [ -n "$CMAKE_BUILD" -o -z "${CMAKE_DIR}" ]; then
    echo "BEGIN MESSAGE"
    echo "Using bundled CMake..."
    echo "END MESSAGE"
    CMAKE_BUILD=1

    check_tools "tar patch"
    
    # Set locations
    BUILD_DIR=${SCRATCH_BUILD}/build/${THORN}
    if [ -z "${CMAKE_INSTALL_DIR}" ]; then
        INSTALL_DIR=${SCRATCH_BUILD}/external/${THORN}
    else
        echo "BEGIN MESSAGE"
        echo "Installing CMake into ${CMAKE_INSTALL_DIR}"
        echo "END MESSAGE"
        INSTALL_DIR=${CMAKE_INSTALL_DIR}
    fi
    CMAKE_DIR=${INSTALL_DIR}
else
    DONE_FILE=${SCRATCH_BUILD}/done/${THORN}
    if [ ! -e ${DONE_FILE} ]; then
        mkdir ${SCRATCH_BUILD}/done 2> /dev/null || true
        date > ${DONE_FILE}
    fi
fi

if [ -z "$CMAKE_DIR" ]; then
    echo 'BEGIN ERROR'
    echo 'ERROR in CMake configuration: Could neither find nor build library.'
    echo 'END ERROR'
    exit 1
fi

################################################################################
# Configure Cactus
################################################################################

# Pass configuration options to build script
echo "BEGIN MAKE_DEFINITION"
echo "CMAKE_BUILD          = ${CMAKE_BUILD}"
echo "CMAKE_INSTALL_DIR    = ${CMAKE_INSTALL_DIR}"
echo "END MAKE_DEFINITION"

# Pass options to Cactus
echo "BEGIN MAKE_DEFINITION"
echo "CMAKE_DIR            = ${CMAKE_DIR}"
echo "END MAKE_DEFINITION"
