add_library(md5 MODULE
    "${SKYNET_ROOT}/3rd/lua-md5/md5.c"
    "${SKYNET_ROOT}/3rd/lua-md5/md5lib.c"
    "${SKYNET_ROOT}/3rd/lua-md5/compat-5.2.c"
)

skynet_configure_module(md5 md5 "${SKYNET_LUACLIB_OUTPUT_DIR}")
