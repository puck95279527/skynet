add_library(luaclib_bson MODULE
    "${SKYNET_ROOT}/lualib-src/lua-bson.c"
)

skynet_configure_module(luaclib_bson bson "${SKYNET_LUACLIB_OUTPUT_DIR}")
