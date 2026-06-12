add_library(luaclib_skynet MODULE
    "${SKYNET_ROOT}/lualib-src/lua-skynet.c"
    "${SKYNET_ROOT}/lualib-src/lua-seri.c"
    "${SKYNET_ROOT}/lualib-src/lua-socket.c"
    "${SKYNET_ROOT}/lualib-src/lua-mongo.c"
    "${SKYNET_ROOT}/lualib-src/lua-netpack.c"
    "${SKYNET_ROOT}/lualib-src/lua-memory.c"
    "${SKYNET_ROOT}/lualib-src/lua-multicast.c"
    "${SKYNET_ROOT}/lualib-src/lua-cluster.c"
    "${SKYNET_ROOT}/lualib-src/lua-crypt.c"
    "${SKYNET_ROOT}/lualib-src/lsha1.c"
    "${SKYNET_ROOT}/lualib-src/lua-sharedata.c"
    "${SKYNET_ROOT}/lualib-src/lua-stm.c"
    "${SKYNET_ROOT}/lualib-src/lua-debugchannel.c"
    "${SKYNET_ROOT}/lualib-src/lua-datasheet.c"
    "${SKYNET_ROOT}/lualib-src/lua-sharetable.c"
)

skynet_configure_module(luaclib_skynet skynet "${SKYNET_LUACLIB_OUTPUT_DIR}")
