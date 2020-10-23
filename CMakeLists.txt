
cmake_minimum_required(VERSION 3.12 FATAL_ERROR)

project(CUGRAPH_BUILD_PROBLEM LANGUAGES C CXX CUDA)

include(FetchContent)

# - THRUST/CUB
message("Fetching Thrust")

FetchContent_Declare(
    thrust
    GIT_REPOSITORY https://github.com/thrust/thrust.git
    # August 28, 2020
    GIT_TAG        52a8bda46c5c2128414d1d47f546b486ff0be2f0
)

find_package(CUDA)

###################################################################################################
# Check for aarch64 vs workstation architectures
if(CMAKE_SYSTEM_PROCESSOR MATCHES "aarch64")
  message(STATUS "CMAKE Detected aarch64 CPU architecture, selecting appropriate gencodes")
  # This is being build for Linux4Tegra or SBSA ARM64 CUDA
  set(GPU_ARCHS "62") # Default minimum CUDA GenCode - not supported by gunrock
  if(CUDA_VERSION_MAJOR GREATER_EQUAL 9)
    set(GPU_ARCHS "${GPU_ARCHS};72")
    set(GUNROCK_GENCODE "-DGUNROCK_GENCODE_SM72=TRUE")
  endif()
  if(CUDA_VERSION_MAJOR GREATER_EQUAL 11)
    # This is probably for SBSA CUDA, or a next gen Jetson
    set(GPU_ARCHS "${GPU_ARCHS};75;80")
    set(GUNROCK_GENCODE "${GUNROCK_GENCODE} -DGUNROCK_GENCODE_SM75=TRUE -DGUNROCK_GENCODE_SM80=TRUE ")
  endif()

else()
  message(STATUS "CMAKE selecting appropriate gencodes for x86 or ppc64 CPU architectures")
  # System architecture was not aarch64,
  # this is datacenter or workstation class hardware
  set(GPU_ARCHS "60") # Default minimum supported CUDA gencode
  set(GUNROCK_GENCODE "-DGUNROCK_GENCODE_SM60=TRUE")
  if(CUDA_VERSION_MAJOR GREATER_EQUAL 9)
    set(GPU_ARCHS "${GPU_ARCHS};70")
    set(GUNROCK_GENCODE "${GUNROCK_GENCODE} -DGUNROCK_GENCODE_SM70=TRUE")
  endif()
  if(CUDA_VERSION_MAJOR GREATER_EQUAL 10)
    set(GPU_ARCHS "${GPU_ARCHS};75")
    set(GUNROCK_GENCODE "${GUNROCK_GENCODE} -DGUNROCK_GENCODE_SM75=TRUE")
  endif()
  if(CUDA_VERSION_MAJOR GREATER_EQUAL 11)
    set(GPU_ARCHS "${GPU_ARCHS};80")
    set(GUNROCK_GENCODE "${GUNROCK_GENCODE} -DGUNROCK_GENCODE_SM80=TRUE")
  endif()

endif()

# https://cmake.org/cmake/help/v3.0/module/ExternalProject.html
include(ExternalProject)

# - GUNROCK
set(CUGUNROCK_DIR ${CMAKE_CURRENT_BINARY_DIR}/cugunrock CACHE STRING
  "Path to cugunrock repo")


################################################################################
# ${GUNROCK_GENCODE} does not expand properly, resulting in default gunrock
# build arch of 60 and a crash.
#
# Explicitly specifying each gunrock build arch works, no crash.
################################################################################
ExternalProject_Add(cugunrock
  GIT_REPOSITORY    https://github.com/rapidsai/cugunrock.git
  GIT_TAG           0b92fae6ee9026188a811b4d08915779e7c97178
  PREFIX            ${CUGUNROCK_DIR}
  CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                    -DGUNROCK_BUILD_SHARED_LIBS=OFF
                    -DGUNROCK_BUILD_TESTS=OFF
                    -DCUDA_AUTODETECT_GENCODE=FALSE
                    ${GUNROCK_GENCODE}
  BUILD_BYPRODUCTS  ${CUGUNROCK_DIR}/lib/libgunrock.a
)
# ExternalProject_Add(cugunrock
#   GIT_REPOSITORY    https://github.com/rapidsai/cugunrock.git
#   GIT_TAG           0b92fae6ee9026188a811b4d08915779e7c97178
#   PREFIX            ${CUGUNROCK_DIR}
#   CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
#                     -DGUNROCK_BUILD_SHARED_LIBS=OFF
#                     -DGUNROCK_BUILD_TESTS=OFF
#                     -DCUDA_AUTODETECT_GENCODE=FALSE
#                     -DGUNROCK_GENCODE_SM60=TRUE
#                     -DGUNROCK_GENCODE_SM61=TRUE
#                     -DGUNROCK_GENCODE_SM70=TRUE
#                     -DGUNROCK_GENCODE_SM72=TRUE
#                     -DGUNROCK_GENCODE_SM75=TRUE
#   BUILD_BYPRODUCTS  ${CUGUNROCK_DIR}/lib/libgunrock.a
# )
################################################################################
################################################################################


add_library(gunrock STATIC IMPORTED)

add_dependencies(gunrock cugunrock)

set_property(TARGET gunrock PROPERTY IMPORTED_LOCATION ${CUGUNROCK_DIR}/lib/libgunrock.a)

find_package(OpenMP)
if(OpenMP_FOUND)
    # find_package(OPenMP) does not automatically add OpenMP flags to CUDA
    set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -Xcompiler=${OpenMP_CXX_FLAGS}")
endif(OpenMP_FOUND)

message("-- Building for GPU_ARCHS = ${GPU_ARCHS}")
foreach(arch ${GPU_ARCHS})
  set(CMAKE_CUDA_FLAGS "${CMAKE_CUDA_FLAGS} -gencode arch=compute_${arch},code=sm_${arch}")
endforeach()

add_executable(REPRO "${CMAKE_CURRENT_SOURCE_DIR}/repro.cu")
target_include_directories(REPRO
                           PRIVATE
                           "${THRUST_INCLUDE_DIR}"
                           "${LIBCUDACXX_INCLUDE_DIR}"
                           "${CMAKE_CUDA_TOOLKIT_INCLUDE_DIRECTORIES}"
                           )
add_library(thrustcheck SHARED
            thrustcheck.cu
           )
target_link_libraries(REPRO
                      PRIVATE
                      thrustcheck
                      cudart
                      cuda
                      )

add_dependencies(thrustcheck cugunrock)
target_include_directories(thrustcheck
    PRIVATE
    "${CUGUNROCK_DIR}/include"
)
target_link_libraries(thrustcheck PRIVATE
                    gunrock
)
if(OpenMP_CXX_FOUND)
target_link_libraries(thrustcheck PRIVATE
    ${OpenMP_CXX_LIB_NAMES})
endif(OpenMP_CXX_FOUND)
