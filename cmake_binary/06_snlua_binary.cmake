add_library(snlua MODULE
    "${SKYNET_ROOT}/service-src/service_snlua.c"
)

skynet_configure_module(snlua snlua "${SKYNET_CSERVICE_OUTPUT_DIR}")
