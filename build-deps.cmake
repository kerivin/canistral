# Cross-platform dependency builder
cmake_minimum_required(VERSION 3.21)
project(DependencyInstaller)

set(DEPS_DIR "${CMAKE_CURRENT_BINARY_DIR}/dep-build")

if(WIN32)
    # Windows - Chocolatey
    find_program(CHOCO choco REQUIRED)
    execute_process(
        COMMAND ${CHOCO} install -y qt6 --params="/InstallationDirectory ${DEPS_DIR}/Qt /DesktopWin64"
        COMMAND ${CHOCO} install -y sqlite --params="/InstallationDirectory ${DEPS_DIR}/SQLite"
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
elseif(APPLE)
    # macOS - Homebrew
    find_program(BREW brew REQUIRED)
    execute_process(
        COMMAND ${BREW} install qt@6
        COMMAND ${BREW} install sqlite
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    # Symlink to dep-build for consistency
    execute_process(
        COMMAND ln -s "$(brew --prefix qt@6)" "${DEPS_DIR}/Qt"
        COMMAND ln -s "$(brew --prefix sqlite)" "${DEPS_DIR}/SQLite"
    )
else()
    # Linux - apt
    find_program(APT apt-get REQUIRED)
    execute_process(
        COMMAND sudo ${APT} install -y qt6-base-dev libsqlite3-dev
        WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
    )
    # Symlink to dep-build
    execute_process(
        COMMAND ln -s "/usr/lib/qt6" "${DEPS_DIR}/Qt"
        COMMAND ln -s "/usr/include/sqlite3.h" "${DEPS_DIR}/SQLite"
    )
endif()

message(STATUS "Dependencies installed to: ${DEPS_DIR}")