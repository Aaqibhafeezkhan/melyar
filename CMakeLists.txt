cmake_minimum_required(VERSION 3.25)
project(melyar LANGUAGES CXX C)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# -----------------------------------------------------------------------------
# Corrosion (Rust integration for CMake)
# -----------------------------------------------------------------------------
find_package(Corrosion QUIET)
if(NOT Corrosion_FOUND)
    include(FetchContent)
    FetchContent_Declare(
        Corrosion
        GIT_REPOSITORY https://github.com/corrosion-rs/corrosion.git
        GIT_TAG v0.5.2
    )
    FetchContent_MakeAvailable(Corrosion)
endif()

# Import Rust Core Static Library
corrosion_import_crate(
    MANIFEST_PATH ${CMAKE_CURRENT_SOURCE_DIR}/core_rs/Cargo.toml
    CRATES melyar_core
)

# -----------------------------------------------------------------------------
# Qt6 Modules
# -----------------------------------------------------------------------------
find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml WebEngineQuick WebChannel)

# -----------------------------------------------------------------------------
# Libmpv
# -----------------------------------------------------------------------------
find_package(PkgConfig REQUIRED)
pkg_check_modules(MPV REQUIRED mpv)

# -----------------------------------------------------------------------------
# Melyar Executable Target
# -----------------------------------------------------------------------------
qt_add_executable(melyar
    ui_cpp/main.cpp
    ui_cpp/bridge/bridge.cpp
    ui_cpp/bridge/bridge.hpp
)

file(GLOB_RECURSE MELYAR_QML_FILES CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "ui_cpp/qml/*.qml"
    "ui_cpp/qml/**/*.qml"
    "ui_cpp/qml/**/qmldir"
)

# Application resources (icons) embedded into the binary
file(GLOB MELYAR_RESOURCE_FILES CONFIGURE_DEPENDS
    RELATIVE "${CMAKE_CURRENT_SOURCE_DIR}"
    "resources/*.svg"
    "resources/*.png"
)

qt6_add_resources(melyar "melyar_qml"
    PREFIX "/melyar"
    FILES ${MELYAR_QML_FILES} ${MELYAR_RESOURCE_FILES}
)

target_include_directories(melyar PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/core_rs/include
    ${CMAKE_CURRENT_SOURCE_DIR}/ui_cpp/bridge
    ${MPV_INCLUDE_DIRS}
)

target_link_libraries(melyar PRIVATE
    melyar_core
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
    Qt6::Qml
    Qt6::WebEngineQuick
    Qt6::WebChannel
    ${MPV_LIBRARIES}
)

set_target_properties(melyar PROPERTIES
    CXX_STANDARD 20
    CMAKE_CXX_STANDARD_REQUIRED ON
    AUTOMOC ON
    AUTORCC ON
    AUTOUIC ON
)

install(TARGETS melyar DESTINATION bin)
install(FILES resources/melyar.desktop DESTINATION share/applications)
install(FILES resources/melyar.svg DESTINATION share/icons/hicolor/scalable/apps)

# -----------------------------------------------------------------------------
# Web UI bundle (ui_web/dist) - built separately with `pnpm build`
# -----------------------------------------------------------------------------
if(EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/ui_web/dist/index.html")
    install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/ui_web/dist/"
            DESTINATION share/melyar/web
            FILES_MATCHING
            PATTERN "*.html"
            PATTERN "*.js"
            PATTERN "*.css"
            PATTERN "*.svg"
            PATTERN "*.woff"
            PATTERN "*.woff2")
endif()
