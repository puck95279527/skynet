# Skynet 热更新与动态加载安全审计

## 风险等级

| 等级 | 含义 |
| --- | --- |
| P0 | 可远程执行 Lua、注入代码、进入目标服务上下文，能直接改变线上逻辑。 |
| P1 | 可热更新、动态加载服务或配置，能间接改变线上行为。 |
| P2 | 本地或配置级动态加载入口，风险主要取决于部署权限、文件写权限和调用权限。 |
| P3 | 示例、测试或依赖行为，本身不是生产漏洞，但容易被误用或作为排查线索。 |

## 总表

| 序号 | 风险等级 | 点位 | 类别 | 源码位置 | 动态能力 | 触发/前置条件 | 生产风险 | 处置建议 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| 01 | P0 | `debug_console` 网络控制台 | 远程管理入口 | `service/debug_console.lua:10-140` | 通过 TCP/HTTP 接收命令并执行管理操作 | 服务被启动，端口对攻击者可达，或攻击者可从本机访问 | 控制台命令可进一步触发注入、启动服务、调用服务、杀服务 | 生产禁用；必须启用时只监听 `127.0.0.1`，加防火墙、鉴权、审计日志 |
| 02 | P0 | `debug RUN` / `skynet.inject` | 代码注入 | `service/debug_console.lua:270-287`、`lualib/skynet/debug.lua:84-90`、`lualib/skynet/inject.lua:21-65` | 读取 Lua 文件后在目标服务内执行 | 能访问 debug console，且目标服务支持 `debug` 协议 | 可修改目标服务内存状态、替换函数、读写上下文变量 | 生产关闭 debug console；禁用或加固 `debug RUN`；对注入操作强制审计 |
| 03 | P0 | `REMOTEDEBUG` 远程调试链 | 交互式远程执行 | `service/debug_console.lua:306-342`、`service/debug_agent.lua:13`、`lualib/skynet/debug.lua:96-99`、`lualib/skynet/remotedebug.lua:71-75` | 进入目标服务调试模式，交互执行表达式和语句 | 能执行 debug console 的 `debug address` | 可在目标服务协程上下文里读写局部变量、upvalue、执行任意 Lua | 生产禁用；删除启动入口；线上构建可考虑移除远程调试模块 |
| 04 | P0 | `debug_console` 管理命令 | 管理面扩大 | `service/debug_console.lua:143-181`、`184-211`、`258-267`、`408-488` | 启动服务、SNAX 服务、调用服务、改环境变量、清缓存、杀服务 | 能访问 debug console | 可绕过正常发布流程改变服务行为或破坏进程状态 | 限制命令集；生产禁用高危命令；保留只读命令也要鉴权 |
| 05 | P1 | `snax.hotfix` | 热补丁 | `lualib/skynet/snax.lua:152-154`、`service/snaxd.lua:54-59`、`lualib/snax/hotfix.lua:55-118` | 加载补丁源码并替换 SNAX 服务函数 | 调用方能拿到 SNAX 对象并发起 `hotfix` | 可无重启替换业务函数，是作弊热更的天然入口 | 线上封装白名单；禁止普通业务路径调用；记录补丁来源、内容 hash、操作者 |
| 06 | P1 | `snax_loader` / `snax.interface` | SNAX 动态接口加载 | `service/snaxd.lua:7-12`、`lualib/snax/interface.lua:3-88` | 从 `snax` 路径或自定义 loader 加载服务接口源码 | 配置了 `snax` 或 `snax_loader`，且相关文件可被替换 | 通过替换接口文件改变 SNAX 服务定义和系统方法 | 锁定 `snax` 目录写权限；线上禁用自定义 `snax_loader` 或只允许签名文件 |
| 07 | P1 | `sharedatad` 动态 `load/loadfile` | 数据热更新 | `service/sharedatad.lua:53-76`、`105-126`、`lualib/skynet/sharedata.lua:44-50` | `sharedata.new/update` 可执行字符串或 `@file` Lua chunk | 调用方能调用 sharedata 更新，或数据文件可被替换 | 以“数据更新”名义执行 Lua，可能夹带逻辑或篡改全局环境可见数据 | 只允许 table 输入；禁止线上传入字符串源码；数据文件只读和变更审计 |
| 08 | P1 | `sharetable` 动态表加载 | 共享表热加载 | `lualib/skynet/sharetable.lua:29-40`、`206-216`、`lualib-src/lua-sharetable.c:172-190` | `loadfile/loadstring` 最终走 `luaL_loadfilex_` 或 `luaL_loadstring` | 调用方能触发 `sharetable.loadfile/loadstring`，或数据源可被替换 | 共享表内容可被热替换，且加载过程会执行 Lua chunk | 线上优先使用 `loadtable`；限制 `loadfile/loadstring` 调用方；共享表文件做签名校验 |
| 09 | P1 | `cluster.reload` / `clusterd` | 集群配置热加载 | `lualib/skynet/cluster.lua:88-90`、`service/clusterd.lua:91-141` | 重新执行配置 chunk 并更新节点地址 | 调用方能执行 `cluster.reload`，或集群配置文件可被改 | 可把跨服/跨节点请求导向恶意节点或错误节点 | 集群配置只读；reload 加操作者审计；生产只允许受控发布系统触发 |
| 10 | P1 | `service_provider` / `service_cell` | 动态代码服务 | `lualib/skynet/service.lua:18-31`、`service/service_provider.lua:28-54`、`service/service_cell.lua:6-18` | `string.dump` 函数后交给新服务 `load(code)` 执行 | 调用方能使用 `skynet.service` 创建动态服务 | 可将一段 Lua 函数变成常驻服务，绕开常规文件扫描 | 审计 `service.new` 使用点；限制动态服务注册名；禁止把外部输入转成服务代码 |
| 11 | P2 | `snlua` 服务加载链 | Lua 服务加载 | `service-src/service_snlua.c:410-428`、`lualib/loader.lua:10-50` | 根据 `LUA_SERVICE` 搜索服务文件，用 `loadfile` 启动 | `luaservice`、`lualoader`、服务文件目录可被改 | 替换服务文件或搜索路径即可改变业务逻辑 | 固定服务目录；线上服务文件只读；启动前校验文件 hash |
| 12 | P2 | `preload` 启动前执行入口 | 全服务预加载 | `examples/config:3`、`service-src/service_snlua.c:419-421`、`lualib/loader.lua:42-45` | 每个 Lua 服务启动前执行指定 preload 文件 | 配置了 `preload`，且 preload 文件可被改 | 一个文件影响所有新启动 Lua 服务，适合植入统一作弊逻辑 | 生产不使用或只使用只读签名文件；审计配置变更 |
| 13 | P2 | `lua_path` / `lua_cpath` / `luaservice` 路径边界 | 搜索路径控制 | `examples/config.path:1-6`、`service-src/service_snlua.c:410-418`、`lualib/loader.lua:27-35` | 控制 Lua 模块、C 模块和服务文件搜索位置 | 配置或路径目录可被改 | 同名模块劫持、替换服务源码、加载恶意 `.so` | 路径只指向发布目录；禁止可写目录进入搜索路径；上线前打印并比对路径 |
| 14 | P2 | `console` 本地 stdin 服务启动 | 本地管理入口 | `service/console.lua:13-28`、`examples/main.lua:9-11` | 从 stdin 读命令并启动 Lua/SNAX 服务 | 启动了 `console`，且攻击者能写进进程 stdin | 可本地启动任意服务，配合路径劫持改变行为 | 生产 daemon 模式禁用；不要把 stdin 暴露给远程控制面 |
| 15 | P2 | `launcher` / `skynet.launch` | 动态服务启动 | `lualib/skynet/manager.lua:16-21`、`service/launcher.lua:93-120` | 运行时按服务名和参数启动 C/Lua 服务 | 调用方有 manager API 或 `.launcher` 调用权限 | 与路径劫持结合可启动恶意服务；可滥用资源 | 审计服务启动来源；限制管理 API 暴露面；记录异常服务名 |
| 16 | P2 | C service 动态加载 | Native 模块加载 | `skynet-src/skynet_module.c:25-63`、`77-100` | 根据 `cpath` 用 `dlopen` 加载 C service，并用 `dlsym` 找入口 | `cpath` 或 `cservice` 文件可被改 | 加载恶意 native 代码后风险高于 Lua，进程级执行 | `cservice` 目录只读；上线校验 `.so` hash；禁止从临时目录加载 |
| 17 | P2 | Lua C 模块动态加载 | Lua native 扩展加载 | `3rd/lua/loadlib.c:109-122`、`539-578` | `require` 根据 `package.cpath` 加载 `.so` | `lua_cpath` 或 `luaclib` 文件可被改 | 通过同名 Lua C 模块劫持业务 `require` | 锁定 `luaclib`；禁止可写路径进入 `lua_cpath`；记录模块加载失败和异常路径 |
| 18 | P3 | 示例和测试中的高危用法 | 误用排查 | `examples/main.lua:9-12`、`examples/injectlaunch.lua:1-19`、`test/testhandle.lua:13-15` | 示例直接启动 debug console，并演示注入修改 launcher | 生产代码复制了示例写法 | 示例习惯被带入线上，导致 debug 入口暴露 | 全项目 grep `debug_console`、`injectlaunch`；生产启动脚本禁止引用示例 main |

