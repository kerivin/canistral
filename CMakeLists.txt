cmake_minimum_required(VERSION 3.21)
project(Canistral LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Set dependency paths
set(DEPS_DIR "${CMAKE_BINARY_DIR}/dep-build")

# Qt6 setup
list(APPEND CMAKE_PREFIX_PATH 
    "${DEPS_DIR}/Qt"
    "${DEPS_DIR}/Qt/6.6.0/msvc2019_64"  # Windows specific
)
find_package(Qt6 REQUIRED COMPONENTS Core)

# SQLite setup
find_path(SQLite3_INCLUDE_DIR sqlite3.h
    PATHS "${DEPS_DIR}/SQLite"
    "${DEPS_DIR}/SQLite/include"
)
find_library(SQLite3_LIBRARY sqlite3
    PATHS "${DEPS_DIR}/SQLite"
    "${DEPS_DIR}/SQLite/lib"
)

# Create executable
file(GLOB_RECURSE SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/src/*.cpp)
add_executable(${PROJECT_NAME} main.cpp ${SOURCES})
target_link_libraries(${PROJECT_NAME} PRIVATE 
    Qt6::Core
    ${SQLite3_LIBRARY}
)
target_include_directories(${PROJECT_NAME} PRIVATE ${SQLite3_INCLUDE_DIR})

# Windows DLL copy
if(WIN32)
    add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E copy
            "$<TARGET_FILE:Qt6::Core>"
            "$<TARGET_FILE_DIR:${PROJECT_NAME}>"
    )
endif()