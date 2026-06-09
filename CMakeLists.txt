cmake_minimum_required(VERSION 3.18)

project(tomocupy LANGUAGES CXX)

set(EXTENSION_WRAPPER swig
    CACHE STRING "Method used for wrapping Python C/CXX extensions.")
set_property(CACHE EXTENSION_WRAPPER PROPERTY STRINGS swig pybind11)

add_subdirectory(src)
