cmake_minimum_required(VERSION 3.16)
project(titan-spotlight VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Network)
find_package(LayerShellQt REQUIRED)

add_executable(titan-spotlight
    src/main.cpp
    src/ipcserver.h
    src/ipcserver.cpp
    src/appindexer.h
    src/appindexer.cpp
    src/calculator.h
    src/calculator.cpp
    src/clipboard.h
    src/clipboard.cpp
    src/spotlightcontroller.h
    src/spotlightcontroller.cpp
    resources.qrc
)

target_include_directories(titan-spotlight PRIVATE src)

target_link_libraries(titan-spotlight PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Network
    LayerShellQt::Interface
)

install(TARGETS titan-spotlight DESTINATION /usr/local/bin)
