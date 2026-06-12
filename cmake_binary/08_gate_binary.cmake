add_library(cservice_gate MODULE
    "${SKYNET_ROOT}/service-src/service_gate.c"
)

skynet_configure_module(cservice_gate gate "${SKYNET_CSERVICE_OUTPUT_DIR}")