## 01. `debug_console` 网络控制台

- **源码位置**：`service/debug_console.lua:10-140`。
- **原理**：服务启动后调用 `socket.listen` 监听端口，`console_main_loop` 从 socket 读取命令；同时支持普通文本命令，也支持 HTTP `GET` / `POST` 映射到命令执行。
- **风险条件**：只传端口时默认监听 `127.0.0.1`，但如果调用时传入 `0.0.0.0`、内网 IP，或者线上存在端口转发、本机被拿到 shell，这个控制台就变成管理入口。
- **作弊场景**：攻击者或内部人员连接控制台后，不需要走正式发布流程，就可以进一步执行 `inject`、`debug`、`start`、`call` 等命令。
- **处置建议**：生产环境不要启动；确需启动时只允许本机访问，并加防火墙、鉴权、连接日志、命令日志；重点检查线上启动文件是否存在 `skynet.newservice("debug_console", ...)`。

## 02. `debug RUN` / `skynet.inject`

- **源码位置**：`service/debug_console.lua:270-287`、`lualib/skynet/debug.lua:84-90`、`lualib/skynet/inject.lua:21-65`。
- **原理**：控制台 `inject address file.lua` 会读取本地 Lua 文件内容，通过 `skynet.call(address, "debug", "RUN", source, filename, ...)` 发给目标服务；目标服务的 `dbgcmd.RUN` 调用 `skynet.inject`，最终执行 `load(source, filename, "bt", env)`。
- **风险条件**：攻击者能访问 debug console，且目标服务注册了默认 `debug` 协议。Skynet 的 Lua 服务默认初始化 debug protocol，因此这不是少数服务才有的能力。
- **作弊场景**：注入代码可以通过 `_U`、`_P` 接触目标服务 upvalue 和协议 dispatcher 相关表，修改业务函数、内存状态、配置缓存、转发表，或者读取敏感运行时数据。
- **处置建议**：生产禁用 debug console；如果必须保留，至少移除或拦截 `RUN`；对所有注入文件记录 hash、操作者、目标地址和执行结果；线上告警任何 `debug RUN`。

