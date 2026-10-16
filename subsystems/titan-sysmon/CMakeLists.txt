cmake_minimum_required(VERSION 3.16)
project(titan-sysmon VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml)
find_package(LayerShellQt REQUIRED)

set(SOURCES
    src/main.cpp
    src/ipcserver.cpp
    src/thmstate.cpp
    src/gpumodel.cpp
    src/sysmoncontroller.cpp
)

set(HEADERS
    src/ipcserver.h
    src/thmstate.hpp
    src/gpumodel.hpp
    src/sysmoncontroller.hpp
)

set(RESOURCES
    resources.qrc
)

add_executable(titan-sysmon
    ${SOURCES}
    ${HEADERS}
    ${RESOURCES}
)

target_link_libraries(titan-sysmon PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    LayerShellQt::Interface
)

install(TARGETS titan-sysmon DESTINATION /usr/local/bin)
