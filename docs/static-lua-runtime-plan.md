# Static Lua Runtime 计划

## 目标

把 Skynet main 服改造成“启动期加载、运行期静态”的 Lua 运行模型。

核心要求：

```text
lua_compiler:
  .lua
    -> 编译成 Lua binary chunk
    -> 计算 hash
    -> 用私钥签名
    -> 输出私有 SKYBC1 字节码包

lua_runtime:
  物理上没有 parser/codegen 能力
  不能解析 Lua 源码
  不能加载官方 luac 产物
  只能验签加载 lua_compiler 产出的 SKYBC1
  启动完成后 seal，拒绝任何新的 Lua chunk / native 模块 / service
```

最终效果：

```text
protobuf string 即使包含 Lua 源码，也不能被 main 编译。
protobuf string 即使包含官方 luac 字节码，也不能被 main 加载。
只有离线 lua_compiler 产出的、签名正确的 SKYBC1，才能在启动期被 lua_runtime 加载。
启动完成 seal 后，连合法 SKYBC1 也不能再被动态加载。
```

## 当前 Lua 加载链

当前仓库的 Lua 加载入口大致是：

```text
lua_load()
  -> luaD_protectedparser()
    -> 读取第一个字节
       如果是 LUA_SIGNATURE，也就是 "\x1bLua"
         -> luaU_undump()      -- 加载 Lua binary chunk
       否则
         -> luaY_parser()      -- 解析 Lua 源码并编译
```

相关源码点：

| 能力 | 位置 | 说明 |
| --- | --- | --- |
| `lua_load` 总入口 | `3rd/lua/lapi.c` | 所有 `load/loadfile/loadstring` 最终会进入这里。 |
| text/binary 分支 | `3rd/lua/ldo.c` | 目前 binary 走 `luaU_undump`，text 走 `luaY_parser`。 |
| 源码 parser | `3rd/lua/lparser.c` | 把 Lua 源码解析成 AST/函数原型。 |
| lexer | `3rd/lua/llex.c` | 词法分析。 |
| codegen | `3rd/lua/lcode.c` | 生成 Lua VM 字节码。 |
| binary chunk 加载 | `3rd/lua/lundump.c` | 加载预编译 Lua bytecode。 |
| `loadfile` | `3rd/lua/lauxlib.c` | 读文件后调用 `lua_load`。 |

因此，要让 runtime 没有 parser 能力，不能只在 Lua 层删 `load`，必须让 `lua_runtime` 不链接 parser/codegen，并让 text 分支无法调用 `luaY_parser`。

## 两套产物

### `lua_compiler`

用途：离线编译工具，只在 CI/编译机运行。

保留能力：

```text
lparser.c
llex.c
lcode.c
ldump.c
luac.c
```

职责：

1. 读取 `.lua` 源码。
2. 使用完整 Lua compiler 编译成原始 Lua binary chunk。
3. 计算 `source_sha256`。
4. 计算 `bytecode_sha256`。
5. 写入 `SKYBC1` 私有容器。
6. 用 Ed25519 私钥签名。
7. 输出 `.skybc` 文件。

私钥只允许存在于 CI/编译机，不进入游戏服机器。

### `lua_runtime`

用途：Skynet main 服链接的 Lua 运行时。

保留能力：

```text
Lua VM
GC
table/string/coroutine
标准库中允许保留的运行期部分
luaU_undump
签名 SKYBC1 校验逻辑
```

必须移除：

```text
lparser.o
llex.o
lcode.o
luaY_parser
luaX_init
luaK_*
```

关键要求：

```text
runtime 物理上没有源码 parser/codegen。
runtime 不是“有 parser 但开关禁用”，而是链接产物里就不应该出现 parser/codegen 符号。
```

需要处理的源码点：

| 位置 | 要求 |
| --- | --- |
| `3rd/lua/ldo.c` | text chunk 分支直接报错，不再引用 `luaY_parser`。 |
| `3rd/lua/lstate.c` | runtime 构建下移除 `luaX_init(L)`。 |
| `3rd/lua/makefile` | 增加 runtime object 列表，排除 `lparser.o/llex.o/lcode.o`。 |
| `3rd/lua/lundump.c` | 保留 raw bytecode 加载能力，但入口只能被 SKYBC1 校验层调用。 |

## SKYBC1 私有格式

默认文件扩展名：

```text
.skybc
```

建议容器结构：

| 字段 | 说明 |
| --- | --- |
| `magic` | 固定为 `SKYBC1`。 |
| `format_version` | SKYBC 容器版本。 |
| `lua_version` | 当前仓库 Lua 版本，例如 Lua 5.5.0。 |
| `lua_abi_id` | Lua 指令、整数、浮点、大小端、补丁版本等 ABI 标识。 |
| `skynet_build_id` | 当前 Skynet runtime 构建 ID。 |
| `flags` | strip debug info、固定平台等标志位。 |
| `source_sha256` | 原始 `.lua` 源码 hash。 |
| `bytecode_sha256` | 内部 raw Lua binary chunk hash。 |
| `bytecode_len` | 内部 raw Lua binary chunk 长度。 |
| `signature` | Ed25519 签名。 |
| `raw_lua_binary_chunk` | 原始 Lua binary chunk，仍以 Lua 内部格式保存。 |

