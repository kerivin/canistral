cmake_minimum_required(VERSION 3.21)
project(tr-nist LANGUAGES CXX)

set(CMAKE_INSTALL_PREFIX "${CMAKE_BINARY_DIR}/bin" CACHE PATH "Installation directory")
message(STATUS "Installation folder: ${CMAKE_INSTALL_PREFIX}")

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

enable_language(C)

#-----------------------------------------------------------------------------
# Package managers
#-----------------------------------------------------------------------------

set(MISSING_MESSAGE "is required for dependency installation")

if(WIN32)
    # Windows - choco
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
        find_program(CHOCO choco.exe REQUIRED)
    endif()
elseif(APPLE)
    # macOS - brew
    find_program(BREW brew)
    if(NOT BREW)
        message(FATAL_ERROR "brew ${MISSING_MESSAGE}")
    endif()
else()
    # Linux - apt-get
    find_program(APT_GET apt-get)
    if(NOT APT_GET)
        message(FATAL_ERROR "apt-get ${MISSING_MESSAGE}")
    endif()
    execute_process(COMMAND sudo ${APT_GET} update)
endif()

#-----------------------------------------------------------------------------
# Python
#-----------------------------------------------------------------------------

if(WIN32)
    execute_process(COMMAND ${CHOCO} install python -y --no-progress)
elseif(APPLE)
    execute_process(COMMAND ${BREW} install python)
else()
    execute_process(COMMAND sudo ${APT_GET} install -y python3-dev python3-venv)
endif()

find_package(Python3 3.11 REQUIRED COMPONENTS Interpreter Development)

set(PYTHON_VENV_NAME python_venv)
set(PYTHON_VENV_DIR "${CMAKE_BINARY_DIR}/${PYTHON_VENV_NAME}")
file(MAKE_DIRECTORY ${PYTHON_VENV_DIR})

message(STATUS "Original Python: ${Python3_EXECUTABLE}")

# Create virtual environment
execute_process(COMMAND ${Python3_EXECUTABLE} -m venv "${PYTHON_VENV_DIR}")

if(WIN32)
    set(VENV_PYTHON_EXECUTABLE "${PYTHON_VENV_DIR}/Scripts/python.exe")
    set(VENV_PIP_EXECUTABLE "${PYTHON_VENV_DIR}/Scripts/pip.exe")
else()
    set(VENV_PYTHON_EXECUTABLE "${PYTHON_VENV_DIR}/bin/python")
    set(VENV_PIP_EXECUTABLE "${PYTHON_VENV_DIR}/bin/pip")
endif()

unset(Python3_EXECUTABLE CACHE)
unset(Python3_INCLUDE_DIRS CACHE)
unset(Python3_LIBRARIES CACHE)
unset(Python3_FOUND CACHE)

execute_process(
  COMMAND ${Python3_EXECUTABLE} -c 
    "import os, sys; print(os.path.realpath(os.path.dirname(os.__file__)))"
  OUTPUT_VARIABLE SYSTEM_STDLIB_PATH
  OUTPUT_STRIP_TRAILING_WHITESPACE
)

set(Python3_EXECUTABLE ${VENV_PYTHON_EXECUTABLE} CACHE STRING "" FORCE)
find_package(Python3 3.11 REQUIRED COMPONENTS Interpreter Development)

execute_process(
    COMMAND ${Python3_EXECUTABLE} -c "import sys; print(sys.prefix)"
    OUTPUT_VARIABLE PYTHON_PREFIX
    OUTPUT_STRIP_TRAILING_WHITESPACE
)
message(STATUS "Using Python from: ${PYTHON_PREFIX}")

#-----------------------------------------------------------------------------
# Python Packages
#-----------------------------------------------------------------------------

execute_process(COMMAND ${VENV_PIP_EXECUTABLE} --version)
set(PYTHON_PACKAGES
    translators
    python-iso639
)

foreach(pkg IN LISTS PYTHON_PACKAGES)
    execute_process(
        COMMAND ${VENV_PIP_EXECUTABLE} install ${pkg}
        RESULT_VARIABLE pkg_result
        ERROR_VARIABLE pkg_error
    )
    if(NOT pkg_result EQUAL 0)
        message(WARNING "Failed to install ${pkg}:\n${pkg_error}")
    endif()
endforeach()

#-----------------------------------------------------------------------------
# PyBind11
#-----------------------------------------------------------------------------

