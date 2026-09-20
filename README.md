# MoonPMTiles

MoonPMTiles 是一个计划中的纯 MoonBit PMTiles v3 工具链，目标是在 Native、
JavaScript、Wasm 与 Wasm GC 环境中，以相同的核心 API 解析、按范围读取、校验并
生成 PMTiles 归档。核心价值是让地图、遥感、边缘计算和对象存储应用只读取所需
瓦片，而不是下载整个归档。

> 当前状态：**P-00 文档规划阶段**。尚无可构建源码、可运行示例或已验证性能数据。
> 九月黑客松的截止时间、仓库和 commit 规则尚未取得官方文本，均为 `Unknown`。

## 目标用户

- 在 MoonBit 中开发地图、GIS、遥感或离线地图工具的开发者；
- 通过 S3、R2、OSS、CDN 或普通 HTTP 托管瓦片的应用团队；
- 需要在浏览器、Wasm、边缘节点或 Native CLI 中读取 PMTiles 的开发者。

## 计划中的 MVP

1. PMTiles v3 Header、Directory、Metadata 与 Hilbert TileID 编解码；
2. `UInt64` 范围计划和 Memory、Native file、HTTP 后端；
3. 有界缓存、结构化错误、归档校验和确定性 Writer；
4. `inspect`、`get-tile`、`verify` CLI 与跨 target 示例；
5. 固定来源的测试向量、属性测试、差分测试和 Native benchmark。

不包含地图渲染、投影、GeoJSON 切片、完整 S3 SDK、在线服务端或自研压缩算法。

## 当前可复现检查

当前只有环境调查可复现：

```powershell
moon version --all
```

`moon check`、`moon test`、示例和 CLI 命令要等 P-01 之后存在 MoonBit module 和源码
才能运行。任何尚未执行的 target 都不得写成已通过。

## 标准与项目类型

本项目按“原创 MoonBit 生态项目、参考公开规范”申报，不是对某个参考实现的逐行移植。
格式依据是 [PMTiles v3 Specification](https://github.com/protomaps/PMTiles/blob/main/spec/v3/spec.md)。
规范为 Public Domain/CC0（适用处）；上游参考实现采用 BSD-3-Clause。若后续参考代码、
fixture 或示例数据，将逐项记录来源、固定版本、哈希、许可证和采用范围。
