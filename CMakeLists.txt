cmake_minimum_required(VERSION 3.21)
project(Canistral LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Trigger dependency build before configuration
if(NOT EXISTS "${CMAKE_BINARY_DIR}/dep-build")
    message(STATUS "Building dependencies...")
    execute_process(
        COMMAND ${CMAKE_COMMAND} -P ${CMAKE_CURRENT_SOURCE_DIR}/build-deps.cmake
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}
    )
endif()

set(DEPS_DIR "${CMAKE_BINARY_DIR}/dep-build")

# Qt6 Setup
list(APPEND CMAKE_PREFIX_PATH
    "${DEPS_DIR}/Qt"
    "${DEPS_DIR}/Qt/6.6.0/msvc2019_64"  # Windows
    "$ENV{HOMEBREW_PREFIX}/opt/qt@6"     # macOS
)
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)

if(WIN32)
    set(QT_DIR "${DEPS_DIR}/Qt/6.6.0/msvc2019_64")
    set(SQLite3_INCLUDE_DIR "${DEPS_DIR}/SQLite/include")
    set(SQLite3_LIBRARY "${DEPS_DIR}/SQLite/lib/sqlite3.lib")
elseif(APPLE)
    execute_process(COMMAND brew --prefix qt@6 OUTPUT_VARIABLE QT_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
    set(QT_DIR "${QT_PREFIX}")
    set(SQLite3_INCLUDE_DIR "${QT_PREFIX}/include")
    set(SQLite3_LIBRARY "${QT_PREFIX}/lib/libsqlite3.dylib")
else()
    set(QT_DIR "/usr/lib/x86_64-linux-gnu/cmake/Qt6")
    set(SQLite3_INCLUDE_DIR "/usr/include")
    set(SQLite3_LIBRARY "/usr/lib/x86_64-linux-gnu/libsqlite3.so")
endif()

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