add_library(gate MODULE
    "${SKYNET_ROOT}/service-src/service_gate.c"
)

skynet_configure_module(gate gate "${SKYNET_CSERVICE_OUTPUT_DIR}")
