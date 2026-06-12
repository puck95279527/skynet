add_executable(skynet_exe
    "${SKYNET_ROOT}/skynet-src/skynet_main.c"
    "${SKYNET_ROOT}/skynet-src/skynet_handle.c"
    "${SKYNET_ROOT}/skynet-src/skynet_module.c"
    "${SKYNET_ROOT}/skynet-src/skynet_mq.c"
    "${SKYNET_ROOT}/skynet-src/skynet_server.c"
    "${SKYNET_ROOT}/skynet-src/skynet_start.c"
    "${SKYNET_ROOT}/skynet-src/skynet_timer.c"
    "${SKYNET_ROOT}/skynet-src/skynet_error.c"
    "${SKYNET_ROOT}/skynet-src/skynet_harbor.c"
    "${SKYNET_ROOT}/skynet-src/skynet_env.c"
    "${SKYNET_ROOT}/skynet-src/skynet_monitor.c"
    "${SKYNET_ROOT}/skynet-src/skynet_socket.c"
    "${SKYNET_ROOT}/skynet-src/socket_server.c"
    "${SKYNET_ROOT}/skynet-src/mem_info.c"
    "${SKYNET_ROOT}/skynet-src/malloc_hook.c"
    "${SKYNET_ROOT}/skynet-src/skynet_daemon.c"
    "${SKYNET_ROOT}/skynet-src/skynet_log.c"
)

skynet_apply_common(skynet_exe)
target_link_libraries(skynet_exe PRIVATE
    liblua
    skynet_jemalloc
    skynet_platform_libs
)
skynet_set_runtime_output(skynet_exe skynet "${SKYNET_EXE_OUTPUT_DIR}")
