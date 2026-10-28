cmake_minimum_required(VERSION 3.16)
project(titan-powermenu VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Network)
find_package(LayerShellQt REQUIRED)

add_executable(titan-powermenu
    src/main.cpp
    src/ipcserver.h
    src/ipcserver.cpp
    src/powermenucontroller.h
    src/powermenucontroller.cpp
    resources.qrc
)

target_include_directories(titan-powermenu PRIVATE src)

target_link_libraries(titan-powermenu PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Network
    LayerShellQt::Interface
)

install(TARGETS titan-powermenu DESTINATION /usr/local/bin)
