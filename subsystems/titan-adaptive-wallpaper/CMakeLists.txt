cmake_minimum_required(VERSION 3.20)
project(titan-adaptive-wallpaper VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml)
find_package(OpenMP)

add_library(titan_adaptive_wallpaper_core STATIC
    include/color_space.hpp
    include/theme_palette.hpp
    include/color_transformer.hpp
    include/cache_manager.hpp
    include/wallpaper_loader.hpp
    include/taw_engine.hpp
    include/taw_controller.hpp
    include/sync_lock.hpp
    src/color_space.cpp
    src/theme_palette.cpp
    src/color_transformer.cpp
    src/cache_manager.cpp
    src/wallpaper_loader.cpp
    src/taw_engine.cpp
    src/taw_controller.cpp
)

target_include_directories(titan_adaptive_wallpaper_core PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)

target_link_libraries(titan_adaptive_wallpaper_core PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
)

if(OpenMP_CXX_FOUND)
    target_link_libraries(titan_adaptive_wallpaper_core PUBLIC OpenMP::OpenMP_CXX)
endif()

# CLI Executable
add_executable(titan-adaptive-wallpaper
    src/main_cli.cpp
)

target_link_libraries(titan-adaptive-wallpaper PRIVATE
    titan_adaptive_wallpaper_core
)

# Test executable
add_executable(test_taw
    tests/test_taw.cpp
)

target_link_libraries(test_taw PRIVATE
    titan_adaptive_wallpaper_core
)

install(TARGETS titan-adaptive-wallpaper DESTINATION /usr/local/bin)

