cmake_minimum_required(VERSION 3.25)
project(Canistral LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_MODULE_PATH
    ${CMAKE_MODULE_PATH}
    ${CMAKE_CURRENT_SOURCE_DIR}
)

if(WIN32)
    message(WARNING "WINDOWS BUILD HASN'T BEEN TESTED")
    execute_process(COMMAND scripts/install_windows.bat)
elseif(APPLE)
    message(WARNING "MACOS BUILD HASN'T BEEN TESTED")
    execute_process(COMMAND sh scripts/install_macos.sh)
else()
    execute_process(COMMAND sh scripts/install_linux.sh)
endif()


# Find dependencies
find_package(Qt6 REQUIRED COMPONENTS Core Widgets)
find_package(SQLite3 REQUIRED)
find_package(LibreOffice REQUIRED)

message(STATUS "CMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
message(STATUS "LibreOffice at: ${LibreOffice_DIR}")
message(STATUS "LibreOffice headers at: ${LibreOffice_INCLUDE_DIRS}")
message(STATUS "LibreOffice libraries at: ${LibreOffice_LIBRARIES}")

file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)

# Main executable
add_executable(${PROJECT_NAME}
    ${SOURCES}
    main.cpp
)

target_include_directories(${PROJECT_NAME} PRIVATE
    include
    ${SQLite3_INCLUDE_DIRS}
    ${LibreOffice_INCLUDE_DIRS}
    ${Qt6_INCLUDE_DIRS}
)

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Widgets
    SQLite::SQLite3
    ${LibreOffice_LIBRARIES}
)

# Post-build for Windows (copy Qt DLLs)
if(WIN32)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:Qt6::Core>"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:Qt6::Widgets>"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    )
endif()

# Install instructions
install(TARGETS ${PROJECT_NAME} 
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION Applications  # macOS .app
)