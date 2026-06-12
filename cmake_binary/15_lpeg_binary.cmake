add_library(luaclib_lpeg MODULE
    "${SKYNET_ROOT}/3rd/lpeg/lpcap.c"
    "${SKYNET_ROOT}/3rd/lpeg/lpcode.c"
    "${SKYNET_ROOT}/3rd/lpeg/lpprint.c"
    "${SKYNET_ROOT}/3rd/lpeg/lptree.c"
    "${SKYNET_ROOT}/3rd/lpeg/lpvm.c"
    "${SKYNET_ROOT}/3rd/lpeg/lpcset.c"
)

skynet_configure_module(luaclib_lpeg lpeg "${SKYNET_LUACLIB_OUTPUT_DIR}")
