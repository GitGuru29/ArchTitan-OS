cmake_minimum_required(VERSION 3.16)
project(titan-hotzones VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
# Emit build/compile_commands.json so clangd/IDE can resolve Qt include paths
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Network Gui Quick Qml)
find_package(LayerShellQt REQUIRED)

# ── titan-hotzones (daemon) ──────────────────────────────────────────────────
add_executable(titan-hotzones
    src/main.cpp
    src/config.cpp
    src/config.hpp
    src/zones.cpp
    src/zones.hpp
    src/hyprland.cpp
    src/hyprland.hpp
    src/osdserver.cpp
    src/osdserver.hpp
    src/events.cpp
    src/events.hpp
)

target_link_libraries(titan-hotzones PRIVATE Qt6::Core Qt6::Network)

# ── titan-zone-osd (on-screen display) ───────────────────────────────────────
add_executable(titan-zone-osd
    src/osd_main.cpp
    src/osdcontroller.cpp
    src/osdcontroller.hpp
    resources.qrc
)

target_link_libraries(titan-zone-osd PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Network
    LayerShellQt::Interface
)

install(TARGETS titan-hotzones titan-zone-osd DESTINATION /usr/local/bin)
