# Stack：Java + Maven 多模块

所有 Java 方向的学习项目都按本文件组织。

## 版本基线

- JDK：使用本机已安装的最新 LTS（21 或 25），在根 POM 的 `java.version` 中声明。
- 构建：**Maven**，根目录提供 Maven Wrapper（`mvn -N wrapper:wrapper -Dmaven=<本机版本>`），用户不需要自己安装 Maven。
- 框架版本按 research.md 查询，不凭记忆写。
- 【坑】先看 `~/.m2/settings.xml` 中有没有自定义 `localRepository`，查找 sources jar 时要去那个目录。

## 模块结构

级别是**聚合模块**（packaging=pom），知识点是级别下的**子模块**；能复用的代码下沉到 common 模块。

```
<project>/                                  # 例：Spring-Cloud-CircuitBreaker
├── pom.xml                                 # 根 POM：只做聚合与版本管理
├── mvnw / mvnw.cmd / .mvn/
├── <prefix>-common/                        # 公共代码：DTO、统一返回体、客户端封装、测试工具（如可控时钟）
├── <prefix>-<道具>/                         # 演示道具，例如可以注入故障的下游服务（见 domain reference）
├── level1-basic/
│   ├── pom.xml                             # packaging=pom
│   ├── 01-<topic>/
│   └── 02-<topic>/
├── level2-advanced/
├── level3-principle/
└── level4-production/                      # 可选
```

### 命名

- `<prefix>` 是项目的短前缀，例如 `cbdemo`。
- artifactId：`<prefix>-l<级别>-<NN>-<topic>`，例如 `cbdemo-l1-01-circuitbreaker-factory`，在 IDE 中排序后仍然是学习顺序。
- 包名：`<groupId>.l<级别>.<topic>`，例如 `com.kai.learn.cbdemo.l1.factory`，不同模块之间不会冲突。
- groupId 默认用 `com.kai.learn.<prefix>`。
- 包名中不能使用 Java 关键字（例如 `switch` 要写成 `switchimpl`）。

### 一个知识点需要多个进程或多个变体时

在知识点模块下再拆分子模块。例如服务提供者 + 消费者，或者「同一份业务代码搭配三种实现」：

```
06-switch-implementation/
├── pom.xml                  # packaging=pom
├── business/                # 共用的业务代码（普通 jar）
├── impl-a-app/
└── impl-b-app/
```

### 什么代码应该下沉到 common

| 下沉 | 不下沉 |
|---|---|
| 多个模块都在用的 DTO、统一返回体、异常工具 | 本模块要讲解的核心代码（必须留在模块内） |
| 对演示道具的 HTTP 客户端封装 | 只有一个模块用到的工具 |
| 测试工具（如可控时钟 `MutableClock`） | 带有知识点讲解的配置类 |

原则：**下沉的是「噪音」，留下的是「知识点」**。第一个模块可以保留一份带讲解的客户端，后面的模块再使用 common 中的版本。
common 只依赖必需的库；会被纯 Java 模块依赖时，Web 等依赖标记为 `<optional>true</optional>`。

## 根 POM 要求

- 继承框架的 parent（如 `spring-boot-starter-parent`），再用 `<dependencyManagement>` import 其他 BOM。
  根 POM 的注释中要讲清楚「继承 parent」和「import BOM」的区别，这本身就是一个知识点。
- 子模块中**不写版本号**；项目内部模块的版本也在根 POM 的 dependencyManagement 中统一声明。
- `<properties>` 中注释写明各版本之间的兼容关系。
- 只有可以运行的模块才声明 spring-boot-maven-plugin。
- 测试依赖（如 spring-boot-starter-test）放在根 POM 中统一引入。

## 可运行入口

| 场景 | 入口 |
|---|---|
| 单进程示例 | `@SpringBootApplication` 或普通 main 方法 |
| 原理实验、对照测试 | JUnit 5 测试类，方法名用中文描述规则，如 `void 失败率达到阈值时打开()` |
| HTTP 接口 | 模块内提供 `requests.http`（IntelliJ HTTP Client 格式） |
| 需要中间件 | 优先使用 docker-compose；测试中可以用 Testcontainers |

## 运行命令（README 中统一这样写）

```bash
./mvnw install -DskipTests                                  # 第一次运行前执行一次，把 common 等模块装到本地仓库
./mvnw -pl level1-basic/01-xxx spring-boot:run              # 运行某个模块
./mvnw -pl level3-principle/01-xxx test                     # 运行测试
./mvnw -q -pl <module> compile exec:java -Dexec.mainClass=<类名>   # 运行普通 main 方法
```

【坑】不要写成 `-pl X -am spring-boot:run`：`-am` 会把依赖的模块也加入构建，spring-boot:run 会在没有启动类的 common 模块上执行并失败。

## 自检

```bash
./mvnw clean install          # 编译 + 全部测试
```

- 分批生成时，可以先在聚合 POM 中把还没有生成的模块注释掉，最后再全部打开。
- 实测运行应用时，从 jar 的副本启动，或者用 `spring-boot:run`；不要在应用运行期间重新打包它正在使用的 jar。
