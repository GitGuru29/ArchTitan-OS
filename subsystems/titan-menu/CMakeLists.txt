cmake_minimum_required(VERSION 3.16)
project(titan-menu VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Network)
find_package(Qt6 QUIET COMPONENTS Test)
find_package(LayerShellQt REQUIRED)

# ── Core logic (no UI): fuzzy search, menu tree, controller ─────────────────
add_library(titanmenu_core STATIC
    src/fuzzy.cpp
    src/menutree.cpp
    src/menucontroller.cpp
)
target_include_directories(titanmenu_core PUBLIC src)
target_link_libraries(titanmenu_core PUBLIC Qt6::Core)

# ── The overlay ─────────────────────────────────────────────────────────────
add_executable(titan-menu
    src/main.cpp
    src/ipcserver.cpp
    src/ipcserver.h
    resources.qrc
)
target_link_libraries(titan-menu PRIVATE
    titanmenu_core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::Network
    LayerShellQt::Interface
)
install(TARGETS titan-menu DESTINATION /usr/local/bin)

# ── Tests (only when QtTest is installed) ───────────────────────────────────
if(Qt6Test_FOUND)
    enable_testing()
    add_executable(titan-menu-tests tests/test_menu.cpp resources.qrc)
    target_link_libraries(titan-menu-tests PRIVATE titanmenu_core Qt6::Test)
    add_test(NAME titan-menu-tests COMMAND titan-menu-tests)
endif()
