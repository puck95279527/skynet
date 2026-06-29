set(SKYNET_LUA_X_RUNTIME_SOURCES
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

add_library(lua_x_runtime STATIC ${SKYNET_LUA_X_RUNTIME_SOURCES})

skynet_apply_common(lua_x_runtime)
target_include_directories(lua_x_runtime PUBLIC "${SKYNET_LUA_SOURCE_DIR}")
skynet_set_archive_output(lua_x_runtime lua-x-runtime "${SKYNET_LUA_OUTPUT_DIR}")
set_target_properties(lua_x_runtime PROPERTIES PREFIX "")

add_custom_target(lua-x-clean-legacy-output
    COMMAND ${CMAKE_COMMAND} -E rm -f
        "${SKYNET_LUA_OUTPUT_DIR}/liblua.a"
        "${SKYNET_LUA_OUTPUT_DIR}/lua"
        "${SKYNET_LUA_OUTPUT_DIR}/luac"
    COMMENT "Remove legacy Lua outputs from lua-x publish directory"
    VERBATIM
)

add_dependencies(lua_x_runtime lua-x-clean-legacy-output)
add_custom_target(lua-x-runtime DEPENDS lua_x_runtime)
