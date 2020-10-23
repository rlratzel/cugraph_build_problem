#include <iostream>
#include <thrust/iterator/zip_iterator.h>
#include <thrust/device_vector.h>
#include <thrust/sort.h>
#include <thrust/tuple.h>


void is_a_thrust_bug() {
  std::cout << "START is_a_thrust_bug" << std::endl;

  std::cout << "CUDA LAST ERROR (0): "<<cudaGetLastError()<<std::endl;

  const int N = 5105039;
  thrust::device_vector<int> p_srcs(N, 0);
  thrust::device_vector<int> p_dsts(N, 0);
  thrust::device_vector<float> p_weights(N, 0.0);

  std::cout << "CUDA LAST ERROR (1): "<<cudaGetLastError()<<std::endl;

  std::cout << " -- stable_sort_by_key start" << std::endl;
  thrust::stable_sort_by_key(thrust::device,
                             p_dsts.begin(), p_dsts.end(),
                             thrust::make_zip_iterator(thrust::make_tuple(p_srcs.begin(), p_weights.begin())));
  std::cout << " -- stable_sort_by_key done" << std::endl;
  std::cout << "CUDA LAST ERROR (2): "<<cudaGetLastError()<<std::endl;

  std::cout << "DONE is_a_thrust_bug" << std::endl;
}

#include <gunrock/gunrock.h>
void hits() {
   int x[2] = {0};
   int y[2] = {0};
   float a[2] = {0.0};
   float b[2] = {0.0};

   ::hits(0, 0, x, y, 0, a, b);
}