set(PYBIND11_PYTHON_VERSION "${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}")
set(PYBIND11_FINDPYTHON ON)
set(PYBIND11_NOPYTHON OFF)

include(FetchContent)
FetchContent_Declare(
  pybind11
  GIT_REPOSITORY https://github.com/pybind/pybind11.git
  GIT_TAG v2.13.6
)
FetchContent_MakeAvailable(pybind11)

if(NOT pybind11_PYTHON_INTERPRETER)
    set(pybind11_PYTHON_INTERPRETER ${Python3_EXECUTABLE} CACHE STRING "" FORCE)
endif()
message(STATUS "pybind11 using Python: ${pybind11_PYTHON_INTERPRETER}")

#-----------------------------------------------------------------------------
# Pandoc
#-----------------------------------------------------------------------------

if(WIN32)
    # execute_process(COMMAND ${CHOCO} install pandoc -y --no-progress)
elseif(APPLE)
    # execute_process(COMMAND ${BREW} install pandoc)
else()
    # execute_process(COMMAND sudo ${APT_GET} install -y pandoc)
endif()

#-----------------------------------------------------------------------------
# Qt6
#-----------------------------------------------------------------------------

if(NOT DEFINED QT_FORCE_INSTALL)
    set(QT_FORCE_INSTALL OFF CACHE BOOL "Force Qt6 installation even if found")
endif()

set(QT_COMPONENTS Core Gui Widgets)

find_package(Qt6 QUIET COMPONENTS ${QT_COMPONENTS})

if(NOT Qt6_FOUND OR QT_FORCE_INSTALL)
    message(STATUS "Installing Qt6...")
    if(WIN32)
        execute_process(COMMAND ${CHOCO} install qt6-base-dev -y --version 6.4.2 --no-progress --params="/InstallationPath C:/Qt")
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
        )
    elseif(APPLE)
        execute_process(COMMAND ${BREW} install qt@6)
        execute_process(
            COMMAND ${BREW} --prefix qt@6
            OUTPUT_VARIABLE QT_PREFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        set(QT_DIR "${QT_PREFIX}/lib/cmake/Qt6")
    else()
        execute_process(COMMAND sudo ${APT_GET} install -y libgl1-mesa-dev qt6-base-dev qt6-tools-dev-tools)
        set(QT_DIR "/usr/lib/x86_64-linux-gnu/cmake/Qt6")
    endif()
    list(APPEND CMAKE_PREFIX_PATH ${QT_DIR})
    find_package(Qt6 REQUIRED COMPONENTS ${QT_COMPONENTS})
endif()

#-----------------------------------------------------------------------------
# SQLite3
#-----------------------------------------------------------------------------

set(SQLite3_DIR "${CMAKE_CURRENT_SOURCE_DIR}/3rd/sqlite3")
set(SQLite3_INCLUDE_DIR ${SQLite3_DIR})
set(SQLite3_LIBRARY sqlite3)
add_library(${SQLite3_LIBRARY} STATIC ${SQLite3_DIR}/sqlite3.c ${SQLite3_INCLUDE_DIR}/sqlite3.h)
set_target_properties(${SQLite3_LIBRARY} PROPERTIES LINKER_LANGUAGE C)
target_include_directories(${SQLite3_LIBRARY} PUBLIC ${SQLite3_INCLUDE_DIR})

#-----------------------------------------------------------------------------
# PRE-BUILD GENERATE FILES
#-----------------------------------------------------------------------------

set(PYTHON_RUNTIME_HOME ${PYTHONHOME})
set(PYTHON_RUNTIME ${})

configure_file(
    ${CMAKE_SOURCE_DIR}/src/python_init.cpp.in
    ${CMAKE_BINARY_DIR}/generated/python_init.cpp
    @ONLY
)

#-----------------------------------------------------------------------------
# EXECUTABLE SETUP
#-----------------------------------------------------------------------------

file(GLOB_RECURSE SOURCES "src/*.cpp")
file(GLOB_RECURSE HEADERS "include/*.h")

qt_add_executable(${PROJECT_NAME} WIN32
    main.cpp
    ${SOURCES}
)

target_include_directories(${PROJECT_NAME}
    PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${Python3_INCLUDE_DIRS}
        ${pybind11_INCLUDE_DIRS}
)

target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_BINARY_DIR}/generated/python_init.cpp)

target_link_libraries(${PROJECT_NAME} PRIVATE
    ${SQLite3_LIBRARY}
    ${Python3_LIBRARIES}
    pybind11::embed
)

