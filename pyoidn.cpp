#define PYBIND11_HAS_OPTIONAL 1
#include <iostream>
#include <optional>
#include <chrono>

#include <pybind11/pybind11.h>
#include <pybind11/stl.h>
#include <pybind11/numpy.h>

#include <OpenImageDenoise/oidn.hpp>

namespace py = pybind11;

// python binding to run the denoiser
py::array_t<float> run_oidn(py::array_t<float> color, 
                            std::optional<py::array_t<float>> albedo, 
                            std::optional<py::array_t<float>> normal) {
    std::vector<float> oidn_color, oidn_albedo, oidn_normal;
    // input is an array
    py::buffer_info color_buf = color.request();
    // get the dimensions of the array: 
    //    numpy array(nrows, ncolumns) ==> image(width, height) means
    //    height = nrows, width = ncolumns
    size_t w = color_buf.shape[1];
    size_t h = color_buf.shape[0]; 
    size_t c = color_buf.shape[2];
   
    // create an image buffer from the numpy array we got from python
    oidn_color = std::vector<float> ((float *)color_buf.ptr, (float *)color_buf.ptr + w*h*c);

    // optional arguments 
    if (albedo) {
	    py::buffer_info albedo_buf = albedo.value().request();
        oidn_albedo = std::vector<float> ((float *)albedo_buf.ptr, (float *)albedo_buf.ptr + w*h*c);
    }
    else
        std::cout << "albedo_buf is null" << std::endl;

    if (normal) {
	    py::buffer_info normal_buf = normal.value().request();
        oidn_normal = std::vector<float> ((float *)normal_buf.ptr, (float *)normal_buf.ptr + w*h*c);
    }
    else
        std::cout << "normal_buf is null" << std::endl;

    // allocate space for output
    std::vector<float> oidn_output = std::vector<float>(size_t(w)*h*c);

    // initialize the denoising filter
    oidn::DeviceRef device = oidn::newDevice();
    device.commit();
    oidn::FilterRef filter = device.newFilter("RT");
    filter.set("hdr", true);

    // set the various buffers
    filter.setImage("color", oidn_color.data(), oidn::Format::Float3, w, h);
    filter.setImage("output", oidn_output.data(), oidn::Format::Float3, w, h);
    if (albedo) 
        filter.setImage("albedo", oidn_albedo.data(), oidn::Format::Float3, w, h);
    if (normal) 
        filter.setImage("normal", oidn_normal.data(), oidn::Format::Float3, w, h);

    filter.commit();

    auto initTime = std::chrono::high_resolution_clock::now();

    // denoise the image
    filter.execute();
    std::chrono::duration<double> denoiseTime = std::chrono::high_resolution_clock::now()-initTime;
    std::cout << "time to denoise: " << (1000. * denoiseTime.count()) << " msec"<< std::endl;

    // create an numpy array from the oidn output (flip w and h)
    py::array_t<float> result = py::array_t<float>({h, w, c}, (const float *) oidn_output.data());

    return result;
}

// module definition TODO: change this to MODULE from PLUGIN
PYBIND11_PLUGIN(pyoidn) {
    py::module m("pyoidn", "python binding to oidn");
    m.def("run_oidn", &run_oidn, "returns output buffer as array", py::arg("color"), py::arg("albedo")=py::none(), py::arg("normal")=py::none());
    return m.ptr();
}


// dummy main program
int main(int argc, char *argv[]) {
    return 0;
}
