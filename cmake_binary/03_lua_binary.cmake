add_executable(lua
    "${SKYNET_LUA_SOURCE_DIR}/lua.c"
)

skynet_apply_common(lua)
target_link_libraries(lua PRIVATE liblua skynet_platform_libs)
if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "FreeBSD" OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    target_link_libraries(lua PRIVATE readline)
endif()
skynet_set_runtime_output(lua lua "${SKYNET_LUA_OUTPUT_DIR}")
