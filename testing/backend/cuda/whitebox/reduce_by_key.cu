#include <unittest/unittest.h>
#include <thrust/system/cuda/detail/reduce_by_key.h>
#include <thrust/sequence.h>
#include <thrust/iterator/zip_iterator.h>

// this test exists to reproduce issue #480

// TODO test
//   block sizes [32, 64, ... 512]
//   input types
//   input patterns

using namespace unittest;

template<typename Tuple>
struct TuplePlus
{
  __host__ __device__
  Tuple operator()(Tuple x, Tuple y) const
  {
    using namespace thrust;
    return make_tuple(get<0>(x) + get<0>(y),
                      get<1>(x) + get<1>(y));
  }
}; // end TuplePlus

template <typename InputIterator1,
          typename InputIterator2,
          typename OutputIterator1,
          typename OutputIterator2,
          typename BinaryPredicate,
          typename BinaryFunction>
  thrust::pair<OutputIterator1,OutputIterator2>
  cuda_reduce_by_key(InputIterator1 keys_first, 
                     InputIterator1 keys_last,
                     InputIterator2 values_first,
                     OutputIterator1 keys_output,
                     OutputIterator2 values_output,
                     BinaryPredicate binary_pred,
                     BinaryFunction binary_op)
{
  thrust::system::cuda::tag system;
  return thrust::system::cuda::detail::reduce_by_key
        ( system,
          keys_first, keys_last,
          values_first,
          keys_output,
          values_output,
          binary_pred,
          binary_op);
}

template <typename T>
struct TestCudaZipIteratorReduceByKey
{
  void operator()(const size_t n)
  {
    using namespace thrust;

    host_vector<T> h_data0(n); thrust::sequence(h_data0.begin(), h_data0.end()); // = unittest::random_integers<bool>(n);
    host_vector<T> h_data1 = unittest::random_integers<T>(n);
    host_vector<T> h_data2 = unittest::random_integers<T>(n);
    host_vector<T> h_data3(n,0);
    host_vector<T> h_data4(n,0);
    host_vector<T> h_data5(n,0);
    host_vector<T> h_data6(n,0);

    device_vector<T> d_data0 = h_data0;
    device_vector<T> d_data1 = h_data1;
    device_vector<T> d_data2 = h_data2;
    device_vector<T> d_data3(n,0);
    device_vector<T> d_data4(n,0);
    device_vector<T> d_data5(n,0);
    device_vector<T> d_data6(n,0);

    typedef tuple<T,T> Tuple;

    // run on host
    reduce_by_key
        ( make_zip_iterator(make_tuple(h_data0.begin(), h_data0.begin())),
          make_zip_iterator(make_tuple(h_data0.end(),   h_data0.end())),
          make_zip_iterator(make_tuple(h_data1.begin(), h_data2.begin())),
          make_zip_iterator(make_tuple(h_data3.begin(), h_data4.begin())),
          make_zip_iterator(make_tuple(h_data5.begin(), h_data6.begin())),
          equal_to<Tuple>(),
          TuplePlus<Tuple>());

    // run on device
    cuda_reduce_by_key
        ( make_zip_iterator(make_tuple(d_data0.begin(), d_data0.begin())),
          make_zip_iterator(make_tuple(d_data0.end(),   d_data0.end())),
          make_zip_iterator(make_tuple(d_data1.begin(), d_data2.begin())),
          make_zip_iterator(make_tuple(d_data3.begin(), d_data4.begin())),
          make_zip_iterator(make_tuple(d_data5.begin(), d_data6.begin())),
          equal_to<Tuple>(),
          TuplePlus<Tuple>());

    KNOWN_FAILURE;
    //ASSERT_EQUAL(h_data3, d_data3);
    //ASSERT_EQUAL(h_data4, d_data4);
    //ASSERT_EQUAL(h_data5, d_data5);
    //ASSERT_EQUAL(h_data6, d_data6);
  }
};
VariableUnitTest<TestCudaZipIteratorReduceByKey, unittest::type_list<unsigned long long> > TestCudaZipIteratorReduceByKeyInstance;


