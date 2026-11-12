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
├── pom.xml                                 # 根 POM：聚合、版本管理（import BOM）、统一构建配置
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

**不继承框架的 parent**（如 `spring-boot-starter-parent`），所有 BOM 都通过 `<dependencyManagement>` import 引入，
parent 的位置留给公司或个人的统一父 POM。

- import 多个 BOM 时，**先声明的优先**：Spring Boot 的 BOM 放在最前面，Spring Cloud、Spring AI 等放在后面。
- 子模块中**不写版本号**；项目内部模块的版本也在根 POM 的 dependencyManagement 中统一声明。
- `<properties>` 中声明框架版本，并注释写明各版本之间的兼容关系。
- 测试依赖（如 spring-boot-starter-test）放在根 POM 中统一引入。
- 根 POM 的注释中要讲清楚「import BOM」与「继承 parent」的区别，以及下面这些需要自己补上的配置，这本身就是一个知识点。

不继承 parent 时，必须自己补上的构建配置：

| 配置 | 写法 | 漏掉的后果 |
|---|---|---|
| 编码、Java 版本 | `project.build.sourceEncoding=UTF-8`、`maven.compiler.release` | 中文乱码；字节码版本不对 |
| 编译器 `-parameters` | maven-compiler-plugin `<parameters>true</parameters>` | **编译正常，运行时报错**：`@RequestParam int n`、`@PathVariable String id` 这类未写名字的参数无法绑定 |
| 插件版本 | `<pluginManagement>` 中固定版本，与所用 Boot 版本的 spring-boot-dependencies 中声明的插件版本一致 | 使用 Maven 内置的旧版本插件，行为不一致 |
| spring-boot-maven-plugin | 在 pluginManagement 中声明版本，并配置 `repackage` execution；只有可运行的模块在自己的 `<build>` 中引用（不写版本） | `java -jar` 报 `no main manifest attribute` |

插件版本的查法：打开 `spring-boot-dependencies-<版本>.pom`，搜索 `maven-compiler-plugin.version` 等属性。
自检时确认可运行模块的 jar 中有 `Start-Class`：`unzip -p xxx.jar META-INF/MANIFEST.MF`。

## 默认依赖：Lombok + SLF4J

所有 Maven 项目都在**根 POM 的 `<dependencies>`** 中引入这两个依赖，所有模块默认可用：

```xml
<properties>
    <!-- 与 spring-boot-dependencies 中的 lombok.version 保持一致。
         import BOM 只导入依赖版本，不导入 BOM 中的 <properties>，所以 ${lombok.version} 要自己声明 -->
    <lombok.version>x.y.z</lombok.version>
</properties>

<dependencies>
    <dependency>
        <groupId>org.projectlombok</groupId>
        <artifactId>lombok</artifactId>
        <!-- 只在编译期使用，不会打进 jar -->
        <scope>provided</scope>
    </dependency>
    <dependency>
        <groupId>org.slf4j</groupId>
        <artifactId>slf4j-api</artifactId>
    </dependency>
</dependencies>
```

**Lombok 必须在 maven-compiler-plugin 中显式声明为注解处理器**：

```xml
<plugin>
    <groupId>org.apache.maven.plugins</groupId>
    <artifactId>maven-compiler-plugin</artifactId>
    <version>${maven-compiler-plugin.version}</version>
    <configuration>
        <parameters>true</parameters>
        <annotationProcessorPaths>
            <path>
                <groupId>org.projectlombok</groupId>
                <artifactId>lombok</artifactId>
                <version>${lombok.version}</version>
            </path>
        </annotationProcessorPaths>
    </configuration>
</plugin>
```

- 【坑】从 JDK 23 开始，javac 不再默认执行 classpath 上的注解处理器。不显式声明时，`@Slf4j`、`@Getter` 等注解不会生效，
  编译报错 `cannot find symbol: variable log`。
- 【坑】`annotationProcessorPaths` 中的 `<version>` 不受 dependencyManagement 管理，必须写明，所以根 POM 要声明 `lombok.version`。
- 在 JDK 24+ 上编译时，Lombok 会打印 `sun.misc.Unsafe::objectFieldOffset has been called by lombok.permit.Permit` 警告，
  不影响编译结果，在 README 中说明一句即可。
- 项目中还用到其他注解处理器（如 MapStruct、spring-boot-configuration-processor）时，要一起列在 `annotationProcessorPaths` 中，
  一旦显式声明，就只会执行列出的处理器。
- 版本查法：`spring-boot-dependencies-<版本>.pom` 中的 `lombok.version`；没有使用 Spring Boot 时，到 Maven Central 查最新版本，并确认它支持所用的 JDK 版本。
- SLF4J 只是日志门面：Spring Boot 模块由 starter 提供 Logback 实现；纯 Java 模块（如 L3 的测试模块）需要输出日志时，
  再加 `logback-classic`（runtime 或 test scope），否则 SLF4J 会提示没有绑定实现，日志不会输出。
- 根目录放一个 `lombok.config`：

  ```properties
  config.stopBubbling = true
  # 生成的代码带上 @Generated，覆盖率统计会忽略它们
  lombok.addLombokGeneratedAnnotation = true
  ```

**示例代码中怎样使用 Lombok**：用来去掉噪音，不要遮住知识点。

| 推荐 | 不推荐 |
|---|---|
| `@Slf4j` 代替 `LoggerFactory.getLogger(...)` | 用 `@Data` 写 DTO：不可变的数据用 `record` |
| `@RequiredArgsConstructor` 用于普通的构造器注入 | 知识点本身就是构造过程时（例如构造器中创建熔断器），仍然手写构造器 |
| `@Getter`、`@Builder` 用于配置类、复杂的值对象 | `@SneakyThrows`、`val` 等会让读者困惑的特性 |

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