foreach(component IN LISTS QT_COMPONENTS)
    target_link_libraries(${PROJECT_NAME} PRIVATE "Qt6::${component}")
endforeach()

if(MSVC)
    target_compile_options(${PROJECT_NAME} PRIVATE /Zc:__cplusplus /W4 /WX)
else()
    target_compile_options(${PROJECT_NAME} PRIVATE -Wall -Wextra -Wpedantic -Werror -fPIC)
endif()

target_compile_options(${PROJECT_NAME} PRIVATE -fvisibility=hidden)

target_compile_definitions(${PROJECT_NAME} PRIVATE
    QT_NO_KEYWORDS
    PYTHON_EXECUTABLE=${Python3_EXECUTABLE}
    PYTHONHOME="${PYTHON_VENV_DIR}"
)

if(UNIX AND NOT APPLE)
    target_compile_definitions(${PROJECT_NAME} PRIVATE QT_QPA_PLATFORM=xcb)
endif()

add_custom_command(
    TARGET ${PROJECT_NAME} PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        "${SYSTEM_STDLIB_PATH}/encodings"
        "${PYTHON_VENV_DIR}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/encodings"
    COMMENT "Copying encodings directory"
)

if(WIN32 AND Python3_VERSION VERSION_LESS "3.13")
    file(COPY
        "${SYSTEM_STDLIB_PATH}/../python${Python3_VERSION_MAJOR}${Python3_VERSION_MINOR}.zip"
        DESTINATION "${PYTHON_VENV_DIR}/lib"
    )
endif()

#-----------------------------------------------------------------------------
# INSTALL
#-----------------------------------------------------------------------------

get_target_property(Qt6_core_location Qt6::Core IMPORTED_LOCATION)
if(Qt6_core_location)
    get_filename_component(QT_BIN_DIR "${Qt6_core_location}" DIRECTORY)
    
    if(WIN32)
        set(PLATFORM_LIB qwindows.dll)
    elseif(APPLE)
        set(PLATFORM_LIB libqcocoa.dylib)
    else()
        set(PLATFORM_LIB libqxcb.so)
    endif()

    find_path(QT_PLATFORMS_DIR
        NAMES ${PLATFORM_LIB}
        PATHS "${QT_BIN_DIR}/../plugins/platforms" "/usr/lib/qt6/plugins/platforms" "/usr/lib/x86_64-linux-gnu/qt6/plugins/platforms"
    )
endif()

install(TARGETS ${PROJECT_NAME}
        RUNTIME DESTINATION .
        BUNDLE DESTINATION .
        LIBRARY DESTINATION .
        ARCHIVE DESTINATION .)

install(DIRECTORY ${PYTHON_VENV_DIR}
        DESTINATION .
        PATTERN "__pycache__" EXCLUDE
        PATTERN "*.pyc" EXCLUDE
        PATTERN "*.dist-info" EXCLUDE
        PATTERN "*.egg-info" EXCLUDE)

if(WIN32)
    if(QT_PLATFORMS_DIR)
        install(DIRECTORY ${QT_PLATFORMS_DIR}/
                DESTINATION platforms
                FILES_MATCHING PATTERN "*.dll")
    endif()
    if(Qt6_core_location)
        foreach(component IN LISTS QT_COMPONENTS)
            if(TARGET Qt6::${component})
                install(FILES "${QT_BIN_DIR}/Qt6${component}.dll"
                        DESTINATION .)
                if(CMAKE_BUILD_TYPE STREQUAL "Debug")
                    install(FILES "${QT_BIN_DIR}/Qt6${component}d.dll"
                            DESTINATION .)
                endif()
            endif()
        endforeach()
    endif()
endif()

if(UNIX AND QT_PLATFORMS_DIR)
    install(DIRECTORY ${QT_PLATFORMS_DIR}/
            DESTINATION platforms
            FILES_MATCHING PATTERN "*${PLATFORM_LIB}")
endif()

include(InstallRequiredSystemLibraries)

set(CPACK_PACKAGE_NAME "${PROJECT_NAME}")
set(CPACK_PACKAGE_INSTALL_DIRECTORY "${PROJECT_NAME}")

if(WIN32)
    set(CPACK_GENERATOR "NSIS;ZIP")
    set(CPACK_NSIS_MODIFY_PATH ON)
elseif(APPLE)
    set(CPACK_GENERATOR "DragNDrop;TGZ")
else()
    set(CPACK_GENERATOR "DEB;TGZ")
endif()

include(CPack)