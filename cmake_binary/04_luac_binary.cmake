add_executable(luac
    "${SKYNET_ROOT}/3rd/lua/luac.c"
)

skynet_apply_common(luac)
target_link_libraries(luac PRIVATE liblua skynet_platform_libs)
if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    target_link_libraries(luac PRIVATE readline)
endif()
skynet_set_runtime_output(luac luac "${SKYNET_LUA_OUTPUT_DIR}")