签名内容建议覆盖：

```text
header_without_signature + raw_lua_binary_chunk
```

runtime 内置公钥，加载时必须验签。

## Runtime 加载规则

加载流程：

```text
1. 读取文件内容
2. 检查 magic == SKYBC1
3. 检查 format_version
4. 检查 lua_version
5. 检查 lua_abi_id
6. 检查 skynet_build_id
7. 计算 bytecode_sha256
8. 用内置公钥验签
9. 验签通过后，把 raw_lua_binary_chunk 交给 luaU_undump
10. 生成 Lua closure
```

必须拒绝：

```text
.lua 源码
load("print(1)") 这类字符串源码
官方 luac 产出的裸 "\x1bLua" chunk
被篡改的 SKYBC1
签名不匹配的 SKYBC1
lua_version / lua_abi_id / skynet_build_id 不匹配的 SKYBC1
```

注意：不能只修改 `loadfile`。`load`、`loadstring`、`require`、`sharedata.update`、`snax.hotfix`、`debug inject` 等最终也可能进入 `lua_load`，因此 runtime 边界必须在 C 层。

## Seal 机制

runtime 分两个阶段：

```text
启动期:
  允许加载签名 SKYBC1。
  加载固定 service / lualib / luaclib / cservice。
  生成 manifest。

运行期:
  调用 skynet.static_seal()。
  seal 后拒绝任何新的 Lua chunk。
  seal 后拒绝任何新的 native 模块。
  seal 后拒绝任何新的 Skynet service。
```

seal 后必须失败：

```text
load(...)
loadfile(...)
dofile(...)
require(未加载模块)
snax.hotfix(...)
debug RUN
REMOTEDEBUG
sharedata.update(name, lua_source_string)
sharetable.loadstring(...)
sharetable.loadfile(...)
cluster.reload(file)
skynet.newservice(...)
skynet.launch(...)
package.loadlib(...)
新 cservice dlopen
新 luaclib dlopen
```

seal 不是替代签名，而是第二道边界：

```text
签名保证“启动期只加载可信字节码”。
seal 保证“运行期不能再加载新逻辑”。
```

## Skynet 配置调整

生产配置需要从 `.lua` 路径切到 `.skybc` 路径。

示例：

```lua
lualoader = root .. "lualib/loader.skybc"
luaservice = root .. "service/?.skybc"
lua_path = root .. "lualib/?.skybc;" .. root .. "lualib/?/init.skybc"
lua_cpath = root .. "luaclib/?.so"
cpath = root .. "cservice/?.so"
```

生产包要求：

```text
不部署 .lua 源码
不包含 examples/
不包含 test/
不启动 debug_console
不暴露热更接口
```

## 兼容性影响

这个方案会主动破坏 Skynet 的动态能力。

已知受影响点：

| 能力 | 当前实现 | runtime 下处理 |
| --- | --- | --- |
| `skynet.service.new` | `string.dump(mainfunc)` + `service_cell load(code)` | 生产禁用；改成固定 service 文件并预编译。 |
| `snax.hotfix` | `load(source, "=patch", "bt", G)` | 生产禁用。 |
| `debug RUN` | `skynet.inject` 中 `load(source, ...)` | 生产禁用。 |
| `REMOTEDEBUG` | `injectcode` 构造源码后 `load` | 生产禁用。 |
| `sharedata.update` 字符串 | 字符串进入 `load/loadfile` | 生产只允许 table 或签名数据格式。 |
| `sharetable.loadstring/loadfile` | C 层执行 `luaL_loadstring/luaL_loadfilex_` | 生产禁用，优先 `loadtable`。 |
| `cluster.reload(file)` | 读取配置后 `load(source, ...)` | 生产只允许 table 配置或重启加载。 |
| 懒加载 `require` | seal 后可能需要加载新模块 | 启动期预加载完整模块集。 |

需要改造的 repo 内使用点：

```text
lualib/skynet/sharetable.lua
lualib/skynet/datasheet/builder.lua
service/bootstrap.lua 的 ltls_holder
test/testservice/kvdb.lua
examples/simplewebsocket.lua
test/testtimeout.lua
```

生产路径里不应依赖这些动态 `service.new` 用法；如确实需要，需要拆成普通 service 文件并编译成 `SKYBC1`。

## Manifest 计划

启动完成、seal 之前生成 manifest。

建议包含：