## 03. `REMOTEDEBUG` 远程调试链

- **源码位置**：`service/debug_console.lua:306-342`、`service/debug_agent.lua:13`、`lualib/skynet/debug.lua:96-99`、`lualib/skynet/remotedebug.lua:71-75`、`lualib/skynet/injectcode.lua:61-128`。
- **原理**：控制台 `debug address` 会启动 `debug_agent`，然后向目标服务发 `debug REMOTEDEBUG`。`remotedebug` 会 hook dispatcher，并把输入命令交给 `injectcode`，`injectcode` 构造源码后 `load(full_source, "=(debug)")`，还能绑定局部变量和 upvalue。
- **风险条件**：能执行 debug console 的 `debug` 命令即可触发。该能力不是只读调试，而是交互式执行。
- **作弊场景**：可以在服务正在处理消息时断入，读取或修改局部变量、upvalue、当前协程上下文，对线上行为做临时、不落盘的修改。
- **处置建议**：生产禁用远程调试；线上构建可以直接移除 `debug_agent` / `remotedebug` 入口；如保留，必须要求强鉴权和完整审计。

## 04. `debug_console` 管理命令

- **源码位置**：`service/debug_console.lua:143-181`、`184-211`、`258-267`、`408-488`。
- **原理**：控制台内置命令不止查询状态，还包括 `start`、`snax`、`clearcache`、`kill`、`exit`、`call`、`setenv`。其中 `call` 会 `load("return " .. cmdline, "debug console", "t", {})` 解析参数，然后直接调用目标服务 Lua 协议。
- **风险条件**：能访问 debug console。
- **作弊场景**：`start/snax` 可启动额外服务，`call` 可直接打业务服务内部接口，`setenv` 可影响后续服务读取配置，`clearcache` 可让后续 `require/loadfile` 重新取文件。
- **处置建议**：生产禁用整个控制台；如果只想保留观测能力，应拆出只读命令白名单，禁止 `inject/debug/call/start/snax/setenv/clearcache/kill/exit`。

