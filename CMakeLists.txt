cmake_minimum_required(VERSION 3.13)

project(tree-sitter-shellspec
        # x-release-please-start-version
        VERSION "0.1.0"
        # x-release-please-end
        DESCRIPTION "ShellSpec grammar for tree-sitter (extends bash)"
        HOMEPAGE_URL "https://github.com/ivuorinen/tree-sitter-shellspec"
        LANGUAGES C)

option(BUILD_SHARED_LIBS "Build using shared libraries" ON)
option(TREE_SITTER_REUSE_ALLOCATOR "Reuse the library allocator" OFF)

set(TREE_SITTER_ABI_VERSION 15 CACHE STRING "Tree-sitter ABI version")
if(NOT ${TREE_SITTER_ABI_VERSION} MATCHES "^[0-9]+$")
    unset(TREE_SITTER_ABI_VERSION CACHE)
    message(FATAL_ERROR "TREE_SITTER_ABI_VERSION must be an integer")
endif()

include(GNUInstallDirs)

# Not REQUIRED: src/parser.c is committed, so a consumer can build this library with
# no tree-sitter CLI installed. Requiring it here failed configuration before CMake
# ever reached the checked-in sources. The regeneration rules and the ts-test target
# are registered only when the CLI is actually present.
find_program(TREE_SITTER_CLI tree-sitter DOC "Tree-sitter CLI")

if(TREE_SITTER_CLI)
  add_custom_command(OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/grammar.json"
                            "${CMAKE_CURRENT_SOURCE_DIR}/src/node-types.json"
                     DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/grammar.js"
                     COMMAND "${TREE_SITTER_CLI}" generate grammar.js --no-parser
                     WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                     COMMENT "Generating grammar.json")

  add_custom_command(OUTPUT "${CMAKE_CURRENT_SOURCE_DIR}/src/parser.c"
                     BYPRODUCTS "${CMAKE_CURRENT_SOURCE_DIR}/src/tree_sitter/parser.h"
                                "${CMAKE_CURRENT_SOURCE_DIR}/src/tree_sitter/alloc.h"
                                "${CMAKE_CURRENT_SOURCE_DIR}/src/tree_sitter/array.h"
                     DEPENDS "${CMAKE_CURRENT_SOURCE_DIR}/src/grammar.json"
                     COMMAND "${TREE_SITTER_CLI}" generate src/grammar.json
                              --abi=${TREE_SITTER_ABI_VERSION}
                     WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                     COMMENT "Generating parser.c")
endif()

add_library(tree-sitter-shellspec src/parser.c)
if(EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/src/scanner.c)
  target_sources(tree-sitter-shellspec PRIVATE src/scanner.c)
endif()
target_include_directories(tree-sitter-shellspec
                           PRIVATE src
                           INTERFACE $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/bindings/c>
                                     $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>)

target_compile_definitions(tree-sitter-shellspec PRIVATE
                           $<$<BOOL:${TREE_SITTER_REUSE_ALLOCATOR}>:TREE_SITTER_REUSE_ALLOCATOR>
                           $<$<CONFIG:Debug>:TREE_SITTER_DEBUG>)

set_target_properties(tree-sitter-shellspec
                      PROPERTIES
                      C_STANDARD 11
                      POSITION_INDEPENDENT_CODE ON
                      SOVERSION "${TREE_SITTER_ABI_VERSION}.${PROJECT_VERSION_MAJOR}"
                      DEFINE_SYMBOL "")

configure_file(bindings/c/tree-sitter-shellspec.pc.in
               "${CMAKE_CURRENT_BINARY_DIR}/tree-sitter-shellspec.pc" @ONLY)

install(DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/bindings/c/tree_sitter"
        DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}"
        FILES_MATCHING PATTERN "*.h")
install(FILES "${CMAKE_CURRENT_BINARY_DIR}/tree-sitter-shellspec.pc"
        DESTINATION "${CMAKE_INSTALL_LIBDIR}/pkgconfig")
# LIBRARY alone covers only the shared .so. ARCHIVE installs the static .a produced
# when BUILD_SHARED_LIBS=OFF, and RUNTIME installs the DLL, which is the artifact type
# a shared build emits on Windows. Without these two, both builds install nothing.
install(TARGETS tree-sitter-shellspec
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}")

file(GLOB QUERIES queries/*.scm)
install(FILES ${QUERIES}
        DESTINATION "${CMAKE_INSTALL_DATADIR}/tree-sitter/queries/shellspec")

if(TREE_SITTER_CLI)
  add_custom_target(ts-test "${TREE_SITTER_CLI}" test
                    WORKING_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}"
                    COMMENT "tree-sitter test")
endif()
