add_library(client MODULE
    "${SKYNET_ROOT}/lualib-src/lua-clientsocket.c"
    "${SKYNET_ROOT}/lualib-src/lua-crypt.c"
    "${SKYNET_ROOT}/lualib-src/lsha1.c"
)

skynet_configure_module(client client "${SKYNET_LUACLIB_OUTPUT_DIR}")
target_link_libraries(client PRIVATE Threads::Threads)
