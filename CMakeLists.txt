cmake_minimum_required(VERSION 3.0.0)
project(pyoidn VERSION 0.1.0)

find_package(pybind11 REQUIRED)
find_library(PYTHON3_LIB NAMES python PATHS /usr/lib/python3.6/config-3.6m-x86_64-linux-gnu/)
find_library(OIDN_LIB NAMES OpenImageDenoise PATHS /usr/local/lib)

include_directories(/usr/include/python3.6m/ /usr/local/include/OpenImageDenoise)

pybind11_add_module(pyoidn pyoidn.cpp)
target_link_libraries(pyoidn "${OIDN_LIB}" "${PYTHON3_LIB}")

# for the std::optional
target_compile_features(pyoidn PUBLIC cxx_std_17)

install(FILES od.py DESTINATION bin)
