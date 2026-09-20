# MoonPMTiles Agent Guide

本仓库正在开发一个面向 MoonBit、对象存储和 Wasm 应用的 PMTiles v3
跨后端读取与归档工具链。公共仓库为：

```text
https://github.com/Orion-XX/MoonPMTiles
```

目标是交付可信、可复现、跨 target 的 reader、writer、validator 和 CLI，
而不是仅完成一次演示。开始工作前，先检查 `git status --short --branch`、
当前任务卡及其依赖。如果本地存在 `docs/`、`development/`、`research/`、
`submission/`，应先读取其中与任务相关的契约，但这些目录是内部资料，除非
负责人明确改变决定，不得暂存、提交或上传。

## 项目范围

MVP 只包含：

- PMTiles v3 Header、Directory、Metadata、varint 和 Hilbert TileID 编解码；
- Memory、Native file 和一个经过实测的 HTTP Range 数据源；
- 有界解析、结构化错误、精确范围读取和有界缓存；
- `none` 与 `gzip` 压缩路径，其他 codec 必须先完成可用性验证；
- 确定性 writer、archive validator；
- `inspect`、`get-tile`、`verify` CLI；
- native、wasm、wasm-gc、JavaScript 上适用的核心检查和测试。

不得自行扩展到地图渲染、投影、GeoJSON/MVT 切片、完整 S3 SDK、数据库、
在线服务、鉴权上传、持久化缓存或自研压缩算法。不得把候选扩展点描述成
已经交付的功能。

## 规范与既有能力边界

- PMTiles v3 规范是格式行为的主要依据：
  `https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md`。
- 不要逐行移植上游实现；使用公开规范和已记录的测试向量独立实现。
- 开发前先搜索 `moonbitlang/core`、当前标准库和已安装工具链。不得重复实现
  core 已提供的 `Bytes`、整数转换、容器、JSON、文件或测试能力。
- 性质测试优先使用 `moonbitlang/core/quickcheck`，不得另造通用随机数、
  generator 或 shrink 框架。
- 不要自研 gzip、Brotli 或 Zstd。压缩能力通过 provider 隔离；不可用时返回
  明确的 `UnsupportedCompression`。
- 引入依赖、fixture 或参考代码前，必须记录固定版本或 commit、来源、许可证、
  SHA-256、采用范围和更新方式。
- 普通构建和测试不得下载依赖数据或访问公网。允许的 HTTP 集成测试只访问
  明确启动的 loopback fixture server。

## 架构边界

纯 MoonBit 核心不得依赖网络、文件系统或特定 host。平台能力通过 adapter 注入。
预期模块边界如下；只为当前任务创建必要路径：

```text
src/model             格式枚举、Header、DirectoryEntry、TileCoord、错误
src/codec             小端字段、varint、Header/Directory 编解码
src/tileid            z/x/y 与 Hilbert TileID
src/directory         目录校验、编码和查找
src/archive           读取状态机、范围计划、metadata/tile 查询
src/compression       codec 标识和 provider 契约
src/writer            确定性归档布局与编码
adapters/memory       跨 target 内存数据源
adapters/native_file  Native 文件范围读取
adapters/http         经 target spike 验证的 HTTP Range adapter
cmd/pmtiles           inspect、get-tile、verify
examples              最小可运行示例
fixtures              固定测试数据、manifest 和许可证信息
benches               可复现的 Native release benchmark
spikes                可删除的工具链/API 实验
```

职责必须单向清晰：adapter 只取字节，不解释 PMTiles；codec 不执行 I/O；
CLI 不复制格式逻辑；writer 不负责制作地图瓦片。公共核心保持 target-neutral，
不得只在某个 backend 调用平台 API 来替代格式正确性。

## 二进制与资源安全规则

- 归档 offset 和 length 使用 `UInt64`。执行 `offset + length`、累计计数或转为
  内存索引之前，必须显式检查溢出和 target 可表示范围。
- Header 固定为 127 字节；magic、version、枚举值和声明范围都必须严格校验。
- varint 最多 10 字节，并拒绝截断、过长和 `UInt64` 溢出编码。
- Directory 条目数量、metadata、leaf、cache 和 HTTP 200 fallback 都必须受独立
  `Limits` 约束；不得用不可信计数直接触发无界分配。
