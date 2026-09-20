# MoonPMTiles

跨 target 的 MoonBit PMTiles v3 核心工具链：解析 Header、Directory、TileID，执行有界范围读取，校验归档，并为确定性 writer、Memory source 和 HTTP Range 响应提供可组合的基础模块。

> 当前状态：核心格式编解码、Memory/archive 路径、确定性 writer、HTTP Range 响应校验、畸形输入测试和 Native release benchmark 已实现并通过本地验证。Native file、gzip provider、真实 HTTP transport、CLI 端到端运行和 mooncakes.io 发布仍是明确的后续工作，不能视为已交付功能。

## 快速开始

环境要求：MoonBit `0.1.20260819`（`moonc v0.10.9+6e6c44045`）。在仓库根目录执行：

```powershell
moon fmt --check
moon check --deny-warn --target all
moon test --deny-warn --target all
moon info
moon bench benches --target native --release
```

当前验证结果：Wasm、Wasm GC、JavaScript 和 Native 各 `24/24` 测试通过；Native release benchmark 的 Header encode/decode 基线为一次本地运行中的约 `431 ns`（10 × 100000 runs）。基准数字只用于相对比较，不是跨机器承诺。

## 项目范围

- PMTiles v3 Header、Directory、Metadata、varint 和 Hilbert TileID 编解码；
- `UInt64` 安全边界、有界解析、结构化错误和二分 Directory lookup；
- Memory source、archive 状态机、`none` compression provider；
- 确定性 writer、HTTP Range 206/200 fallback 响应校验；
- 跨 target 的单元、畸形输入和 round-trip 基础测试。

明确不在 MVP 范围内：地图渲染、投影、GeoJSON/MVT 生成、完整 S3 SDK、在线服务、持久化缓存和自研压缩算法。

## 架构

纯 MoonBit 核心位于 `src/`，adapter 只负责提供字节，codec 不执行 I/O，CLI 不复制格式逻辑。平台能力通过 adapter 注入，以便 Native、Wasm、Wasm GC 和 JavaScript 共享格式行为。

规范依据：[PMTiles v3 Specification](https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md)。

## 贡献

请先阅读 [`AGENTS.md`](AGENTS.md) 和 [`docs/04_TASK_BREAKDOWN.md`](docs/04_TASK_BREAKDOWN.md)。每项工作应对应一张任务卡，在独立分支完成，使用可复现命令验证，并提交小而完整的真实 commit。贡献和 PR 必须使用项目维护者身份：

```text
OrionX <213938578+Orion-XX@users.noreply.github.com>
```

请不要提交内部规划目录、构建输出、凭据或未经 provenance 审查的 fixture。

## 许可证

本项目采用 [MIT License](LICENSE)。PMTiles 规范和外部 fixture/参考资料的许可证以各自来源为准；新增来源必须在对应 manifest 或文档中记录版本、哈希、许可证和用途。
