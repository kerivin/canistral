cmake_minimum_required(VERSION 3.21)
project(Canistral LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/Zc:__cplusplus)
else()
    add_compile_options(-Wall -Wextra)
endif()

enable_language(C)

# Dependency handling
if(NOT EXISTS "${CMAKE_BINARY_DIR}/dep-build")
    message(STATUS "Building dependencies...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_SOURCE_DIR}/build-deps.cmake
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endif()

set(DEPS_DIR "${CMAKE_BINARY_DIR}/dep-build")

# Cross-platform Qt6 detection
if(DEFINED ENV{QT_DIR})
    # Allow manual override via environment variable
    set(QT_DIR $ENV{QT_DIR})
elseif(WIN32)
    # Windows: Try multiple possible locations
    find_path(QT_DIR NAMES Qt6Config.cmake
        PATHS
        "${DEPS_DIR}/Qt/6.6.0/msvc2019_64"
        "C:/Qt/6.6.0/msvc2019_64"
        "C:/Qt/6.6.0/mingw_64"
        DOC "Path to Qt6 installation"
    )
elseif(APPLE)
    # macOS: Use homebrew path
    execute_process(COMMAND brew --prefix qt@6
        OUTPUT_VARIABLE QT_PREFIX
        OUTPUT_STRIP_TRAILING_WHITESPACE
        ERROR_QUIET
    )
    if(QT_PREFIX)
        set(QT_DIR "${QT_PREFIX}")
    else()
        # Fallback to standard locations
        set(QT_DIR "/usr/local/opt/qt@6")
    endif()
else()
    # Linux: Standard system paths
    find_path(QT_DIR NAMES Qt6Config.cmake
        PATHS
        "/usr/lib/x86_64-linux-gnu/cmake/Qt6"
        "/usr/local/lib/cmake/Qt6"
        DOC "Path to Qt6 installation"
    )
endif()

# LibreOffice SDK detection
if(WIN32)
    set(LO_SDK_PATHS
        "${DEPS_DIR}/LibreOffice/sdk/include"
        "C:/LibreOffice/sdk/include"
    )
elseif(APPLE)
    set(LO_SDK_PATHS
        "${DEPS_DIR}/LibreOffice/sdk/include"
        "/Applications/LibreOffice.app/Contents/sdk/include"
        "/opt/libreoffice/sdk/include"
    )
else()
    set(LO_SDK_PATHS
        "${DEPS_DIR}/LibreOffice/sdk/include"
        "/usr/include/libreoffice/sdk"
        "/usr/lib/libreoffice/sdk/include"
    )
endif()

find_path(LIBREOFFICE_INCLUDE_DIR uno/environment.h
    PATHS ${LO_SDK_PATHS}
    DOC "Path to LibreOffice SDK includes"
)

# Qt6 Setup
list(APPEND CMAKE_PREFIX_PATH ${QT_DIR})
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)

# SQLite3 Setup
set(SQLite3_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rd/sqlite3")
set(SQLite3_INCLUDE_DIR ${SQLite3_DIR})
set(SQLite3_LIBRARY sqlite3)
add_library(${SQLite3_LIBRARY} STATIC ${SQLite3_DIR}/sqlite3.c ${SQLite3_INCLUDE_DIR}/sqlite3.h)
set_target_properties(${SQLite3_LIBRARY} PROPERTIES LINKER_LANGUAGE C)
target_include_directories(${SQLite3_LIBRARY} PUBLIC ${SQLite3_INCLUDE_DIR})

# LibreOffice SDK Setup
if(LIBREOFFICE_INCLUDE_DIR)
    add_library(LibreOffice::SDK INTERFACE IMPORTED)
    set_target_properties(LibreOffice::SDK PROPERTIES
        INTERFACE_INCLUDE_DIRECTORIES "${LIBREOFFICE_INCLUDE_DIR}"
    )
endif()

# Main executable
file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
add_executable(${PROJECT_NAME} main.cpp ${SOURCES})
target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    ${SQLite3_LIBRARY}
    $<$<BOOL:${LIBREOFFICE_INCLUDE_DIR}>:LibreOffice::SDK>
)

# Windows-specific setup
if(WIN32)
    # Get the directory containing Qt DLLs
    get_target_property(Qt6Core_location Qt6::Core IMPORTED_LOCATION_RELEASE)
    get_filename_component(QT_DLL_DIR ${Qt6Core_location} DIRECTORY)

    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "${QT_DLL_DIR}/Qt6Core.dll"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        COMMAND ${CMAKE_COMMAND} -E copy
            "${QT_DLL_DIR}/Qt6Gui.dll"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        COMMAND ${CMAKE_COMMAND} -E copy
            "${QT_DLL_DIR}/Qt6Widgets.dll"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        COMMENT "Copying Qt6 DLLs to output directory"
    )
endif()