- Directory 查找使用经过验证的排序数据和二分查找，不得在热点路径线性扫描。
- leaf 跳转必须限制次数并检测重复范围或循环。
- 单 tile 查询不得默认下载整个远程归档。初始 Header/root 合并读取上限为
  16 KiB；任何例外都必须由归档布局触发并有测试证明。
- `RangeSource` 成功时必须返回请求的精确字节数；短读必须是结构化错误。
- 不存在的 tile 用 `None` 表示。损坏、越界、短读或不支持的 codec 不得伪装成
  `None` 或部分成功。
- parser 面对任意输入都应在资源限制内终止。外部输入错误不得导致 panic。
- 错误可包含阶段和安全上下文，但不得泄露凭据、完整远程响应或不受控字节串。

## 公共 API 规则

- 公共 API 必须同时具有文档、单元测试、错误语义、资源限制和跨 target 行为说明。
- 所有公共构造必须维护类型不变量；不要让调用者轻易构造非法 Header、range 或
  coordinate。
- API 变更必须检查生成的 `.mbti` 差异，并同步相关契约和示例。
- 所有权、异步、error trait、文件 I/O、HTTP 和 gzip API 必须以当前 MoonBit
  工具链的实际编译结果为准，不得凭记忆设计后直接固化。
- writer 对相同有序输入必须产生逐字节一致的输出。生成内容不得包含时间戳、
  随机顺序或 host 路径。
- 性能优化必须先有正确性测试和基线；不要用未测量的“零拷贝”“高性能”宣传语。

## 测试与证据

每个实现任务都必须增加或更新聚焦测试，并报告实际运行的完整命令。根据当前
工具链支持情况，至少执行适用的命令：

```powershell
moon version --all
moon info
moon fmt --check
moon check --deny-warn --target all
moon test --deny-warn --target all
```

如果 `--target all` 或其他命令在当前工具链无效，保留错误输出，在 spike 记录中
写明可复现命令，然后逐 target 使用已验证的替代命令。不得修改事实来匹配计划。

测试层级应覆盖：

- Header、小端字段、varint、TileID 和 Directory 的单元测试；
- encode/decode、z/x/y 与 TileID、writer/reader 的 round-trip 性质；
- 空输入、边界值、整数溢出、乱序目录、短读和恶意计数；
- Memory source 的 root/leaf/tile 完整状态机和实际请求范围；
- 固定来源 fixture 与参考实现的差分结果；
- Native file、gzip 和 loopback HTTP Range 集成；
- CLI 成功、tile 缺失、损坏归档和稳定退出码；
- Native release benchmark，记录硬件、OS、toolchain、commit、样本和统计方法。

每个 target 必须独立记录 `Verified`、`Partially verified`、`Unverified`、`Blocked`
或 `N/A`。native 通过不能推断 wasm、wasm-gc 或 JavaScript 通过；编译通过也不能
替代运行测试。未执行的 target 必须明确写成 `Unverified`。

不要为了让测试通过而随意更新 fixture、snapshot 或期望值。每个变化都要能由规范、
手工向量、round-trip 或可信差分 oracle 解释。修复 bug 时必须增加回归测试。

## Fixture 与生成文件

- fixture 必须有 manifest，记录来源 URL、固定 commit/version、SHA-256、许可证和用途。
- 禁止在普通测试中临时从公网下载 fixture。
- 生成器输出必须可重复：相同输入连续生成两次应无 diff 且哈希一致。
- 生成文件头必须记录生成器命令、来源和格式版本。
- 不得手工编辑生成文件；修复生成器后重新生成。
- 只有通过固定生成器产生并完成 provenance 审查的输出才能提交。

## 任务纪律

- 以内部任务卡 `P-00`、`P-01` 等为工作单元，一次只执行一张任务卡。
- 开始前检查依赖、允许修改路径、验收条件、测试命令和非目标。
- 前置任务未完成时，下游任务保持 blocked；不得在下游任务中偷偷补做大量前置工作。
- 修改前说明准备改哪些文件。编辑文本文件优先使用 `apply_patch`。
- 不重构无关包，不顺带升级工具链，不引入 MVP 无关框架或依赖。
- 遇到脏工作树时保留用户修改。不得覆盖、回滚或格式化无关文件。
- spike 只记录实际执行过的 API、命令、成功和失败结果；推测必须明确标为假设。
- 每完成一张任务卡，先检查 diff 和测试证据，再形成一个或少量逻辑完整的 commit。

