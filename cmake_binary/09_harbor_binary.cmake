add_library(cservice_harbor MODULE
    "${SKYNET_ROOT}/service-src/service_harbor.c"
)

skynet_configure_module(cservice_harbor harbor "${SKYNET_CSERVICE_OUTPUT_DIR}")
