if(SKYNET_ENABLE_TLS)
    add_library(ltls MODULE
        "${SKYNET_ROOT}/lualib-src/ltls.c"
    )

    skynet_configure_module(ltls ltls "${SKYNET_LUACLIB_OUTPUT_DIR}")
    target_include_directories(ltls PRIVATE ${TLS_INC})
    target_link_directories(ltls PRIVATE ${TLS_LIB})
    target_link_libraries(ltls PRIVATE ssl crypto)
endif()