| 字段 | 说明 |
| --- | --- |
| `skynet_build_id` | 当前 runtime 构建标识。 |
| `lua_version` | Lua 版本。 |
| `lua_abi_id` | ABI 标识。 |
| `seal_time` | seal 时间。 |
| `service_list` | 启动服务列表。 |
| `module_list` | 已加载 Lua 模块列表。 |
| `skybc_hashes` | 每个 SKYBC 包的 hash 和签名信息。 |
| `cservice_hashes` | 每个 C service `.so` hash。 |
| `luaclib_hashes` | 每个 Lua C 模块 `.so` hash。 |
| `config_hash` | 启动配置 hash。 |

manifest 可以：

```text
写入只读审计文件
主动上报到独立 integrity 服务
提供只读 RPC 查询
```

注意：如果攻击者已经有进程内任意代码执行能力，直接远程问 main 要 hash 可能被伪造。因此更推荐 seal 前主动上报到独立进程。

## 分阶段落地

### 第一阶段：文档与风险冻结

目标：

```text
明确 static runtime 目标。
冻结不需要热更的生产策略。
列出所有动态能力兼容影响。
```

产物：

```text
docs/static-lua-runtime-plan.md
```

### 第二阶段：签名字节码容器

目标：

```text
实现 SKYBC1 格式。
实现 lua_compiler 输出 SKYBC1。
实现 runtime 验签加载 SKYBC1。
```

验收：

```text
合法 SKYBC1 可加载。
官方 luac 产物失败。
篡改 bytecode 失败。
篡改 header 失败。
签名错误失败。
```

### 第三阶段：无 Parser Runtime

目标：

```text
lua_runtime 不链接 lparser.o/llex.o/lcode.o。
runtime 符号表不存在 luaY_parser/luaX_init/luaK_*。
text chunk 在 C 层无法编译。
```

验收：

```text
nm skynet | rg "luaY_parser|luaX_init|luaK_" 无结果。
load("print(1)") 失败。
loadfile("plain.lua") 失败。
官方 luac chunk 失败。
SKYBC1 seal 前成功。
```

### 第四阶段：Skynet 配置迁移

目标：

```text
loader/service/lualib 全部改成 .skybc。
生产包不带 .lua。
启动期加载固定模块集。
```

验收：

```text
main 使用 .skybc 启动成功。
生产配置不包含 examples/test/.lua。
固定服务正常运行。
```

### 第五阶段：seal 与动态能力禁用

目标：

```text
实现 skynet.static_seal()。
seal 后禁止新 Lua chunk / new .so / new service。
禁用 debug_console 和热更入口。
```

验收：

```text
seal 后 require 未加载模块失败。
seal 后合法 SKYBC1 也无法加载。
seal 后 skynet.newservice 失败。
seal 后 package.loadlib 失败。
seal 后 debug RUN / snax.hotfix 失败。
```

## 测试清单

| 测试项 | 预期 |
| --- | --- |
| `.lua -> SKYBC1` | 编译成功。 |
| `SKYBC1` 验签加载 | seal 前成功。 |
| 普通 `.lua` | runtime 加载失败。 |
| 官方 `luac` 裸 chunk | runtime 加载失败。 |
| 篡改 header | runtime 加载失败。 |
| 篡改 bytecode | runtime 加载失败。 |
| 错误签名 | runtime 加载失败。 |
| ABI 不匹配 | runtime 加载失败。 |
| seal 后加载合法 SKYBC1 | 失败。 |
| seal 后 `load("...")` | 失败。 |
| seal 后 `skynet.newservice` | 失败。 |
| seal 后 `package.loadlib` | 失败。 |
| runtime 符号检查 | 不存在 parser/codegen 符号。 |

## 安全边界

能防：

```text
protobuf string 携带 Lua 源码
protobuf string 携带官方 luac 字节码
运行期 load/loadfile/dofile 编译源码
未签名字节码加载
签名不匹配字节码加载
seal 后新增 Lua 逻辑
seal 后新增 native 模块
seal 后新增 Skynet service
```

不能单独防：

```text
私钥泄露后生成合法恶意 SKYBC1
服务器已被拿到 native 执行权限后的内存 patch
已经加载进内存的 table/upvalue 被可信代码自己改坏
业务逻辑授权或数值校验漏洞
操作系统层面的文件替换和进程注入
```

对应要求：

```text
私钥不进游戏服
生产目录只读
main 服最小权限运行
5000 debug 生产关闭
8888 后台强鉴权和审计
manifest 上报独立 integrity 服务
```

## 默认假设

```text
生产服不需要 Lua 热更新。
生产服启动后不需要动态创建新 Skynet service。
编译器和 runtime 来自同一个 Lua 5.5.0 + Skynet 代码基线。
runtime 只内置公钥。
私钥只存在于 CI/编译机。
第一版优先建立安全边界，不优先追求工具链体验。
```
