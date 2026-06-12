add_library(cservice_logger MODULE
    "${SKYNET_ROOT}/service-src/service_logger.c"
)

skynet_configure_module(cservice_logger logger "${SKYNET_CSERVICE_OUTPUT_DIR}")
