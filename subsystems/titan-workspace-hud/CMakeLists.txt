cmake_minimum_required(VERSION 3.16)
project(titan-workspace-hud VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml DBus Network Widgets)
find_package(LayerShellQt REQUIRED)

set(SOURCES
    src/main.cpp
    src/ipcserver.cpp
    src/hyprlandcontroller.cpp
)

set(HEADERS
    src/ipcserver.h
    src/hyprlandcontroller.h
)

set(RESOURCES
    resources.qrc
)

add_executable(titan-workspace-hud
    ${SOURCES}
    ${HEADERS}
    ${RESOURCES}
)

target_link_libraries(titan-workspace-hud PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::DBus
    Qt6::Network
    Qt6::Widgets
    LayerShellQt::Interface
)

install(TARGETS titan-workspace-hud DESTINATION /usr/local/bin)
