# Makefile 二进制产物表

本文按根目录 `Makefile` 的生产顺序列出二进制产物。

## 构建入口

| 平台 | 命令 |
| --- | --- |
| macOS | `make macosx` |
| Linux | `make linux` |
| FreeBSD | `gmake freebsd` |
| OpenBSD | `make openbsd` |
| MinGW | `make mingw` |

## 二进制产物总表

| 序号 | 类别 | 二进制 | 类型 | 作用 | 源文件 / 输入 |
| --- | --- | --- | --- | --- | --- |
| 1 | 第三方依赖 | `3rd/jemalloc/lib/libjemalloc_pic.a` | 静态库 | jemalloc 内存分配库；Linux/FreeBSD 默认链接，macOS/OpenBSD 不链接。 | `3rd/jemalloc` 子模块 |
| 2 | Lua 子工程 | `3rd/lua/liblua.a` | 静态库 | Skynet 主程序链接的 Lua 运行时静态库。 | `3rd/lua/makefile` 构建 Lua core/lib 源码 |
| 3 | Lua 子工程 | `3rd/lua/lua` | 可执行文件 | Lua 命令行解释器，可用于运行示例客户端或普通 Lua 脚本。 | `3rd/lua/lua.c`<br>`3rd/lua/liblua.a` |
| 4 | Lua 子工程 | `3rd/lua/luac` | 可执行文件 | Lua 字节码编译器。 | `3rd/lua/luac.c`<br>`3rd/lua/liblua.a` |
| 5 | 主程序 | `skynet` | 可执行文件 | Skynet 主进程，负责启动节点、加载配置、调度服务、管理消息队列、定时器、socket、模块加载和日志。 | `skynet-src/skynet_main.c`<br>`skynet-src/skynet_handle.c`<br>`skynet-src/skynet_module.c`<br>`skynet-src/skynet_mq.c`<br>`skynet-src/skynet_server.c`<br>`skynet-src/skynet_start.c`<br>`skynet-src/skynet_timer.c`<br>`skynet-src/skynet_error.c`<br>`skynet-src/skynet_harbor.c`<br>`skynet-src/skynet_env.c`<br>`skynet-src/skynet_monitor.c`<br>`skynet-src/skynet_socket.c`<br>`skynet-src/socket_server.c`<br>`skynet-src/mem_info.c`<br>`skynet-src/malloc_hook.c`<br>`skynet-src/skynet_daemon.c`<br>`skynet-src/skynet_log.c`<br>`3rd/lua/liblua.a`<br>`3rd/jemalloc/lib/libjemalloc_pic.a`，macOS/OpenBSD 不链接 |
| 6 | C 服务模块 | `cservice/snlua.so` | C service | Lua 服务容器，创建 Lua VM，加载 `service/*.lua`、`examples/*.lua` 等 Lua 服务脚本。 | `service-src/service_snlua.c` |
| 7 | C 服务模块 | `cservice/logger.so` | C service | 日志服务，接收 Skynet 日志消息并写到标准输出或日志文件。 | `service-src/service_logger.c` |
| 8 | C 服务模块 | `cservice/gate.so` | C service | 网关服务，管理外部 socket 连接，负责连接接入、断开和数据转发。 | `service-src/service_gate.c` |
| 9 | C 服务模块 | `cservice/harbor.so` | C service | 集群节点通信服务，用于 harbor 模式下节点之间的消息转发。 | `service-src/service_harbor.c` |
| 10 | Lua C 模块 | `luaclib/skynet.so` | Lua C 模块 | Skynet Lua 层核心绑定，提供消息收发、socket、序列化、内存统计、cluster、crypt、sharedata、stm、datasheet 等底层能力。 | `lualib-src/lua-skynet.c`<br>`lualib-src/lua-seri.c`<br>`lualib-src/lua-socket.c`<br>`lualib-src/lua-mongo.c`<br>`lualib-src/lua-netpack.c`<br>`lualib-src/lua-memory.c`<br>`lualib-src/lua-multicast.c`<br>`lualib-src/lua-cluster.c`<br>`lualib-src/lua-crypt.c`<br>`lualib-src/lsha1.c`<br>`lualib-src/lua-sharedata.c`<br>`lualib-src/lua-stm.c`<br>`lualib-src/lua-debugchannel.c`<br>`lualib-src/lua-datasheet.c`<br>`lualib-src/lua-sharetable.c` |
| 11 | Lua C 模块 | `luaclib/client.so` | Lua C 模块 | 客户端 socket 辅助模块，供 Lua 客户端脚本连接 Skynet 服务并处理简单加密相关逻辑。 | `lualib-src/lua-clientsocket.c`<br>`lualib-src/lua-crypt.c`<br>`lualib-src/lsha1.c` |
| 12 | Lua C 模块 | `luaclib/bson.so` | Lua C 模块 | BSON 编解码支持，主要供 MongoDB 相关 Lua 库使用。 | `lualib-src/lua-bson.c` |
| 13 | Lua C 模块 | `luaclib/md5.so` | Lua C 模块 | MD5 哈希模块。 | `3rd/lua-md5/md5.c`<br>`3rd/lua-md5/md5lib.c`<br>`3rd/lua-md5/compat-5.2.c` |
| 14 | Lua C 模块 | `luaclib/sproto.so` | Lua C 模块 | Sproto 协议序列化和反序列化模块。 | `lualib-src/sproto/sproto.c`<br>`lualib-src/sproto/lsproto.c` |
| 15 | Lua C 模块 | `luaclib/lpeg.so` | Lua C 模块 | LPeg 模式匹配库，供 Lua 层做语法/模式解析。 | `3rd/lpeg/lpcap.c`<br>`3rd/lpeg/lpcode.c`<br>`3rd/lpeg/lpprint.c`<br>`3rd/lpeg/lptree.c`<br>`3rd/lpeg/lpvm.c`<br>`3rd/lpeg/lpcset.c` |
| 16 | Lua C 模块，可选 | `luaclib/ltls.so` | Lua C 模块 | TLS/HTTPS 支持模块；默认不构建，需要打开 `TLS_MODULE=ltls`。 | `lualib-src/ltls.c` |

## 平台差异

| 平台 | jemalloc | 动态库参数 | 额外链接 |
| --- | --- | --- | --- |
| macOS | 不链接，定义 `NOUSE_JEMALLOC` | `-fPIC -dynamiclib -Wl,-undefined,dynamic_lookup` | `-lpthread -lm -ldl` |
| Linux | 链接 `3rd/jemalloc/lib/libjemalloc_pic.a` | `-fPIC --shared` | `-lpthread -lm -ldl -lrt` |
| FreeBSD | 链接 `3rd/jemalloc/lib/libjemalloc_pic.a` | `-fPIC --shared` | `-lpthread -lm -lrt` |
| OpenBSD | 不链接，定义 `NOUSE_JEMALLOC` | `-fPIC --shared` | `-lpthread -lm` |
| MinGW | 走 `mingw.mk` | 走 `mingw.mk` | 走 `mingw.mk` |

## 清理目标

| 命令 | 删除内容 |
| --- | --- |
| `make clean` | `skynet`<br>`cservice/*.so`<br>`luaclib/*.so`<br>`*.dSYM`<br>`cservice/*.dSYM`<br>`luaclib/*.dSYM` |
| `make cleanall` | 包含 `make clean` 内容，另清理 `3rd/lua` 构建产物和 `3rd/jemalloc/Makefile` |
