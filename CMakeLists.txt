cmake_minimum_required(VERSION 3.21)
project(Canistral VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

#-----------------------------------------------------------------------------
# Dependency Paths
#-----------------------------------------------------------------------------

set(SUBMODULES_DIR "${CMAKE_SOURCE_DIR}/third_party")
set(QT_SUBMODULE_DIR "${SUBMODULES_DIR}/qt6")
set(SQLITE3_SUBMODULE_DIR "${SUBMODULES_DIR}/sqlite3")
set(LIBREOFFICE_SDK_SUBMODULE_DIR "${SUBMODULES_DIR}/libreoffice-sdk")

#-----------------------------------------------------------------------------
# Qt6 (Submodule)
#-----------------------------------------------------------------------------

if(EXISTS "${QT_SUBMODULE_DIR}")
    set(CMAKE_PREFIX_PATH "${QT_SUBMODULE_DIR};${CMAKE_PREFIX_PATH}")
    find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
    
    # Platform-specific Qt deployment
    if(WIN32)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${QT_SUBMODULE_DIR}/bin"
                $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
    endif()
else()
    message(FATAL_ERROR "Qt6 submodule not found. Run: git submodule update --init")
endif()

#-----------------------------------------------------------------------------
# SQLite3 (Submodule)
#-----------------------------------------------------------------------------

if(EXISTS "${SQLITE3_SUBMODULE_DIR}")
    # Build SQLite3 from submodule
    add_library(sqlite3
        "${SQLITE3_SUBMODULE_DIR}/sqlite3.c"
        "${SQLITE3_SUBMODULE_DIR}/sqlite3.h"
    )
    target_include_directories(sqlite3 PUBLIC "${SQLITE3_SUBMODULE_DIR}")
else()
    message(FATAL_ERROR "SQLite3 submodule not found. Run: git submodule update --init")
endif()

#-----------------------------------------------------------------------------
# LibreOffice SDK (Submodule)
#-----------------------------------------------------------------------------

if(EXISTS "${LIBREOFFICE_SDK_SUBMODULE_DIR}")
    add_library(libreoffice-sdk INTERFACE)
    target_include_directories(libreoffice-sdk INTERFACE
        "${LIBREOFFICE_SDK_SUBMODULE_DIR}/include"
    )
    add_definitions(-DHAS_LIBREOFFICE)
else()
    message(WARNING "LibreOffice SDK submodule not found - document conversion disabled")
endif()

#-----------------------------------------------------------------------------
# Main Application
#-----------------------------------------------------------------------------

file(GLOB_RECURSE SOURCES "src/*.cpp")
file(GLOB_RECURSE HEADERS "include/*.h")
file(GLOB_RECURSE UI_FILES "ui/*.ui")
file(GLOB_RECURSE RESOURCES "resources/*.qrc")

qt_add_executable(${PROJECT_NAME}
    ${SOURCES}
    ${HEADERS}
)

qt_add_resources(${PROJECT_NAME} "RESOURCES"
    ${RESOURCES}
)

qt_wrap_ui(${PROJECT_NAME} "UI_HEADERS"
    ${UI_FILES}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    sqlite3
)

if(TARGET libreoffice-sdk)
    target_link_libraries(${PROJECT_NAME} PRIVATE libreoffice-sdk)
endif()

#-----------------------------------------------------------------------------
# Installation
#-----------------------------------------------------------------------------

install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
    LIBRARY DESTINATION lib
)