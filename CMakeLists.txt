cmake_minimum_required(VERSION 3.20)

project(skynet C)

set(CMAKE_C_STANDARD 99)
set(CMAKE_C_STANDARD_REQUIRED ON)
set(CMAKE_C_EXTENSIONS ON)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

option(SKYNET_ENABLE_TLS "Build ltls module" OFF)

set(SKYNET_ROOT "${CMAKE_CURRENT_SOURCE_DIR}")
set(SKYNET_PUBLISH_DIR "${SKYNET_ROOT}/publish")
set(SKYNET_EXE_OUTPUT_DIR "${SKYNET_PUBLISH_DIR}")
set(SKYNET_CSERVICE_OUTPUT_DIR "${SKYNET_PUBLISH_DIR}/lib/cservice")
set(SKYNET_LUACLIB_OUTPUT_DIR "${SKYNET_PUBLISH_DIR}/lib/luaclib")
set(SKYNET_LUA_SOURCE_DIR "${SKYNET_ROOT}/3rd/lua-x")
set(SKYNET_LUA_OUTPUT_DIR "${SKYNET_PUBLISH_DIR}/3rd/lua-x")

find_package(Threads REQUIRED)

add_library(skynet_common_options INTERFACE)
target_compile_options(skynet_common_options INTERFACE -g -O2 -Wall)
target_include_directories(skynet_common_options INTERFACE
    "${SKYNET_LUA_SOURCE_DIR}"
    "${SKYNET_ROOT}/skynet-src"
    "${SKYNET_ROOT}/service-src"
    "${SKYNET_ROOT}/lualib-src"
    "${SKYNET_ROOT}/lualib-src/sproto"
    "${SKYNET_ROOT}/3rd/lua-md5"
    "${SKYNET_ROOT}/3rd/lpeg"
    "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc"
)

if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    target_compile_definitions(skynet_common_options INTERFACE NOUSE_JEMALLOC)
endif()

if(APPLE)
    target_compile_definitions(skynet_common_options INTERFACE
        LUA_USE_MACOSX
        LUA_USE_READLINE
    )
elseif(CMAKE_SYSTEM_NAME STREQUAL "Linux")
    target_compile_definitions(skynet_common_options INTERFACE LUA_USE_LINUX)
