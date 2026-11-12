# 调研流程（生成任何代码之前必须完成）

reference 只提供方法，具体框架的内容靠调研得到。调研的目标是：**版本是最新且兼容的、知识点覆盖了官方的完整能力、原理讲解与实际源码一致**。

## 1. 查版本

- 从包仓库的元数据获取最新的稳定版，不要凭记忆写版本号：
  - Maven：`curl -s https://repo1.maven.org/maven2/<group路径>/<artifact>/maven-metadata.xml`，过滤掉 M / RC / SNAPSHOT
  - PyPI：`curl -s https://pypi.org/pypi/<package>/json`
  - npm：`npm view <package> versions`
- 有「版本列车」或 BOM 的生态（Spring Boot ↔ Spring Cloud、Spring AI ↔ Boot 等），要确认组合是兼容的。
  最新的组合还处于 RC 时，选上一个 GA 组合，并在根 POM / README 中注明原因。
- 用 BOM 或依赖树确认传递依赖的实际版本（例如 Spring Cloud CircuitBreaker 5.0.3 实际带的是 Resilience4j 2.3.0）。

## 2. 读官方文档

- 用户给了文档链接就从它开始；否则找官方文档的目录页。
- 目标是拿到**完整的能力清单**：支持哪些实现、有哪些集成点、有哪些配置项。特别留意：
  - 新版本新增的特性（往往是最值得学的）
  - 已废弃或进入维护模式的部分（只在【对比】中提及）
  - 文档中一笔带过、但看起来很关键的地方（这些需要读源码确认）

## 3. 读对应版本的源码

- 下载 sources jar（`mvn dependency:sources`，或从 Maven Central 直接下载 `-sources.jar`），解压到临时目录后阅读。
  Python 包直接读 site-packages 中的源码。
- 必读：入口类、自动配置类、核心的执行路径（例如 `run()` / `execute()` / `invoke()`）。
- 重点找**文档没写、但会影响行为**的细节：默认值、线程切换、配置的优先级、异常包装、隐式开关。
  这类发现往往就是 L3 原理模块和 faq 的核心内容。
- 注释和文档中引用的类名、方法名、默认值，都必须能在源码中找到。

## 4. 拟定知识点清单

结合 domain reference 中的「知识点维度」，把调研结果整理成 L1~L4：

- L1：官方 Getting Started 的范围 + 最核心的配置
- L2：各个集成点 + 常用特性组合 + 观测手段
- L3：源码中最关键的 2~4 个机制，至少一个「手写简化版 + 对照测试」
- L4：调参方法、监控告警、故障场景、运维手段

## 5. 没有对应 stack 时

1. 确定这门语言的主流构建工具、依赖管理方式、测试框架、多模块（或 workspace）组织方式。
2. 按 java-maven.md 的章节结构，在交付说明中给出一份「建议新增的 stack」草稿，供用户决定是否沉淀。

## 实测时的注意事项

- 示例应用要从 jar 的**副本**启动，或者用构建工具的 run 命令启动。重新打包会覆盖正在运行的 jar，导致应用出现 ClassNotFoundException 或请求卡住，容易被误判为代码问题。
- 实测输出写进 README 时，保留能说明问题的关键数据（状态、耗时、计数），去掉无关的噪音。
- 实测结果和文档或预期不一致时，就是最好的学习材料：查明原因，写进对应模块的【坑】和 faq。
