cmake_minimum_required(VERSION 3.21)
project(Canistral LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/Zc:__cplusplus)
    # target_compile_options(${PROJECT_NAME} PRIVATE /Zc:__cplusplus)
else()
    add_compile_options(-Wall -Wextra)
endif()

# Trigger dependency build before configuration
if(NOT EXISTS "${CMAKE_BINARY_DIR}/dep-build")
    message(STATUS "Building dependencies...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_SOURCE_DIR}/build-deps.cmake
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endif()

set(DEPS_DIR "${CMAKE_BINARY_DIR}/dep-build")

if(WIN32)
    set(SQLite3_INCLUDE_DIR "${DEPS_DIR}/SQLite/include")
    set(SQLite3_LIBRARY "${DEPS_DIR}/SQLite/lib/sqlite3.lib")
else()
    find_path(SQLite3_INCLUDE_DIR sqlite3.h
        PATHS "${DEPS_DIR}/SQLite/include"
            "${DEPS_DIR}/sqlite-amalgamation-3420000"
    )
    find_path(LIBREOFFICE_INCLUDE_DIR uno/environment.h
        PATHS "${DEPS_DIR}/LibreOffice/sdk/include"
    )
endif()

# Qt6 Setup
list(APPEND CMAKE_PREFIX_PATH
    "${DEPS_DIR}/Qt"
    "${DEPS_DIR}/Qt/6.6.0/msvc2019_64"  # Windows
    "$ENV{HOMEBREW_PREFIX}/opt/qt@6"     # macOS
)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)

# SQLite3 Setup
find_library(SQLite3_LIBRARY sqlite3
    PATHS "${DEPS_DIR}/SQLite/lib"
)

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
target_include_directories(${PROJECT_NAME} PRIVATE
    ${SQLite3_INCLUDE_DIR}
)

# Windows-specific setup
if(WIN32)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:Qt6::Core>"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:Qt6::Gui>"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:Qt6::Widgets>"
            $<TARGET_FILE_DIR:${PROJECT_NAME}>
        COMMENT "Copying Qt6 DLLs to output directory"
    )
endif()