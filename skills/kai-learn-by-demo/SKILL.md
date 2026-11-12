---
name: kai-learn-by-demo
description: 学习新技术时，生成可运行、注释详尽、按难度分层（入门/进阶/原理/生产）的示例学习项目，代码经过实测，附带原理文档、常见坑和练习题。适用于用户说「我想学 X」「帮我生成一个 X 的 demo / 示例项目 / 学习项目」「通过项目学习 X」等场景，X 可以是任意框架、中间件、云服务、AI 工具。Use when the user wants to learn a new technology by example, e.g. "generate a demo project for Spring Cloud / Kafka / AWS / LangChain", "learn X by building", "scaffold a learning project".
---

# kai-learn-by-demo：通过示例项目学习新技术

目标：为用户生成一个**能跑起来、可以边看边改、内容经过实测**的学习项目，让用户顺着代码和注释，由浅入深地掌握一门技术。

## 读者画像（生成内容时始终以此为准）

- 用户是 **Java 后端开发**，有一定的**架构基础**，熟悉 Spring、Maven、常见中间件。
- **不讲**编程基础、IDE 用法、Java 语法这类内容。
- **重点讲**：设计动机、实现原理、关键源码路径、和同类方案的取舍、生产中的坑。
- 学习非 Java 技术（Python、AI 等）时，**主动用 Java 生态来类比**，例如「FastAPI 的依赖注入 ≈ Spring 的 `@Autowired`，但它是按函数参数解析的」。

## Reference 的组织方式

reference **不按具体框架**写，而是按两个维度组织。具体框架的知识点由你按调研流程自行确定：

| 维度 | 回答的问题 | 目录 |
|---|---|---|
| 语言生态（stack） | 用什么语言写、怎么构建、怎么运行和测试 | `references/stacks/` |
| 技术形态（domain） | 怎么拆解知识点、需要什么演示环境、必须做哪些实验 | `references/domains/` |

一个学习项目 = 1 个生态 + 1~2 个形态。例如：熔断（Spring Cloud CircuitBreaker）= java-maven + distributed-governance；
LangChain = python + ai-application；Kafka = java-maven + middleware。

## 工作流程

### 1. 确认需求与环境（最多问一轮，能用默认值就不问）

| 项 | 默认值 |
|---|---|
| 生成目录 | **当前工作目录**；用户指定了目录就用指定的 |
| 学习范围 | 用户说的是一个大领域（如 Spring Cloud）时，先列出子主题请用户挑选；说的是具体组件（如 CircuitBreaker）时，就聚焦这个组件 |
| 学习目标 | 覆盖 L1~L3；L4 只在用户提到生产或面试时生成，或者在给出路线时询问 |
| 语言 | 技术本身支持 Java 时用 Java；否则用该技术的主流语言 |

同时检查本机环境：对应的 JDK / Python / Node、构建工具、Docker（**daemon 是否在运行**，不只是命令是否存在）。
缺少的环境会影响哪些模块，要在路线中注明。目标目录非空时，先列出已有内容，确认后再写入，绝不覆盖用户的文件。

### 2. 加载 reference

1. 必读：[references/conventions.md](references/conventions.md)（通用规范）和 [references/research.md](references/research.md)（调研流程）。
2. 按语言选择一个 stack：

   | 语言 | stack |
   |---|---|
   | Java / Kotlin（Maven） | [references/stacks/java-maven.md](references/stacks/java-maven.md) |
   | Python | [references/stacks/python.md](references/stacks/python.md) |
   | 其他 | 没有对应文件时，按 research.md 的「没有对应 stack 时」处理 |

