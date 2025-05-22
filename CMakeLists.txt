cmake_minimum_required(VERSION 3.21)
project(TRnist LANGUAGES CXX)

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
# Package managers
#-----------------------------------------------------------------------------

set(MISSING_MESSAGE "is required for dependency installation")

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
    find_program(CHOCO choco.exe)
    if(NOT CHOCO)
        message(FATAL_ERROR "chocolatey ${MISSING_MESSAGE}")
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

find_package(Python3 3.6 REQUIRED COMPONENTS Interpreter Development)

set(PYTHON_VENV_DIR "${CMAKE_BINARY_DIR}/python_venv")
file(MAKE_DIRECTORY ${PYTHON_VENV_DIR})

execute_process(
    COMMAND ${Python3_EXECUTABLE} -m venv "${PYTHON_VENV_DIR}"
    RESULT_VARIABLE venv_result
)
if(NOT venv_result EQUAL 0)
    message(FATAL_ERROR "Failed to create Python virtual environment")
endif()

if(WIN32)
    set(PYTHON_PIP "${PYTHON_VENV_DIR}/Scripts/pip.exe")
    execute_process(COMMAND ${PYTHON_VENV_DIR}/Scripts/Activate.ps1)
else()
    set(PYTHON_PIP "${PYTHON_VENV_DIR}/bin/pip")
    execute_process(COMMAND ${PYTHON_VENV_DIR}/bin/activate)
endif()

execute_process(COMMAND ${PYTHON_PIP} --version)
set(PYTHON_PACKAGES "pybind11 translators python-iso639")

foreach(PKG pybind11 translators python-iso639)
    execute_process(
        COMMAND ${PYTHON_PIP} install ${PKG}
        RESULT_VARIABLE PKG_RESULT
        ERROR_VARIABLE PKG_ERROR
    )
    if(NOT PKG_RESULT EQUAL 0)
        message(WARNING "Failed to install ${PKG}:\n${PKG_ERROR}")
    endif()
endforeach()

set(Python3_EXECUTABLE "${PYTHON_VENV_DIR}/bin/python" CACHE INTERNAL "")

#-----------------------------------------------------------------------------
# PyBind11 Setup
#-----------------------------------------------------------------------------

include(FetchContent)
FetchContent_Declare(
  pybind11
  GIT_REPOSITORY https://github.com/pybind/pybind11.git
  GIT_TAG v2.11.1
)
FetchContent_MakeAvailable(pybind11)

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
# Qt6 Installation and Configuration
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
            DOC "Path to Qt6 cmake configuration"
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

foreach(component IN LISTS QT_COMPONENTS)
    if(NOT TARGET Qt6::${component})
        message(FATAL_ERROR "Qt6 component ${component} not found. Check your Qt installation.")
    endif()
endforeach()

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

add_executable(${PROJECT_NAME} WIN32
    main.cpp
    ${SOURCES}
    ${HEADERS}
)

target_include_directories(${PROJECT_NAME}
    PUBLIC 
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
    PRIVATE
        ${Python3_INCLUDE_DIRS}
        ${pybind11_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    ${SQLite3_LIBRARY}
    Python3::Python
    pybind11::embed)

foreach(component IN LISTS QT_COMPONENTS)
    target_link_libraries(${PROJECT_NAME} PRIVATE "Qt6::${component}")
endforeach()

target_compile_definitions(${PROJECT_NAME} PRIVATE
    QT_NO_KEYWORDS
)

# Set Python executable path for the virtual environment
if(WIN32)
    set(PYTHON_EXECUTABLE "${PYTHON_VENV_DIR}/Scripts/python.exe")
else()
    set(PYTHON_EXECUTABLE "${PYTHON_VENV_DIR}/bin/python")
endif()

# Copy Python virtual environment to build directory
add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy_directory
        ${PYTHON_VENV_DIR}
        $<TARGET_FILE_DIR:${PROJECT_NAME}>/python_venv
    COMMENT "Copying Python virtual environment"
)

# Copy Windows DLLs
if(WIN32)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${Python3_LIBRARIES}"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMAND ${CMAKE_COMMAND} -E echo "NOTE: Ensure Python is installed on target machine"
    )
    get_target_property(Qt6_core_location Qt6::Core IMPORTED_LOCATION_RELEASE)
    if(NOT Qt6_core_location)
        get_target_property(Qt6_core_location Qt6::Core IMPORTED_LOCATION)
    endif()
    if(Qt6_core_location)
        get_filename_component(QT_BIN_DIR "${Qt6_core_location}" DIRECTORY)
        set(ENV{PATH} "${QT_BIN_DIR};$ENV{PATH}")
        foreach(component IN LISTS QT_COMPONENTS)
            if(TARGET Qt6::${component})
                # Release DLL
                add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                    COMMAND ${CMAKE_COMMAND} -E copy_if_different
                        "${QT_BIN_DIR}/Qt6${component}.dll"
                        $<TARGET_FILE_DIR:${PROJECT_NAME}>
                    COMMENT "Copying Qt6${component}.dll"
                )
                # Debug DLL
                if(CMAKE_BUILD_TYPE STREQUAL "Debug")
                    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
                        COMMAND ${CMAKE_COMMAND} -E copy_if_different
                            "${QT_BIN_DIR}/Qt6${component}d.dll"
                            $<TARGET_FILE_DIR:${PROJECT_NAME}>
                        COMMENT "Copying Qt6${component}d.dll"
                    )
                endif()
            endif()
        endforeach()

        set(QT_PLUGINS_DIR "${QT_BIN_DIR}/../plugins")
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E make_directory
                "$<TARGET_FILE_DIR:${PROJECT_NAME}>/platforms"
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                "${QT_PLUGINS_DIR}/platforms/qwindows.dll"
                "$<TARGET_FILE_DIR:${PROJECT_NAME}>/platforms/"
            COMMENT "Copying Qt platform plugin"
        )
    else()
        message(WARNING "Could not determine Qt binary directory! DLLs may be missing.")
    endif()
endif()