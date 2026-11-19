cmake_minimum_required(VERSION 3.16)
project(titan-shell VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml DBus Network Widgets)
find_package(LayerShellQt REQUIRED)

set(SHELL_SOURCES
    src/main.cpp
    src/shellipc.cpp
    src/shellcontroller.cpp

    # Sysmon
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src/sysmoncontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src/gpumodel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src/thmstate.cpp

    # Spotlight
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/spotlightcontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/appindexer.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/calculator.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/clipboard.cpp

    # QuickSettings
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/systemcontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/networkcontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/bluetoothcontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/audiocontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/nightlightcontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/notificationmodel.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/notificationserver.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/mpriscontroller.cpp

    # Menu
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src/menucontroller.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src/menutree.cpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src/fuzzy.cpp

    # Workspace HUD
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-workspace-hud/src/hyprlandcontroller.cpp
)

set(SHELL_HEADERS
    src/shellipc.h
    src/shellcontroller.h
    src/appiconprovider.h

    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src/sysmoncontroller.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src/gpumodel.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src/thmstate.hpp

    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/spotlightcontroller.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/appindexer.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/calculator.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src/clipboard.h

    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/systemcontroller.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/networkcontroller.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/bluetoothcontroller.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/audiocontroller.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/nightlightcontroller.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/notificationmodel.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/notificationserver.h
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src/mpriscontroller.h

    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src/menucontroller.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src/menutree.hpp
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src/fuzzy.hpp

    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-workspace-hud/src/hyprlandcontroller.h
)

add_executable(titan-shell
    ${SHELL_SOURCES}
    ${SHELL_HEADERS}
    resources.qrc
)

target_include_directories(titan-shell PRIVATE
    src
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-sysmon/src
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-spotlight/src
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-quicksettings/src
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-menu/src
    ${CMAKE_CURRENT_SOURCE_DIR}/../titan-workspace-hud/src
)

target_link_libraries(titan-shell PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::DBus
    Qt6::Network
    Qt6::Widgets
    LayerShellQt::Interface
)

install(TARGETS titan-shell DESTINATION /usr/local/bin)
