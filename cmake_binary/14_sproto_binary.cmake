add_library(luaclib_sproto MODULE
    "${SKYNET_ROOT}/lualib-src/sproto/sproto.c"
    "${SKYNET_ROOT}/lualib-src/sproto/lsproto.c"
)

skynet_configure_module(luaclib_sproto sproto "${SKYNET_LUACLIB_OUTPUT_DIR}")