## 05. `snax.hotfix`

- **源码位置**：`lualib/skynet/snax.lua:152-154`、`service/snaxd.lua:54-59`、`lualib/snax/hotfix.lua:55-118`。
- **原理**：`snax.hotfix(obj, source, ...)` 会向 SNAX 服务发送 `system.hotfix`，`snax.hotfix` 模块把补丁源码 `load(source, "=patch", "bt", G)` 成 patch，再用 upvalue 绑定替换已有函数。
- **风险条件**：调用方能拿到目标 SNAX 对象并发起 `hotfix`；或者业务系统对外暴露了热修接口。
- **作弊场景**：把关键业务函数替换成偏向某些账号、道具、概率或结算逻辑的版本，不需要重启服务，也不一定留下文件变更。
- **处置建议**：生产热修必须走统一发布系统；补丁内容做 hash、签名和留档；业务代码不要直接暴露 `snax.hotfix` 给外部请求链路。

## 06. `snax_loader` / `snax.interface`

- **源码位置**：`service/snaxd.lua:7-12`、`lualib/snax/interface.lua:3-88`。
- **原理**：`snaxd` 启动时读取 `skynet.getenv "snax_loader"`，如果存在则 `dofile(loaderpath)`；否则 `snax.interface` 根据配置 `snax` 路径，用 `loadfile(filename, "bt", G)` 加载 SNAX 接口文件。
- **风险条件**：`snax_loader` 配置可被改，或者 `snax` 搜索目录内文件可被替换。
- **作弊场景**：替换 SNAX 接口文件中的 `accept/response/system.hotfix`，即可改变服务方法表和热修行为。
- **处置建议**：线上不使用任意 `snax_loader`；SNAX 源码目录只读；发布前比对 `snax` 路径和文件 hash。

## 07. `sharedatad` 动态 `load/loadfile`

- **源码位置**：`service/sharedatad.lua:53-76`、`105-126`、`lualib/skynet/sharedata.lua:44-50`。
- **原理**：`sharedata.new/update(name, v, ...)` 如果 `v` 是 table，就直接作为共享数据；如果 `v` 是字符串，`@file` 走 `loadfile`，普通字符串走 `load`，再执行 chunk 得到 table。
- **风险条件**：调用方能调用 `sharedata.new/update`，或者被加载的数据文件可被替换。
- **作弊场景**：伪装成配置/数据热更新，实际执行 Lua chunk，改变全服共享配置、活动参数、概率表、白名单等。
- **处置建议**：生产只允许 table 数据或受控文件；禁止把外部输入直接传给 `sharedata.new/update`；共享数据更新必须记录来源、diff 和操作者。

## 08. `sharetable` 动态表加载

- **源码位置**：`lualib/skynet/sharetable.lua:29-40`、`206-216`、`lualib-src/lua-sharetable.c:172-190`。
- **原理**：`sharetable.loadfile/loadstring` 通过服务转发到 C 扩展，C 层 `load_matrixfile` 会根据 source 是否以 `@` 开头，选择 `luaL_loadfilex_` 或 `luaL_loadstring`，然后执行并构造共享表。
- **风险条件**：调用方能触发 `sharetable.loadfile/loadstring`，或者共享表文件/字符串来源不可信。
- **作弊场景**：动态替换共享表内容，例如排行榜配置、掉落表、匹配参数；如果加载 chunk 中夹带逻辑，也会在加载阶段执行。
- **处置建议**：线上优先使用 `sharetable.loadtable`；限制 `loadfile/loadstring` 的调用方；共享表来源目录只读并做签名校验。

## 09. `cluster.reload` / `clusterd`

