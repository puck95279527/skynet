if(SKYNET_ENABLE_TLS)
    add_library(luaclib_ltls MODULE
        "${SKYNET_ROOT}/lualib-src/ltls.c"
    )

    skynet_configure_module(luaclib_ltls ltls "${SKYNET_LUACLIB_OUTPUT_DIR}")
    target_include_directories(luaclib_ltls PRIVATE ${TLS_INC})
    target_link_directories(luaclib_ltls PRIVATE ${TLS_LIB})
    target_link_libraries(luaclib_ltls PRIVATE ssl crypto)
endif()
