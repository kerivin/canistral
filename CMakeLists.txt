cmake_minimum_required(VERSION 3.21)
project(Canistral VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# libraries
set(SUBMODULES_DIR "${CMAKE_SOURCE_DIR}/third_party")
set(QT_SUBMODULE_DIR "${SUBMODULES_DIR}/qt6")
set(SQLITE_SUBMODULE_DIR "${SUBMODULES_DIR}/sqlite3")
set(LIBREOFFICE_SDK_SUBMODULE_DIR "${SUBMODULES_DIR}/libreoffice-sdk")

add_subdirectory(${QT_SUBMODULE_DIR})
add_subdirectory(${SQLITE3_SUBMODULE_DIR})
add_subdirectory(${LIBREOFFICE_SDK_SUBMODULE_DIR})

# qt6
find_package(Qt6 REQUIRED COMPONENTS Core Gui Widgets)
if(WIN32)
        add_custom_command(TARGET ${PROJECT_NAME} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_directory
                "${QT_SUBMODULE_DIR}/bin"
                $<TARGET_FILE_DIR:${PROJECT_NAME}>
        )
endif()

# libreoffice
add_library(libreoffice-sdk)
target_include_directories(libreoffice-sdk "${LIBREOFFICE_SDK_SUBMODULE_DIR}/include")

# sqlite3
add_library(sqlite3)
target_include_directories(sqlite3 "${SQLITE3_SUBMODULE_DIR}/include")

target_link_libraries(${PROJECT_NAME} PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    SQLiteCpp
    sqlite3
    pthread
    dl
)

#sources
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

if(TARGET libreoffice-sdk)
    target_link_libraries(${PROJECT_NAME} PRIVATE libreoffice-sdk)
endif()

install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
    BUNDLE DESTINATION .
    LIBRARY DESTINATION lib
)