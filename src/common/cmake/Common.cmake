# Code for compiling flatbuffers

include(ExternalProject)

set(FLATCC_PREFIX "${CMAKE_BINARY_DIR}/src/common/flatcc-prefix/src/flatcc")

if (NOT TARGET flatcc)
  ExternalProject_Add(flatcc
    URL "https://github.com/dvidelabs/flatcc/archive/v0.4.0.tar.gz"
    INSTALL_COMMAND ""
    CMAKE_ARGS "-DCMAKE_C_FLAGS=-fPIC")
endif()

set(FLATBUFFERS_INCLUDE_DIR "${FLATCC_PREFIX}/include")
set(FLATBUFFERS_STATIC_LIB "${FLATCC_PREFIX}/lib/libflatcc.a")
set(FLATBUFFERS_COMPILER "${FLATCC_PREFIX}/bin/flatcc")

include_directories("${FLATBUFFERS_INCLUDE_DIR}")

# Custom CFLAGS

set(CMAKE_C_FLAGS "-g -Wall -Wextra -Werror=implicit-function-declaration -Wno-sign-compare -Wno-unused-parameter -Wno-type-limits -Wno-missing-field-initializers --std=c99 -D_XOPEN_SOURCE=500 -D_POSIX_C_SOURCE=200809L -fPIC -std=c99")

# Code for finding Python

message(STATUS "Trying custom approach for finding Python.")
# Start off by figuring out which Python executable to use.
find_program(CUSTOM_PYTHON_EXECUTABLE python)
message(STATUS "Found Python program: ${CUSTOM_PYTHON_EXECUTABLE}")
execute_process(COMMAND ${CUSTOM_PYTHON_EXECUTABLE} -c "import sys; print('python' + sys.version[0:3])"
                OUTPUT_VARIABLE PYTHON_LIBRARY_NAME OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "PYTHON_LIBRARY_NAME: " ${PYTHON_LIBRARY_NAME})
# Now find the Python include directories.
execute_process(COMMAND ${CUSTOM_PYTHON_EXECUTABLE} -c "from distutils.sysconfig import *; print(get_python_inc())"
                OUTPUT_VARIABLE PYTHON_INCLUDE_DIRS OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "PYTHON_INCLUDE_DIRS: " ${PYTHON_INCLUDE_DIRS})
# Now find the Python libraries. We'll start by looking near the Python
# executable. If that fails, then we'll look near the Python include
# directories.
execute_process(COMMAND ${CUSTOM_PYTHON_EXECUTABLE} -c "import sys; print(sys.exec_prefix)"
                OUTPUT_VARIABLE PYTHON_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
message(STATUS "PYTHON_PREFIX: " ${PYTHON_PREFIX})
# The name ending in "m" is for miniconda.
FIND_LIBRARY(PYTHON_LIBRARIES
             NAMES "${PYTHON_LIBRARY_NAME}" "${PYTHON_LIBRARY_NAME}m"
             HINTS "${PYTHON_PREFIX}"
             PATH_SUFFIXES "lib" "libs"
             NO_DEFAULT_PATH)
message(STATUS "PYTHON_LIBRARIES: " ${PYTHON_LIBRARIES})
# If that failed, perhaps because the user is in a virtualenv, search around
# the Python include directories.
if(NOT PYTHON_LIBRARIES)
  message(STATUS "Failed to find PYTHON_LIBRARIES near the Python executable, so now looking near the Python include directories.")
  # The name ending in "m" is for miniconda.
  FIND_LIBRARY(PYTHON_LIBRARIES
               NAMES "${PYTHON_LIBRARY_NAME}" "${PYTHON_LIBRARY_NAME}m"
               HINTS "${PYTHON_INCLUDE_DIRS}/../.."
               PATH_SUFFIXES "lib" "libs"
               NO_DEFAULT_PATH)
  message(STATUS "PYTHON_LIBRARIES: " ${PYTHON_LIBRARIES})
endif()
# If we found the Python libraries and the include directories, then continue
# on. If not, then try find_package as a last resort, but it probably won't
# work.
if(PYTHON_LIBRARIES AND PYTHON_INCLUDE_DIRS)
  message(STATUS "The custom approach for finding Python succeeded.")
  SET(PYTHONLIBS_FOUND TRUE)
else()
  message(WARNING "The custom approach for finding Python failed. Defaulting to find_package.")
  find_package(PythonInterp REQUIRED)
  find_package(PythonLibs ${PYTHON_VERSION_STRING} EXACT REQUIRED)
  set(CUSTOM_PYTHON_EXECUTABLE ${PYTHON_EXECUTABLE})
endif()

message(STATUS "Using CUSTOM_PYTHON_EXECUTABLE: " ${CUSTOM_PYTHON_EXECUTABLE})
message(STATUS "Using PYTHON_LIBRARIES: " ${PYTHON_LIBRARIES})
message(STATUS "Using PYTHON_INCLUDE_DIRS: " ${PYTHON_INCLUDE_DIRS})

# Common libraries

set(COMMON_LIB "${CMAKE_BINARY_DIR}/src/common/libcommon.a"
    CACHE STRING "Path to libcommon.a")

include_directories("${CMAKE_CURRENT_LIST_DIR}/..")
include_directories("${CMAKE_CURRENT_LIST_DIR}/../thirdparty/")
include_directories("${CMAKE_CURRENT_LIST_DIR}/../lib/python")