3. 按技术形态选择 1~2 个 domain：

   | 技术形态 | 例子 | domain |
   |---|---|---|
   | 框架 / 库 | Spring Data JPA、MyBatis、Reactor、Quarkus、JSpecify | [references/domains/framework-library.md](references/domains/framework-library.md) |
   | 中间件 / 存储 | Kafka、RocketMQ、Redis、Elasticsearch、Neo4j | [references/domains/middleware.md](references/domains/middleware.md) |
   | 分布式治理 | 熔断、限流、网关、注册与配置中心、链路追踪 | [references/domains/distributed-governance.md](references/domains/distributed-governance.md) |
   | 云服务 | AWS、阿里云、GCP 的各项托管服务 | [references/domains/cloud-service.md](references/domains/cloud-service.md) |
   | AI 应用 | LLM API、Spring AI、LangChain(4j)、RAG、Agent、MCP | [references/domains/ai-application.md](references/domains/ai-application.md) |

   都不合适时，选最接近的一个，并在交付说明中建议新增一个 domain。

### 3. 调研（按 research.md 执行，不能跳过）

查版本 → 读官方文档 → 读对应版本的源码 → 拟定知识点清单。调研结论（版本组合、新特性、和文档不一致的地方）要写进根 README 或原理文档。

### 4. 设计学习路线（先给用户看，再生成代码）

```
版本与环境   核实过的版本组合；缺失的环境及其影响
L1 入门      01-xxx：一句话学习目标
L2 进阶      ...
L3 原理      ...（至少一个「手写简化版 + 与真实实现对照测试」）
L4 生产      ...（可选）
公共模块     放了什么；需要什么演示道具（如故障注入服务、mock 模型）
外部依赖     docker-compose 中有哪些服务
```

用户没有异议（或明确说直接生成）就继续。

### 5. 生成并逐个实测

按 conventions.md、stack 和 domain 的要求生成。**按级别分批生成，每生成一批就编译并运行一批**：

- 每个模块都要真正运行一次，把关键输出（状态变化、耗时、计数）**写进模块 README 的「实测结果」**。
- 实测结果与预期不一致时，先查明原因（通常要读源码），再修改代码或注释；不要把预期当作结果写进文档。
- 注释和文档中引用的源码类名、方法名、默认值，都要核对过源码。
- 无法验证的部分（例如 Docker 没有运行），在对应的 README 中明确标注「未验证」。

### 6. 交付说明

告诉用户：项目位置、建议的学习顺序、第一条要执行的命令、实测中最值得关注的几个发现，以及没有验证的部分。

### 7. 知识沉淀（每次学习结束时）

这个 skill 是用户的个人知识体系，会随着每次学习逐步完善。交付说明的最后，列出这次可以沉淀回 skill 的经验，**只列可以泛化的部分**：

| 沉淀到 | 内容 | 举例 |
|---|---|---|
| domains/xxx.md | 这一类技术共通的知识点维度、实验、坑 | 「治理组件包装的调用可能运行在其他线程中，要检查上下文传递」 |
| stacks/xxx.md | 构建、运行、测试上的经验 | 「`-am` 与 `spring-boot:run` 不能一起用」 |
| research.md / conventions.md | 调研和生成流程上的改进 | 「检查 Docker daemon 是否在运行」 |

只属于某个框架的细节**不要沉淀**，它们已经保存在生成的项目中。用户同意后，再去修改 skill 仓库（kailbin/agent-skills）。

## 变更记录

- 2026-11-12：初版，支持 Spring Cloud、AWS；Java 项目统一用 Maven 多模块构建。
- 2026-11-12：reference 改为「语言生态 × 技术形态」两个维度，不再按具体框架编写；新增调研流程、逐模块实测、知识沉淀步骤。来自 Spring Cloud CircuitBreaker 的试用反馈。
- 2026-11-12：Java 项目不再继承 spring-boot-starter-parent，改为 import BOM，并列出需要自己补上的构建配置。
- 2026-11-12：Maven 项目默认引入 Lombok 与 SLF4J；Lombok 在 maven-compiler-plugin 中显式声明为注解处理器（JDK 23+ 必需，已在 JDK 25 上实测）。
- 2026-11-12：根 POM 默认依赖改为 lombok / logback-classic / junit-jupiter，spring-boot-starter-test 等按需在模块中声明；
  内部模块不进 dependencyManagement，直接用 `${project.version}`；打印日志的模块放 logback.xml。
