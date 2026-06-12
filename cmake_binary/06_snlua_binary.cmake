add_library(cservice_snlua MODULE
    "${SKYNET_ROOT}/service-src/service_snlua.c"
)

skynet_configure_module(cservice_snlua snlua "${SKYNET_CSERVICE_OUTPUT_DIR}")
