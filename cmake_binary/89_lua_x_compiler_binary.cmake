set(SKYNET_LUA_X_COMPILER_SOURCES
    "${SKYNET_LUA_SOURCE_DIR}/lapi.c"
    "${SKYNET_LUA_SOURCE_DIR}/lcode.c"
    "${SKYNET_LUA_SOURCE_DIR}/lctype.c"
    "${SKYNET_LUA_SOURCE_DIR}/ldebug.c"
    "${SKYNET_LUA_SOURCE_DIR}/ldo.c"
    "${SKYNET_LUA_SOURCE_DIR}/ldump.c"
    "${SKYNET_LUA_SOURCE_DIR}/lfunc.c"
    "${SKYNET_LUA_SOURCE_DIR}/lgc.c"
    "${SKYNET_LUA_SOURCE_DIR}/llex.c"
    "${SKYNET_LUA_SOURCE_DIR}/lmem.c"
    "${SKYNET_LUA_SOURCE_DIR}/lobject.c"
    "${SKYNET_LUA_SOURCE_DIR}/lopcodes.c"
    "${SKYNET_LUA_SOURCE_DIR}/lparser.c"
    "${SKYNET_LUA_SOURCE_DIR}/lstate.c"
    "${SKYNET_LUA_SOURCE_DIR}/lstring.c"
    "${SKYNET_LUA_SOURCE_DIR}/ltable.c"
    "${SKYNET_LUA_SOURCE_DIR}/ltm.c"
    "${SKYNET_LUA_SOURCE_DIR}/lundump.c"
    "${SKYNET_LUA_SOURCE_DIR}/lvm.c"
    "${SKYNET_LUA_SOURCE_DIR}/lzio.c"
    "${SKYNET_LUA_SOURCE_DIR}/lauxlib.c"
    "${SKYNET_LUA_SOURCE_DIR}/lbaselib.c"
    "${SKYNET_LUA_SOURCE_DIR}/lcorolib.c"
    "${SKYNET_LUA_SOURCE_DIR}/ldblib.c"
    "${SKYNET_LUA_SOURCE_DIR}/liolib.c"
    "${SKYNET_LUA_SOURCE_DIR}/lmathlib.c"
    "${SKYNET_LUA_SOURCE_DIR}/loadlib.c"
    "${SKYNET_LUA_SOURCE_DIR}/loslib.c"
    "${SKYNET_LUA_SOURCE_DIR}/lstrlib.c"
    "${SKYNET_LUA_SOURCE_DIR}/ltablib.c"
    "${SKYNET_LUA_SOURCE_DIR}/lutf8lib.c"
    "${SKYNET_LUA_SOURCE_DIR}/linit.c"
)

add_library(lua_x_compiler_lib STATIC ${SKYNET_LUA_X_COMPILER_SOURCES})

skynet_apply_common(lua_x_compiler_lib)
target_include_directories(lua_x_compiler_lib PUBLIC "${SKYNET_LUA_SOURCE_DIR}")

add_executable(lua_x_compiler
    "${SKYNET_LUA_SOURCE_DIR}/luac.c"
)

skynet_apply_common(lua_x_compiler)
target_link_libraries(lua_x_compiler PRIVATE lua_x_compiler_lib skynet_platform_libs)
if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    target_link_libraries(lua_x_compiler PRIVATE readline)
endif()
skynet_set_runtime_output(lua_x_compiler lua-x-compiler "${SKYNET_LUA_OUTPUT_DIR}")

add_custom_target(lua-x-compiler DEPENDS lua_x_compiler)
