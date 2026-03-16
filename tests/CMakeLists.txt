include(FetchContent)

FetchContent_Declare(
    googletest
    GIT_REPOSITORY https://github.com/google/googletest.git
    GIT_TAG        v1.15.2
)
# Prevent GoogleTest from overriding our compiler/linker options on Windows
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)
FetchContent_MakeAvailable(googletest)

include(GoogleTest)

# ── Macro: add a test executable with standard linkage ────────────────────────
# Usage: add_gtest(my_tests test_my_feature.cpp)
macro(add_gtest target source)
    add_executable(${target} ${source})
    target_include_directories(${target} PRIVATE ${PROJECT_SOURCE_DIR}/include)
    target_link_libraries(${target}
        PRIVATE
            ${PROJECT_NAME}_lib
            GTest::gtest_main
            GTest::gmock_main
    )
    gtest_discover_tests(${target})
endmacro()

# ── Test executables ──────────────────────────────────────────────────────────
# TODO: add test files here using add_gtest()
# Example:
#   add_gtest(${PROJECT_NAME}_myfeature_tests test_myfeature.cpp)
add_gtest(${PROJECT_NAME}_placeholder_tests test_placeholder.cpp)