推荐的自然依赖顺序是：

```text
P-00 -> P-01 -> P-02 -> P-03 -> P-04 -> P-06 -> P-07
                         |        |
                         |        +------> P-08
                         +-> P-05 --------> P-08 -> P-09 -> P-10
```

未经 P-01 的真实工具链 spike，不得冻结 I/O、HTTP、压缩或异步 API。

## MoonBit 约定

- 遵循当前工具链认可的 module/package 结构；每个 package 使用 `moon.pkg`。
- 黑盒测试使用 `_test.mbt`，白盒测试使用 `_wbtest.mbt`。
- MoonBit 顶层块用 `///|` 分隔。
- 优先使用稳定、明确的断言，不用大范围 snapshot 掩盖二进制差异。
- `debug_inspect` 只用于结构化调试，不作为公共输出契约。
- 格式化后检查 diff，避免把无关格式噪声混入功能提交。

## Windows 与 PowerShell

主要开发环境是 Windows 和 PowerShell 7：

- 命令优先使用 PowerShell 兼容写法，不默认使用 Bash heredoc、`grep`、`sed`、
  `awk`、`&&` 或 `||`。
- 搜索文件和文本优先使用 `rg` / `rg --files`。
- 含空格、中文或特殊字符的路径使用 `-LiteralPath`。
- 多行 Python 使用 PowerShell here-string 管道给 `python -`。
- 普通验证应保持在同一个 `pwsh` 环境，减少 shell 差异。

## Git、GitHub 与提交历史

- 规范远程为 `https://github.com/Orion-XX/MoonPMTiles.git`，默认分支为 `main`。
- 本仓库提交作者使用仓库本地身份
  `OrionX <213938578+Orion-XX@users.noreply.github.com>`；不得修改用户的全局 Git 身份。
- 默认分支应保持可构建。非平凡实现使用短任务分支，例如
  `p02-header-tileid`、`p07-http-range`。
- commit 必须小而完整，包含一个真实逻辑成果及其测试。推荐 Conventional Commit
  主题并带任务号，例如 `feat(codec): validate PMTiles headers (P-02)`。
- 不得创建空提交、重复提交、纯凑数提交或把一个原子修改机械拆开。九月黑客松是否
  要求至少 10 个提交目前必须以官方规则为准；即使确认要求，也只累计自然产生的成果。
- 不得提交 token、凭据、个人路径、缓存、临时下载、构建输出或未经审查的生成数据。
- 不得 force-push、重写共享历史、reset 他人工作或使用破坏性清理命令。
- PR 标题以任务号开头；正文包含范围、Issue、文件、完整命令、各 target 结果、
  测试数、fixture/依赖来源、已知失败和剩余风险。
- CI 失败或要求的 target 未验证时不得自行宣称完成或合并；例外必须由负责人明确记录。

## 内部资料与公开边界

以下路径在当前工作区作为本地规划和申报资料使用：

```text
docs/
development/
research/
submission/
```

它们当前通过 `.git/info/exclude` 本地忽略，不会自动上传。Agent 可以读取和更新与
当前任务直接相关的内部文件，但必须在报告中区分“本地更新”和“公开仓库变更”。
不得使用 `git add -f` 绕过规则。公开 README、源码或 API 文档需要引用内部结论时，
只发布对用户必要且已经验证的内容，不公开内部评审、凭据或未确认赛事信息。

## 完成报告

每张任务卡结束时必须报告：

1. 修改的公开文件和仅本地修改的内部文件；
2. 新增或重新生成的文件及其来源；
3. 实际运行的完整命令；
4. 每个 target 的独立结果；
5. 测试总数、通过数和失败数；
6. fixture、依赖、版本、哈希和许可证变化；
7. 已验证、部分验证、未验证、阻塞项和已知风险；
8. commit/PR（若已创建）及下一张任务卡和依赖。

只报告可复现证据。计划、推测、编译通过和运行通过必须清楚区分。