elseif(CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    target_compile_definitions(skynet_common_options INTERFACE
        LUA_USE_LINUX
        LUA_USE_READLINE
    )
endif()

add_library(skynet_platform_libs INTERFACE)
target_link_libraries(skynet_platform_libs INTERFACE
    Threads::Threads
    m
    ${CMAKE_DL_LIBS}
)

function(skynet_apply_common target)
    target_link_libraries(${target} PRIVATE skynet_common_options)
endfunction()

function(skynet_set_runtime_output target output_name output_dir)
    set_target_properties(${target} PROPERTIES
        OUTPUT_NAME "${output_name}"
        RUNTIME_OUTPUT_DIRECTORY "${output_dir}"
        RUNTIME_OUTPUT_DIRECTORY_DEBUG "${output_dir}"
        RUNTIME_OUTPUT_DIRECTORY_RELEASE "${output_dir}"
        RUNTIME_OUTPUT_DIRECTORY_RELWITHDEBINFO "${output_dir}"
        RUNTIME_OUTPUT_DIRECTORY_MINSIZEREL "${output_dir}"
    )
endfunction()

function(skynet_set_archive_output target output_name output_dir)
    set_target_properties(${target} PROPERTIES
        OUTPUT_NAME "${output_name}"
        ARCHIVE_OUTPUT_DIRECTORY "${output_dir}"
        ARCHIVE_OUTPUT_DIRECTORY_DEBUG "${output_dir}"
        ARCHIVE_OUTPUT_DIRECTORY_RELEASE "${output_dir}"
        ARCHIVE_OUTPUT_DIRECTORY_RELWITHDEBINFO "${output_dir}"
        ARCHIVE_OUTPUT_DIRECTORY_MINSIZEREL "${output_dir}"
    )
endfunction()

function(skynet_configure_module target output_name output_dir)
    skynet_apply_common(${target})
    set_target_properties(${target} PROPERTIES
        PREFIX ""
        SUFFIX ".so"
        OUTPUT_NAME "${output_name}"
        LIBRARY_OUTPUT_DIRECTORY "${output_dir}"
        LIBRARY_OUTPUT_DIRECTORY_DEBUG "${output_dir}"
        LIBRARY_OUTPUT_DIRECTORY_RELEASE "${output_dir}"
        LIBRARY_OUTPUT_DIRECTORY_RELWITHDEBINFO "${output_dir}"
        LIBRARY_OUTPUT_DIRECTORY_MINSIZEREL "${output_dir}"
    )
    if(APPLE)
        target_link_options(${target} PRIVATE -undefined dynamic_lookup)
    endif()
endfunction()

include(cmake_binary/01_libjemalloc_pic_binary.cmake)
include(cmake_binary/88_lua_x_runtime_binary.cmake)
include(cmake_binary/89_lua_x_compiler_binary.cmake)
include(cmake_binary/05_skynet_exe_binary.cmake)
include(cmake_binary/06_snlua_binary.cmake)
include(cmake_binary/07_logger_binary.cmake)
include(cmake_binary/08_gate_binary.cmake)
include(cmake_binary/09_harbor_binary.cmake)
include(cmake_binary/10_skynet_lib_binary.cmake)
include(cmake_binary/11_client_binary.cmake)
include(cmake_binary/12_bson_binary.cmake)
include(cmake_binary/13_md5_binary.cmake)
include(cmake_binary/14_sproto_binary.cmake)
include(cmake_binary/15_lpeg_binary.cmake)
include(cmake_binary/16_ltls_binary.cmake)

add_dependencies(skynet
    lua-x-runtime
    lua-x-compiler
    snlua
    logger
    gate
    harbor
    skynet_lib
    client
    bson
    md5
    sproto
    lpeg
)

if(TARGET ltls)
    add_dependencies(skynet ltls)
endif()

add_custom_target(publish_lua_sources
    COMMAND ${CMAKE_COMMAND} -E make_directory "${SKYNET_PUBLISH_DIR}"
    COMMAND ${CMAKE_COMMAND} -E rm -rf
        "${SKYNET_PUBLISH_DIR}/examples"
        "${SKYNET_PUBLISH_DIR}/lualib"
        "${SKYNET_PUBLISH_DIR}/service"
        "${SKYNET_PUBLISH_DIR}/test"
        "${SKYNET_PUBLISH_DIR}/cservice"
        "${SKYNET_PUBLISH_DIR}/luaclib"
        "${SKYNET_PUBLISH_DIR}/lua"
    COMMAND ${CMAKE_COMMAND} -E make_directory "${SKYNET_PUBLISH_DIR}/lua"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${SKYNET_ROOT}/examples" "${SKYNET_PUBLISH_DIR}/lua/examples"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${SKYNET_ROOT}/lualib" "${SKYNET_PUBLISH_DIR}/lua/lualib"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${SKYNET_ROOT}/service" "${SKYNET_PUBLISH_DIR}/lua/service"
    COMMAND ${CMAKE_COMMAND} -E copy_directory "${SKYNET_ROOT}/test" "${SKYNET_PUBLISH_DIR}/lua/test"
    COMMENT "Copy Lua runtime sources and examples into publish"
    VERBATIM
)

add_custom_target(publish_lua_bytecode
    COMMAND "${SKYNET_ROOT}/tools/compile_lua_bytecode.sh"
    DEPENDS publish_lua_sources
    WORKING_DIRECTORY "${SKYNET_ROOT}"
    COMMENT "Compile Lua sources into publish/lua-bytecode"
    VERBATIM
)
add_dependencies(publish_lua_bytecode lua-x-compiler)

add_dependencies(skynet publish_lua_sources)
add_dependencies(skynet publish_lua_bytecode)
