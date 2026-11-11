cmake_minimum_required(VERSION 3.16)
project(titan-tour VERSION 2.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml)
find_package(LayerShellQt REQUIRED)

set(SOURCES
    src/main.cpp
    src/tourcontroller.cpp
)

set(HEADERS
    src/tourcontroller.h
)

set(RESOURCES
    resources.qrc
)

add_executable(titan-tour
    ${SOURCES}
    ${HEADERS}
    ${RESOURCES}
)

target_include_directories(titan-tour PRIVATE src)

target_link_libraries(titan-tour PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    LayerShellQt::Interface
)

set_target_properties(titan-tour PROPERTIES
    BUILD_RPATH "/usr/lib;${CMAKE_CURRENT_SOURCE_DIR}/../../airootfs/usr/lib;${CMAKE_CURRENT_SOURCE_DIR}/../../titan-ui/build"
    INSTALL_RPATH "/usr/lib;${CMAKE_CURRENT_SOURCE_DIR}/../../airootfs/usr/lib;${CMAKE_CURRENT_SOURCE_DIR}/../../titan-ui/build"
)

install(TARGETS titan-tour DESTINATION /usr/local/bin)
