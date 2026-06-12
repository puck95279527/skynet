add_library(logger MODULE
    "${SKYNET_ROOT}/service-src/service_logger.c"
)

skynet_configure_module(logger logger "${SKYNET_CSERVICE_OUTPUT_DIR}")
