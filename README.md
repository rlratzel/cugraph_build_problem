# To reproduce the build problem:
* Ensure the following cmake code is uncommented:
```
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
```
* Follow build and run instructions below

# To verify the fix:
* Ensure the following cmake code is uncommented:
```
ExternalProject_Add(cugunrock
  GIT_REPOSITORY    https://github.com/rapidsai/cugunrock.git
  GIT_TAG           0b92fae6ee9026188a811b4d08915779e7c97178
  PREFIX            ${CUGUNROCK_DIR}
  CMAKE_ARGS        -DCMAKE_INSTALL_PREFIX=<INSTALL_DIR>
                    -DGUNROCK_BUILD_SHARED_LIBS=OFF
                    -DGUNROCK_BUILD_TESTS=OFF
                    -DCUDA_AUTODETECT_GENCODE=FALSE
                    -DGUNROCK_GENCODE_SM60=TRUE
                    -DGUNROCK_GENCODE_SM61=TRUE
                    -DGUNROCK_GENCODE_SM70=TRUE
                    -DGUNROCK_GENCODE_SM72=TRUE
                    -DGUNROCK_GENCODE_SM75=TRUE
  BUILD_BYPRODUCTS  ${CUGUNROCK_DIR}/lib/libgunrock.a
)
```
* Follow build and run instructions below

# Build Instructions
1. `cmake .`
2. `make`

# Run
* `./run.sh 1000`
