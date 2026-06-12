add_library(bson MODULE
    "${SKYNET_ROOT}/lualib-src/lua-bson.c"
)

skynet_configure_module(bson bson "${SKYNET_LUACLIB_OUTPUT_DIR}")
