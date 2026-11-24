cmake_minimum_required(VERSION 3.22)
project(titan-focus VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml DBus Network)
find_package(LayerShellQt REQUIRED)

# ── Headless Core Library (Layers 1-3, no display required) ──────────────────
add_library(titan_focus_core STATIC
    src/configloader.cpp
    src/configloader.h
    src/nudgestate.cpp
    src/nudgestate.h
    src/ruleengine.cpp
    src/ruleengine.h
    src/notifier.cpp
    src/notifier.h
    src/procsampler.cpp
    src/procsampler.h
    src/pressuresampler.cpp
    src/pressuresampler.h
    src/sessionmonitor.cpp
    src/sessionmonitor.h
    src/focusmonitor.cpp
    src/focusmonitor.h
    src/ipcserver.cpp
    src/ipcserver.h
)

target_include_directories(titan_focus_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/src
)

target_link_libraries(titan_focus_core PUBLIC
    Qt6::Core
    Qt6::Network
)

# ── Main Daemon + Lazy LayerShell Overlay Executable ─────────────────────────
add_executable(titan-focus
    src/main.cpp
    src/focuscontroller.cpp
    src/focuscontroller.h
    resources.qrc
)

target_link_libraries(titan-focus PRIVATE
    titan_focus_core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::DBus
    LayerShellQt::Interface
)

install(TARGETS titan-focus DESTINATION /usr/local/bin)

# ── Headless Unit Test Suite ─────────────────────────────────────────────────
enable_testing()

add_executable(test-ruleengine
    tests/test-ruleengine.cpp
)

target_link_libraries(test-ruleengine PRIVATE
    titan_focus_core
)

add_test(NAME ruleengine_unit_tests COMMAND test-ruleengine)
