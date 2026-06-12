add_library(harbor MODULE
    "${SKYNET_ROOT}/service-src/service_harbor.c"
)

skynet_configure_module(harbor harbor "${SKYNET_CSERVICE_OUTPUT_DIR}")
