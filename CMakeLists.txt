cmake_minimum_required(VERSION 3.20)

# ── Project ───────────────────────────────────────────────────────────────────
# TODO: rename project and update VERSION
project(my_project VERSION 0.1.0 LANGUAGES CXX)

# ── C++ standard ──────────────────────────────────────────────────────────────
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# ── Compiler warnings ─────────────────────────────────────────────────────────
add_compile_options(
    -Wall
    -Wextra
    -Wpedantic
    -Werror
    -Wswitch          # warn on unhandled enum values in switch
)

# ── Export compile commands (feeds Intellisense) ──────────────────────────────
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# ── Main library ──────────────────────────────────────────────────────────────
# TODO: add your .cpp source files here
add_library(${PROJECT_NAME}_lib
    src/placeholder.cpp
)
target_include_directories(${PROJECT_NAME}_lib PUBLIC include)

# ── Main executable ───────────────────────────────────────────────────────────
add_executable(${PROJECT_NAME} src/main.cpp)
target_link_libraries(${PROJECT_NAME} PRIVATE ${PROJECT_NAME}_lib)

# ── Tests ─────────────────────────────────────────────────────────────────────
option(BUILD_TESTS "Build tests" ON)
if(BUILD_TESTS)
    enable_testing()
    add_subdirectory(tests)
endif()
