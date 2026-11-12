---
name: kai-learn-by-demo
description: 学习新技术时，生成可运行、注释详尽、按难度分层（入门/进阶/原理/生产）的示例学习项目，并附带原理文档、常见坑和练习题。适用于用户说「我想学 X」「帮我生成一个 X 的 demo / 示例项目 / 学习项目」「通过项目学习 X」等场景。Use when the user wants to learn a new technology by example, e.g. "generate a demo project for Spring Cloud / AWS / LangChain", "learn X by building", "scaffold a learning project".
---

# kai-learn-by-demo：通过示例项目学习新技术

目标：为用户生成一个**能跑起来、可以边看边改**的学习项目，让用户顺着代码和注释，由浅入深地掌握一门技术。

## 读者画像（生成内容时始终以此为准）

- 用户是 **Java 后端开发**，有一定的**架构基础**，熟悉 Spring、Maven、常见中间件。
- **不讲**编程基础、IDE 用法、Java 语法这类内容。
- **重点讲**：设计动机、实现原理、关键源码路径、和同类方案的取舍、生产中的坑。
- 学习非 Java 技术（Python、AI 等）时，**主动用 Java 生态来类比**，例如「FastAPI 的依赖注入 ≈ Spring 的 `@Autowired`，但它是按函数参数解析的」。

## 工作流程

### 1. 确认需求（最多问一轮，能用默认值就不问）

| 项 | 默认值 |
|---|---|
| 生成目录 | **当前工作目录**；用户指定了目录就用指定的 |
| 技术与版本 | 按对应 reference 中的「版本基线」，生成前核对最新兼容版本 |
| 学习目标 | 覆盖 L1~L3，L4 只在用户提到生产或面试时才生成 |
| 范围 | reference 中的「必学知识点」；用户点名的知识点优先 |

目标目录非空时，先列出已有内容，确认后再写入，绝不覆盖用户的文件。

### 2. 加载 reference

先读 [references/conventions.md](references/conventions.md)，这是所有技术都要遵守的通用规范（注释、文档、分级）。
再按下面的路由表读取对应技术的 reference；一个项目涉及多个方向时，相关的 reference 都要读。

| 技术方向 | 先读 | 再读 |
|---|---|---|
| Java 生态（Maven 构建的任何项目） | [references/java-maven.md](references/java-maven.md) | — |
| Spring Cloud / 微服务 | [references/java-maven.md](references/java-maven.md) | [references/spring-cloud.md](references/spring-cloud.md) |
| AWS（S3、SQS、DynamoDB、Lambda…） | [references/java-maven.md](references/java-maven.md) | [references/aws.md](references/aws.md) |
| 路由表中没有的技术 | 只按 conventions.md 生成，并按其中「没有 reference 时」一节先拟定知识点清单 | — |

### 3. 设计学习路线（先给用户看，再生成代码）

输出一份简短的路线大纲：

```
L1 入门    01-xxx：一句话学习目标
           02-xxx：...
L2 进阶    ...
L3 原理    ...
（L4 生产  ...）
公共模块   xxx-common：放了什么
外部依赖   docker-compose 中有哪些服务
```

用户没有异议（或明确说直接生成）就继续。大纲是 README 学习路线的初稿。

### 4. 生成项目

严格按照 conventions.md 和对应技术 reference 的要求生成：

- **结构**：按级别拆分模块，每个知识点一个模块（Java 项目的具体规则见 java-maven.md），可以复用的代码下沉到 common 模块。
- **代码注释**：每个类开头写「是什么 / 为什么 / 原理」，关键代码写行内注释，标注 `【原理】【对比】【坑】`。
- **文档**：根目录 README（使用 [assets/README.template.md](assets/README.template.md)），每个模块一份 README；
  篇幅较长的原理放进 `docs/`（使用 [assets/principle.template.md](assets/principle.template.md)）。
- **外部依赖**：中间件统一放进根目录的 `docker-compose.yml`，一条命令就能启动。
- **可验证**：每个模块都要有一个能直接运行的入口（main 方法、测试类或 HTTP 请求文件），并在 README 中说明预期输出。

模块较多时按级别分批生成，每生成完一批就检查一次能否编译。

### 5. 自检

- [ ] 能编译通过（Java 项目执行 `mvn -q -DskipTests package`，环境允许时也跑一下测试）
- [ ] 每个模块都有 README，写明学习目标、运行方式和预期结果
- [ ] 注释覆盖了 conventions.md 中要求的内容，不是空洞的套话
- [ ] 根 README 的学习路线与实际模块一一对应
- [ ] 没有提交任何真实凭证（AK/SK、密码），配置中只用占位符或本地模拟环境的值

命令无法执行时（例如没有装 Maven 或 Docker），如实告诉用户哪些步骤没有验证。

### 6. 交付说明

最后给用户一段简短说明，包括：项目位置、建议的学习顺序、第一个要运行的命令，以及没有验证的部分。

## 变更记录

- 2026-11-12：初版，支持 Spring Cloud、AWS；Java 项目统一用 Maven 多模块构建。
