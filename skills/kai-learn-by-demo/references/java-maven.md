# Java 项目通用规则（Maven 多模块）

所有 Java 方向的学习项目（Spring Cloud、AWS SDK for Java 等）都按本文件组织。

## 版本基线

- JDK：**21**（LTS）。用户环境是 JDK 25 时可以使用 25。
- 构建：**Maven**，根目录提供 Maven Wrapper（`mvnw`），用户不需要自己安装 Maven。
- 具体技术的版本见各自的 reference，生成前要核对最新的兼容版本。

## 模块结构

级别是**聚合模块**（packaging=pom），知识点是级别下的**子模块**；能复用的代码下沉到 common 模块。

```
<project>/                                  # 例：spring-cloud-demo
├── pom.xml                                 # 根 POM：只做聚合与版本管理
├── mvnw / .mvn/
├── <project>-common/                       # 公共模块：DTO、工具类、统一返回体、通用配置
├── level1-basic/
│   ├── pom.xml                             # packaging=pom
│   ├── 01-<topic>/                         # 例：01-service-registry
│   └── 02-<topic>/
├── level2-advanced/
├── level3-principle/
└── level4-production/                      # 可选
```

### 命名

- artifactId：`<project>-l<级别>-<NN>-<topic>`，例如 `scdemo-l1-01-service-registry`，
  保证在 IDE 中排序后仍然是学习顺序。
- 包名：`<groupId>.l<级别>.<topic>`，例如 `com.kai.learn.scdemo.l1.registry`，不同模块之间不会冲突。
- groupId 默认用 `com.kai.learn.<project>`。

### 一个知识点需要多个进程时（如服务提供者 + 消费者）

在知识点模块下再拆分子模块：

```
01-service-discovery/
├── pom.xml                  # packaging=pom
├── provider/
└── consumer/
```

### 什么代码应该下沉到 common

| 下沉 | 不下沉 |
|---|---|
| 多个模块都在用的 DTO、统一返回体、异常 | 本模块要讲解的核心代码（必须留在模块内，让读者一眼就能看到） |
| 日志、Jackson 等通用配置 | 只有一个模块用到的工具 |
| 测试辅助类（放到 `<project>-common` 的 test-jar，或者单独建 `<project>-test-support`） | 带有知识点讲解的配置类 |

原则：**下沉的是「噪音」，留下的是「知识点」**。
common 模块太大时可以拆分成 `<project>-common`（纯工具）和 `<project>-core`（领域相关的公共逻辑）。

## 根 POM 要求

- 用 `<dependencyManagement>` 引入 BOM（spring-boot-dependencies、spring-cloud-dependencies、AWS SDK BOM 等），
  子模块中**不写版本号**。
- 用 `<properties>` 集中声明版本，每个版本旁边注释说明它和其他版本之间的兼容关系。
- 用 `<pluginManagement>` 统一管理 spring-boot-maven-plugin 等插件；只有可以运行的模块才启用 repackage。
- 根 POM 本身也要写注释，讲清楚「BOM 是怎么工作的、为什么子模块不用写版本」，这本身就是一个知识点。

## 可运行入口

| 场景 | 入口 |
|---|---|
| 单进程示例 | `@SpringBootApplication` main 方法，或普通 main 方法 |
| 只需要验证 API 行为 | JUnit 5 测试类，方法名用中文或 `should_xxx_when_yyy` |
| HTTP 接口 | 模块内提供 `requests.http`（IntelliJ HTTP Client 格式） |
| 需要中间件 | 优先使用 docker-compose；测试中可以用 Testcontainers |

模块 README 中给出运行命令，例如：

```bash
./mvnw -pl level1-basic/01-service-registry -am spring-boot:run
```

## 自检命令

```bash
./mvnw -q -DskipTests package       # 至少要保证能编译
./mvnw -q test                      # 环境允许时执行
```