- **源码位置**：`lualib/skynet/cluster.lua:88-90`、`service/clusterd.lua:91-141`。
- **原理**：`cluster.reload(config)` 会调用 `clusterd` 的 `reload`。如果传入配置表，直接更新；如果使用配置文件，`clusterd` 读取文件后 `load(source, "@"..config_name, "t", tmp)()` 执行。
- **风险条件**：调用方能触发 `cluster.reload`，或者集群配置文件可被替换。
- **作弊场景**：把跨服节点、远程服务地址导向异常节点，实现流量劫持、跨服数据偏移或灰度外的逻辑替换。
- **处置建议**：集群配置只读；reload 只能由发布系统触发；记录 reload 前后节点 diff。

## 10. `service_provider` / `service_cell`

- **源码位置**：`lualib/skynet/service.lua:18-31`、`service/service_provider.lua:28-54`、`service/service_cell.lua:6-18`。
- **原理**：`skynet.service.new(name, mainfunc, ...)` 会检查函数 upvalue 后 `string.dump(mainfunc)`，再通过 `service_provider` 启动 `service_cell`，`service_cell` 对传入 code 执行 `load(code, service_name)`。
- **风险条件**：业务调用方能使用 `skynet.service` 动态创建服务，且服务函数来源不受控。
- **作弊场景**：不落地 Lua 文件，直接把函数 dump 成字节码服务启动，规避只检查文件变更的审计方式。
- **处置建议**：grep 并审计 `service.new` 使用点；服务名走白名单；禁止把外部输入、GM 指令或运营配置转换成动态服务代码。

## 11. `snlua` 服务加载链

- **源码位置**：`service-src/service_snlua.c:410-428`、`lualib/loader.lua:10-50`。
- **原理**：C 层 `snlua` 把 `lua_path`、`lua_cpath`、`luaservice`、`preload` 写入 Lua 全局变量，然后 `luaL_loadfile` 加载 `lualoader`。默认 `loader.lua` 根据 `LUA_SERVICE` 搜索服务文件并 `loadfile` 执行。
- **风险条件**：`lualoader`、`luaservice` 或服务源码目录可被修改。
- **作弊场景**：替换服务文件，或者把搜索路径前置到攻击者可写目录，让同名服务优先加载恶意版本。
- **处置建议**：固定线上服务路径；发布后源码目录只读；进程启动时打印并审计实际 `LUA_SERVICE`、`LUA_PATH`、`LUA_CPATH`。

## 12. `preload` 启动前执行入口

- **源码位置**：`examples/config:3`、`service-src/service_snlua.c:419-421`、`lualib/loader.lua:42-45`。
- **原理**：如果配置了 `preload`，`snlua` 会把它放进 `LUA_PRELOAD`，`loader.lua` 在主服务执行前 `loadfile(LUA_PRELOAD)` 并调用。
- **风险条件**：生产启用了 `preload`，且 preload 文件可被替换。
- **作弊场景**：在所有后续 Lua 服务启动前植入统一 hook，例如改 `require`、改全局库、注册监控或篡改公共函数。
- **处置建议**：生产默认不启用；确需使用时必须签名、只读、纳入发布审计。

## 13. `lua_path` / `lua_cpath` / `luaservice` 路径边界

- **源码位置**：`examples/config.path:1-6`、`service-src/service_snlua.c:410-418`、`lualib/loader.lua:27-35`。
- **原理**：`lua_path` 决定 Lua `require` 搜索，`lua_cpath` 决定 Lua C 模块搜索，`luaservice` 决定服务脚本搜索。默认示例路径包含 `service/`、`test/`、`examples/`。
- **风险条件**：路径中出现可写目录、临时目录、用户上传目录，或者生产沿用示例路径把 `examples/test` 带上线。
- **作弊场景**：通过同名 Lua 文件或 `.so` 劫持 `require`，或者让服务加载到非发布产物。
- **处置建议**：生产配置只包含正式发布目录；禁止 `examples/`、`test/` 进入线上路径；上线前输出路径并做基线比对。

## 14. `console` 本地 stdin 服务启动

- **源码位置**：`service/console.lua:13-28`、`examples/main.lua:9-11`。
- **原理**：`console` 从 `socket.stdin()` 读取命令，输入 `snax xxx` 会启动 SNAX 服务，其他非空输入会 `skynet.newservice(cmdline)`。
- **风险条件**：生产启动了 `console`，且进程 stdin 被终端、多路复用器、容器 exec、运维面板或其他通道控制。
- **作弊场景**：本地启动额外服务，配合路径劫持或已有服务参数实现逻辑替换。
- **处置建议**：daemon/生产模式禁用；不要把 stdin 接到可远程操作的控制台；排查 `skynet.newservice("console")`。

