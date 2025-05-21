cmake_minimum_required(VERSION 3.21)
project(Canistral LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(MSVC)
    add_compile_options(/Zc:__cplusplus /permissive- /W3)
else()
    add_compile_options(-Wall -Wextra -fPIC)
endif()

enable_language(C)

#-----------------------------------------------------------------------------
# Qt6 Installation and Configuration
#-----------------------------------------------------------------------------

if(NOT DEFINED QT_FORCE_INSTALL)
    set(QT_FORCE_INSTALL OFF CACHE BOOL "Force Qt6 installation even if found")
endif()

find_package(Qt6 QUIET COMPONENTS Core Gui Widgets)

if(NOT Qt6_FOUND OR QT_FORCE_INSTALL)
    message(STATUS "Qt6 not found - installing...")
    if(WIN32)
        # Windows - chocolatey
        find_program(CHOCO choco.exe)
        if(NOT CHOCO)
            message(STATUS "Installing Chocolatey...")
            file(DOWNLOAD https://chocolatey.org/install.ps1 "${CMAKE_BINARY_DIR}/install-choco.ps1" STATUS download_status)
            list(GET download_status 0 error_code)
            execute_process(
                COMMAND powershell -ExecutionPolicy Bypass -Command 
                    "[System.Environment]::SetEnvironmentVariable('Path', [System.Environment]::GetEnvironmentVariable('Path', 'Machine') + ';' + [System.Environment]::GetEnvironmentVariable('Path', 'User'), 'Process'); & '${CMAKE_BINARY_DIR}/install-choco.ps1'"
            )
            set(ENV{PATH} "$ENV{ALLUSERSPROFILE}\\chocolatey\\bin;$ENV{PATH}")
            unset(CHOCO CACHE)
            find_program(CHOCO choco REQUIRED)
        endif()
        find_program(CHOCO choco)
        if(NOT CHOCO)
            message(FATAL_ERROR "Chocolatey not found - required for Qt6 installation")
        endif()
        execute_process(COMMAND choco install qt6-base-dev -y --version 6.4.2 --no-progress --params="/InstallationPath C:/Qt")
        set(QT_PATHS 
            "C:/Qt/6.4.2/msvc2019_64/lib/cmake/Qt6"
            "C:/Qt/6.4.2/msvc2019_64"
            "C:/Qt/6.4.2/mingw_64/lib/cmake/Qt6"
            "C:/Qt/6.4.2/mingw_64"
            "$ENV{QT_DIR}"
            "$ENV{QTDIR}"
        )
        
        find_path(QT_DIR 
            NAMES Qt6Config.cmake
            PATHS ${QT_PATHS}
            REQUIRED
            DOC "Path to Qt6 cmake configuration"
        )
    elseif(APPLE)
        # macOS - brew
        find_program(BREW brew)
        if(NOT BREW)
            message(FATAL_ERROR "brew is required for dependency installation")
        endif()
        execute_process(COMMAND ${BREW} install qt@6 RESULT_VARIABLE QT_INSTALL_RESULT)
        execute_process(
            COMMAND ${BREW} --prefix qt@6
            OUTPUT_VARIABLE QT_PREFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(QT_DIR "${QT_PREFIX}/lib/cmake/Qt6")
    else()
        # Linux - apt-get
        find_program(APT_GET apt-get)
        if(NOT APT_GET)
            message(FATAL_ERROR "apt-get is required for dependency installation")
        endif()

        execute_process(COMMAND sudo ${APT_GET} update)
        execute_process(COMMAND sudo ${APT_GET} install -y libgl1-mesa-dev qt6-base-dev qt6-tools-dev-tools)
        set(QT_DIR "/usr/lib/x86_64-linux-gnu/cmake/Qt6")
    endif()
    list(APPEND CMAKE_PREFIX_PATH ${QT_DIR})
    find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
endif()

#-----------------------------------------------------------------------------
# SQLite3 Build
#-----------------------------------------------------------------------------

set(SQLite3_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rd/sqlite3")
set(SQLite3_INCLUDE_DIR ${SQLite3_DIR})
set(SQLite3_LIBRARY sqlite3)
add_library(${SQLite3_LIBRARY} STATIC ${SQLite3_DIR}/sqlite3.c ${SQLite3_INCLUDE_DIR}/sqlite3.h)
set_target_properties(${SQLite3_LIBRARY} PROPERTIES LINKER_LANGUAGE C)
target_include_directories(${SQLite3_LIBRARY} PUBLIC ${SQLite3_INCLUDE_DIR})

#-----------------------------------------------------------------------------
# Application Setup
#-----------------------------------------------------------------------------

file(GLOB_RECURSE SOURCES "src/*.cpp")
file(GLOB_RECURSE HEADERS "include/*.h")

add_executable(${PROJECT_NAME}
    main.cpp
    ${SOURCES}
    ${HEADERS}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    ${SQLite3_LIBRARY}
)

if(WIN32)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:Qt6::Core>"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:Qt6::Gui>"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:Qt6::Widgets>"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMENT "Copying Qt6 DLLs to output directory"
    )
endif()