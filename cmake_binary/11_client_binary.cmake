add_library(luaclib_client MODULE
    "${SKYNET_ROOT}/lualib-src/lua-clientsocket.c"
    "${SKYNET_ROOT}/lualib-src/lua-crypt.c"
    "${SKYNET_ROOT}/lualib-src/lsha1.c"
)

skynet_configure_module(luaclib_client client "${SKYNET_LUACLIB_OUTPUT_DIR}")
target_link_libraries(luaclib_client PRIVATE Threads::Threads)
