add_executable(skynet
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
    "${SKYNET_ROOT}/skynet-src/malloc_hook.c"
    "${SKYNET_ROOT}/skynet-src/skynet_daemon.c"
    "${SKYNET_ROOT}/skynet-src/skynet_log.c"
)

skynet_apply_common(skynet)
target_link_libraries(skynet PRIVATE
    lua_x_runtime
    skynet_jemalloc
    skynet_platform_libs
)

if(TARGET libjemalloc_pic)
    add_dependencies(skynet libjemalloc_pic)
endif()

if(UNIX AND NOT APPLE)
    target_link_options(skynet PRIVATE -Wl,-E)
endif()

skynet_set_runtime_output(skynet skynet "${SKYNET_EXE_OUTPUT_DIR}")
