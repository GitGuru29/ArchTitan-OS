cmake_minimum_required(VERSION 3.16)
project(titan-ui VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)
qt_standard_project_setup()

# Allow QML files to live in subdirectories (qml/style, qml/components) under a
# single module without generating a qmldir per subdirectory.
qt_policy(SET QTP0004 OLD)

# Emit the module into a standard <build>/qml/ArchTitan/TitanUI layout so the
# gallery (and other apps) can find it with QML_IMPORT_PATH=<build>/qml during
# development, mirroring the installed tree.
set(QT_QML_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/qml")

# ── Shared design system: ArchTitan.TitanUI ────────────────────────────────
qt_add_library(TitanUI SHARED)

set_source_files_properties(qml/style/TitanTheme.qml
    PROPERTIES QT_QML_SINGLETON_TYPE TRUE)

qt_add_qml_module(TitanUI
    URI ArchTitan.TitanUI
    VERSION 1.0
    QML_FILES
        qml/TitanGallery.qml
        qml/TitanGalleryBody.qml
        qml/style/TitanTheme.qml
        qml/components/TitanIcon.qml
        qml/components/TitanButton.qml
        qml/components/TitanSwitch.qml
        qml/components/TitanSlider.qml
        qml/components/TitanCard.qml
        qml/components/TitanPill.qml
        qml/components/TitanToggleTile.qml
        qml/components/TitanBadge.qml
        qml/components/TitanDivider.qml
        qml/components/TitanSidebarItem.qml
        qml/components/TitanGlassPanel.qml
        qml/components/TitanProgress.qml
        qml/components/TitanSpinner.qml
        qml/components/TitanSkeleton.qml
        qml/components/TitanEmptyState.qml
        qml/components/TitanErrorState.qml
    SOURCES
        src/themebackend.h
        src/themebackend.cpp
)

target_link_libraries(TitanUI PRIVATE Qt6::Core Qt6::Gui Qt6::Qml Qt6::Quick)
target_include_directories(TitanUI PRIVATE src)

# ── Optional preview gallery (dev only) ────────────────────────────────────
option(TITAN_UI_BUILD_GALLERY "Build the TitanUI component gallery" ON)
if(TITAN_UI_BUILD_GALLERY)
    qt_add_executable(titan-ui-gallery src/main.cpp)
    target_link_libraries(titan-ui-gallery PRIVATE Qt6::Quick Qt6::Gui)
endif()

# ── Install so any Qt app can `import ArchTitan.TitanUI` ───────────────────
include(GNUInstallDirs)

# Directory Qt scans for QML modules. Prefer the value reported by Qt itself.
if(NOT DEFINED QT6_INSTALL_QML)
    set(QT6_INSTALL_QML "${CMAKE_INSTALL_LIBDIR}/qt6/qml")
endif()
set(TITAN_QML_DIR "${QT6_INSTALL_QML}/ArchTitan/TitanUI")
set(TITAN_QML_BUILD_DIR "${QT_QML_OUTPUT_DIRECTORY}/ArchTitan/TitanUI")

# Backing library (holds the QML file resources + C++ type registration).
install(TARGETS TitanUI
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

# QML plugin + module metadata live in the QML import tree.
install(TARGETS TitanUIplugin
    LIBRARY DESTINATION ${TITAN_QML_DIR}
    RUNTIME DESTINATION ${TITAN_QML_DIR}
)
set_target_properties(TitanUIplugin PROPERTIES
    INSTALL_RPATH "${CMAKE_INSTALL_FULL_LIBDIR}")

install(FILES
    "${TITAN_QML_BUILD_DIR}/qmldir"
    "${TITAN_QML_BUILD_DIR}/TitanUI.qmltypes"
    DESTINATION "${TITAN_QML_DIR}"
)
install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/qml/"
    DESTINATION "${TITAN_QML_DIR}/qml"
)

# ── Shared C++ palette (for Qt Widgets apps) ───────────────────────────────
add_library(TitanPalette INTERFACE)
target_include_directories(TitanPalette INTERFACE
    "$<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>"
    "$<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>"
)
target_link_libraries(TitanPalette INTERFACE Qt6::Core Qt6::Gui)

install(TARGETS TitanPalette EXPORT TitanPaletteTargets)
install(FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/TitanPalette.h"
    DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}")
