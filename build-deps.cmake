# Dependency installer script (runs with cmake -P)
set(DEPS_DIR "${CMAKE_CURRENT_BINARY_DIR}/dep-build")
file(MAKE_DIRECTORY "${DEPS_DIR}")

message(STATUS "Building dependencies in: ${DEPS_DIR}")

# Platform detection
if(WIN32)
    # Windows - Chocolatey
    execute_process(COMMAND powershell -ExecutionPolicy Bypass -File
        "${CMAKE_CURRENT_SOURCE_DIR}/scripts/install_chocolatey.ps1" WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
    )
    find_program(CHOCO choco)
    if(CHOCO)
        execute_process(
            COMMAND ${CHOCO} install -y qt6 --no-progress --params="/InstallationDirectory ${DEPS_DIR}/Qt /DesktopWin64"
            COMMAND ${CHOCO} install -y sqlite --no-progress --params="/InstallationDirectory ${DEPS_DIR}/SQLite"
            COMMAND ${CHOCO} install -y libreoffice-fresh --no-progress --params="/InstallationDirectory ${DEPS_DIR}/LibreOffice"
        )
    else()
        message(WARNING "Chocolatey not found - manual dependency installation required")
    endif()

elseif(APPLE)
    # macOS - Homebrew
    find_program(BREW brew)
    if(BREW)
        execute_process(
            COMMAND ${BREW} install qt@6 sqlite libreoffice
        )
        # Create symlinks in dep-build
        execute_process(
            COMMAND ${BREW} --prefix qt@6
            OUTPUT_VARIABLE QT6_PREFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        file(CREATE_LINK "${DEPS_DIR}/Qt" "${QT6_PREFIX}" SYMBOLIC)
        
        execute_process(
            COMMAND ${BREW} --prefix sqlite
            OUTPUT_VARIABLE SQLITE_PREFIX
            OUTPUT_STRIP_TRAILING_WHITESPACE
        )
        file(CREATE_LINK "${DEPS_DIR}/SQLite" "${SQLITE_PREFIX}" SYMBOLIC)
        
        file(CREATE_LINK "${DEPS_DIR}/LibreOffice" "/Applications/LibreOffice.app/Contents/Resources/sdk" SYMBOLIC)
    else()
        message(WARNING "Homebrew not found - manual dependency installation required")
    endif()

else()
    # Linux - apt
    find_program(APT apt-get)
    if(APT)
        execute_process(
            COMMAND sudo ${APT} update
            COMMAND sudo ${APT} install -y qt6-base-dev libsqlite3-dev libreoffice-dev
        )
        # Create links in dep-build
        file(MAKE_DIRECTORY "${DEPS_DIR}/Qt")
        file(COPY "/usr/lib/qt6/" DESTINATION "${DEPS_DIR}/Qt")
        
        file(MAKE_DIRECTORY "${DEPS_DIR}/SQLite")
        file(COPY "/usr/include/sqlite3.h" DESTINATION "${DEPS_DIR}/SQLite/include")
        
        file(MAKE_DIRECTORY "${DEPS_DIR}/LibreOffice")
        file(COPY "/usr/lib/libreoffice/sdk/" DESTINATION "${DEPS_DIR}/LibreOffice/sdk")
    else()
        message(WARNING "apt-get not found - manual dependency installation required")
    endif()
endif()

message(STATUS "Dependencies installed to: ${DEPS_DIR}")