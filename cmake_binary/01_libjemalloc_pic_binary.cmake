if(APPLE OR CMAKE_SYSTEM_NAME STREQUAL "OpenBSD")
    add_custom_target(libjemalloc_pic
        COMMENT "jemalloc is disabled on this platform"
    )
    add_custom_target(clean_jemalloc
        COMMENT "jemalloc is disabled on this platform"
    )

    add_library(skynet_jemalloc INTERFACE)
    target_compile_definitions(skynet_jemalloc INTERFACE NOUSE_JEMALLOC)
else()
    find_program(SKYNET_MAKE_PROGRAM NAMES gmake make REQUIRED)
    include(ProcessorCount)
    ProcessorCount(SKYNET_CPU_COUNT)
    if(NOT SKYNET_CPU_COUNT)
        set(SKYNET_CPU_COUNT 1)
    endif()
    set(SKYNET_JEMALLOC_JOBS "${SKYNET_CPU_COUNT}" CACHE STRING
        "Parallel jobs used when delegating jemalloc builds to the Makefile"
    )

    set(SKYNET_JEMALLOC_STATICLIB
        "${SKYNET_ROOT}/3rd/jemalloc/lib/libjemalloc_pic.a"
    )

    file(GLOB SKYNET_JEMALLOC_SOURCE_FILES
        "${SKYNET_ROOT}/3rd/jemalloc/src/*.c"
        "${SKYNET_ROOT}/3rd/jemalloc/src/*.cpp"
    )
    set(SKYNET_JEMALLOC_CLEAN_FILES
        "${SKYNET_ROOT}/3rd/jemalloc/Makefile"
        "${SKYNET_ROOT}/3rd/jemalloc/config.log"
        "${SKYNET_ROOT}/3rd/jemalloc/config.status"
        "${SKYNET_ROOT}/3rd/jemalloc/config.stamp"
        "${SKYNET_ROOT}/3rd/jemalloc/configure~"
        "${SKYNET_ROOT}/3rd/jemalloc/jemalloc.pc"
        "${SKYNET_ROOT}/3rd/jemalloc/bin/jemalloc-config"
        "${SKYNET_ROOT}/3rd/jemalloc/bin/jemalloc.sh"
        "${SKYNET_ROOT}/3rd/jemalloc/bin/jeprof"
        "${SKYNET_ROOT}/3rd/jemalloc/lib/libjemalloc.a"
        "${SKYNET_ROOT}/3rd/jemalloc/lib/libjemalloc_pic.a"
        "${SKYNET_ROOT}/3rd/jemalloc/lib/libjemalloc.so"
        "${SKYNET_ROOT}/3rd/jemalloc/lib/libjemalloc.so.2"
        "${SKYNET_ROOT}/3rd/jemalloc/doc/html.xsl"
        "${SKYNET_ROOT}/3rd/jemalloc/doc/manpages.xsl"
        "${SKYNET_ROOT}/3rd/jemalloc/doc/jemalloc.xml"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_defs.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_macros.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_mangle.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_mangle_jet.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_protos.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_protos_jet.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_rename.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/jemalloc_typedefs.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/jemalloc_internal_defs.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/jemalloc_preamble.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/private_namespace.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/private_namespace.gen.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/private_namespace_jet.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/private_namespace_jet.gen.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/private_symbols.awk"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/private_symbols_jet.awk"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/public_namespace.h"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/public_symbols.txt"
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc/internal/public_unnamespace.h"
        "${SKYNET_ROOT}/3rd/jemalloc/test/include/test/jemalloc_test.h"
        "${SKYNET_ROOT}/3rd/jemalloc/test/include/test/jemalloc_test_defs.h"
        "${SKYNET_ROOT}/3rd/jemalloc/test/test.sh"
    )
    foreach(SKYNET_JEMALLOC_SOURCE_FILE IN LISTS SKYNET_JEMALLOC_SOURCE_FILES)
        get_filename_component(SKYNET_JEMALLOC_SOURCE_NAME "${SKYNET_JEMALLOC_SOURCE_FILE}" NAME_WE)
        list(APPEND SKYNET_JEMALLOC_CLEAN_FILES
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.o"
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.d"
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.pic.o"
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.pic.d"
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.sym"
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.sym.o"
            "${SKYNET_ROOT}/3rd/jemalloc/src/${SKYNET_JEMALLOC_SOURCE_NAME}.sym.d"
        )
    endforeach()
    set_property(DIRECTORY APPEND PROPERTY ADDITIONAL_CLEAN_FILES
        ${SKYNET_JEMALLOC_CLEAN_FILES}
    )

    add_custom_target(libjemalloc_pic
        COMMAND /bin/sh -c "if [ ! -f autogen.sh ]; then git -C '${SKYNET_ROOT}' submodule update --init 3rd/jemalloc; fi"
        COMMAND /bin/sh -c "if [ ! -f Makefile ]; then CC='${CMAKE_C_COMPILER}' ./autogen.sh --with-jemalloc-prefix=je_ --enable-prof; fi"
        COMMAND ${CMAKE_COMMAND} -E rm -f configure~
        COMMAND ${SKYNET_MAKE_PROGRAM} -j${SKYNET_JEMALLOC_JOBS} CC=${CMAKE_C_COMPILER}
        WORKING_DIRECTORY "${SKYNET_ROOT}/3rd/jemalloc"
        COMMENT "Ensure jemalloc static library"
        VERBATIM
    )

    add_library(skynet_jemalloc INTERFACE)
    target_include_directories(skynet_jemalloc INTERFACE
        "${SKYNET_ROOT}/3rd/jemalloc/include/jemalloc"
    )
    target_link_directories(skynet_jemalloc INTERFACE
        "${SKYNET_ROOT}/3rd/jemalloc/lib"
    )
    target_link_libraries(skynet_jemalloc INTERFACE jemalloc_pic)
    add_dependencies(skynet_jemalloc libjemalloc_pic)

    add_custom_target(clean_jemalloc
        COMMAND /bin/sh -c "if [ -f 3rd/jemalloc/Makefile ]; then ${SKYNET_MAKE_PROGRAM} -C 3rd/jemalloc clean && rm -f 3rd/jemalloc/Makefile; fi"
        WORKING_DIRECTORY "${SKYNET_ROOT}"
        COMMENT "Clean jemalloc static library"
        VERBATIM
    )
endif()
