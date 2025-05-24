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

execute_process(COMMAND ${Python3_EXECUTABLE} -m venv "${PYTHON_VENV_DIR}")

if(WIN32)
    set(VENV_PIP_EXECUTABLE "${PYTHON_VENV_DIR}/Scripts/pip.exe")
    set(VENV_SITE_PACKAGES "${PYTHON_VENV_DIR}/Lib/site-packages")
else()
    set(VENV_PIP_EXECUTABLE "${PYTHON_VENV_DIR}/bin/pip")
    set(VENV_SITE_PACKAGES "${PYTHON_VENV_DIR}/lib/python${Python3_VERSION_MAJOR}.${Python3_VERSION_MINOR}/site-packages")
endif()

#-----------------------------------------------------------------------------
# Python Packages
#-----------------------------------------------------------------------------

set(PYTHON_MODULES
    translators
    python-iso639
)

foreach(pkg IN LISTS PYTHON_MODULES)
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

set(PYBIND11_FINDPYTHON ON)

include(FetchContent)
FetchContent_Declare(
  pybind11
  GIT_REPOSITORY https://github.com/pybind/pybind11.git
  GIT_TAG v2.13.6
)
FetchContent_MakeAvailable(pybind11)