## 15. `launcher` / `skynet.launch`

- **源码位置**：`lualib/skynet/manager.lua:16-21`、`service/launcher.lua:93-120`。
- **原理**：`skynet.launch` 通过 core 命令启动指定服务；`launcher` 维护服务列表，并提供 `LAUNCH/LOGLAUNCH` 等命令给 `newservice` 路径使用。
- **风险条件**：不可信代码能调用 manager API、能调用 `.launcher`，或者能影响被启动的服务名和参数。
- **作弊场景**：运行时启动异常服务、重复启动资源消耗服务、启动被路径劫持后的同名服务。
- **处置建议**：只在受信业务模块中使用 manager API；记录异常服务名和启动参数；结合路径白名单控制可启动服务集合。

## 16. C service 动态加载

- **源码位置**：`skynet-src/skynet_module.c:25-63`、`77-100`。
- **原理**：Skynet C service 根据 `cpath` 模板拼出 `.so` 路径，使用 `dlopen(tmp, RTLD_NOW | RTLD_GLOBAL)` 加载，再用 `dlsym` 查找 `xxx_create/init/release/signal`。
- **风险条件**：`cpath` 配置可被改，或者 `cservice` 目录可被写入/替换。
- **作弊场景**：加载恶意 native 模块后可获得进程级执行能力，影响范围比 Lua 更大。
- **处置建议**：`cservice` 目录只读；`.so` 产物做 hash 和签名；禁止从 `/tmp`、上传目录、用户 home 等可写路径加载。

## 17. Lua C 模块动态加载

- **源码位置**：`3rd/lua/loadlib.c:109-122`、`539-578`。
- **原理**：Lua `require` 搜索 Lua 文件时走 `luaL_loadfile`，搜索 C 模块时按 `package.cpath` 找 `.so`，再 `dlopen` 并 `dlsym luaopen_xxx`。
- **风险条件**：`lua_cpath` 配置可被改，或者 `luaclib` 目录可被替换。
- **作弊场景**：用同名 `.so` 劫持业务模块，例如替换协议、加密、数据库、网络或工具库。
- **处置建议**：`luaclib` 只读；禁止可写路径进入 `lua_cpath`；记录启动时实际 `package.cpath`；对 native 模块做完整性校验。

## 18. 示例和测试中的高危用法

- **源码位置**：`examples/main.lua:9-12`、`examples/injectlaunch.lua:1-19`、`test/testhandle.lua:13-15`。
- **原理**：示例 `main.lua` 会启动 `debug_console`；`injectlaunch.lua` 明确演示通过控制台注入 launcher 服务，把 `command.LAUNCH` 替换成 `command.LOGLAUNCH`；测试文件也会启动 debug console。
- **风险条件**：生产代码复制示例启动方式，或线上路径包含 `examples/`、`test/`。
- **作弊场景**：开发期便利入口被带到线上，攻击者可直接按示例步骤注入并修改服务启动行为。
- **处置建议**：全项目 grep `debug_console`、`injectlaunch`、`examples/main.lua`；生产配置不要引用 `examples/`、`test/`；发布检查中加入“禁止 debug_console”规则。

## 重点排查清单

| 检查项 | 建议命令 / 方法 | 目标 |
| --- | --- | --- |
| 查 debug console 是否上线 | `rg -n "debug_console" .` | 找到所有启动控制台的位置。 |
| 查热补丁入口 | `rg -n -e "hotfix" -e "snax.hotfix" service lualib examples test` | 确认是否有业务接口可触发热修。 |
| 查动态执行 | `rg -n -e "load\\(" -e "loadfile\\(" -e "luaL_loadfile" -e "luaL_loadstring" service lualib service-src skynet-src lualib-src` | 找出所有 Lua chunk 执行入口。 |
| 查 native 加载 | `rg -n -e "dlopen" -e "dlsym" -e "lua_cpath" -e "cpath" skynet-src service-src lualib 3rd/lua` | 确认 C 模块搜索路径和加载位置。 |
| 查生产路径 | 打印或审计 `lua_path`、`lua_cpath`、`luaservice`、`cpath` | 确认没有可写目录、`examples/`、`test/`。 |
| 查文件完整性 | 对 `service/`、`lualib/`、`luaclib/`、`cservice/` 做 hash 基线 | 发现绕过发布系统的文件替换。 |
