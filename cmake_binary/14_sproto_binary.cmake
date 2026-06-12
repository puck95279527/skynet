add_library(sproto MODULE
    "${SKYNET_ROOT}/lualib-src/sproto/sproto.c"
    "${SKYNET_ROOT}/lualib-src/sproto/lsproto.c"
)

skynet_configure_module(sproto sproto "${SKYNET_LUACLIB_OUTPUT_DIR}")
