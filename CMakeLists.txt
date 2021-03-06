cmake_minimum_required(VERSION 3.0.0)
project(pyoidn VERSION 0.1.0)

set(PYBIND11_CPP_STANDARD, "-std=c++17")
find_package(pybind11 REQUIRED)
find_library(OIDN_LIB NAMES OpenImageDenoise PATHS /usr/local/lib)
SET(CMAKE_INSTALL_RPATH_USE_LINK_PATH TRUE)
include_directories(/usr/include/python3.6m/ /usr/local/include/OpenImageDenoise)

pybind11_add_module(pyoidn pyoidn.cpp)
target_link_libraries(pyoidn "${OIDN_LIB}" "${PYTHON_LIBRARY}")

# for the std::optional
target_compile_features(pyoidn PUBLIC cxx_std_17)

set(CMAKE_INSTALL_PREFIX .)
install(TARGETS pyoidn  DESTINATION install)
install(FILES bistro2_16spp_input.jpg DESTINATION install)
install(
    FILES od.py
    PERMISSIONS OWNER_EXECUTE OWNER_WRITE OWNER_READ
    DESTINATION install
)