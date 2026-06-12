if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    add_custom_target(libjemalloc_pic
        COMMENT "jemalloc is disabled on this platform"
    )

    add_library(skynet_jemalloc INTERFACE)
    target_compile_definitions(skynet_jemalloc INTERFACE NOUSE_JEMALLOC)
else()
    set(SKYNET_JEMALLOC_STATICLIB
        "${SKYNET_ROOT}/3rd/jemalloc/lib/libjemalloc_pic.a"
    )

    add_custom_target(libjemalloc_pic
        COMMAND git submodule update --init
        COMMAND ./autogen.sh --with-jemalloc-prefix=je_ --enable-prof
        COMMAND ${CMAKE_MAKE_PROGRAM} CC=${CMAKE_C_COMPILER}
        WORKING_DIRECTORY "${SKYNET_ROOT}/3rd/jemalloc"
        COMMENT "Build jemalloc static library"
        VERBATIM
    )

    add_library(skynet_jemalloc STATIC IMPORTED GLOBAL)
    set_target_properties(skynet_jemalloc PROPERTIES
        IMPORTED_LOCATION "${SKYNET_JEMALLOC_STATICLIB}"
        INTERFACE_INCLUDE_DIRECTORIES "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc"
    )
    add_dependencies(skynet_jemalloc libjemalloc_pic)
endif()
