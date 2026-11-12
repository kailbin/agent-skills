# Spring Cloud 学习项目

> 先读 java-maven.md，本文件只补充 Spring Cloud 特有的内容。

## 1. 版本基线

- Spring Boot 与 Spring Cloud **必须按 Release Train 配套使用**。生成前查看
  https://spring.io/projects/spring-cloud 的兼容表，选择最新的 GA 组合。
- 使用 Spring Cloud Alibaba 时，再核对它的版本说明（https://github.com/alibaba/spring-cloud-alibaba/wiki），
  如果它还没有适配最新的 Boot 版本，**整体降到它支持的那组版本**，并在根 POM 注释中写明原因。
- 根 POM 的 properties 中注释写明：Boot 版本 ↔ Cloud Release Train ↔ Alibaba 版本之间的对应关系。

## 2. 默认技术选型

用户没有指定时，按下面的默认值选择，并在 README 中写明可以替换成什么：

| 能力 | 默认 | 备选（在【对比】中讲解） |
|---|---|---|
| 注册中心 | Nacos | Eureka、Consul |
| 配置中心 | Nacos Config | Spring Cloud Config |
| 服务调用 | OpenFeign | RestClient / `@HttpExchange` + LoadBalancer |
| 负载均衡 | Spring Cloud LoadBalancer | （Ribbon 已停止维护，只在对比中提及） |
| 网关 | Spring Cloud Gateway | — |
| 熔断限流 | Spring Cloud CircuitBreaker + Resilience4j | Sentinel |
| 分布式事务 | Seata（只放在 L4，可选） | 本地消息表、事务消息 |
| 链路追踪 | Micrometer Tracing + Zipkin | SkyWalking |

## 3. 必学知识点

### L1 入门

| 模块 | 内容 | 学完能回答 |
|---|---|---|
| 01-service-registry | provider 注册到 Nacos，查看控制台 | 服务注册时上报了什么？心跳机制是怎样的？ |
| 02-service-discovery | consumer 通过 DiscoveryClient + LoadBalancer 调用 provider | 服务名是怎样解析成 IP 的？ |
| 03-openfeign | 声明式调用、超时配置、日志级别 | 一个 Feign 接口最终是怎样变成 HTTP 请求的？ |
| 04-config-center | 外部化配置、`@RefreshScope` 动态刷新 | 配置刷新的时候，Bean 发生了什么？ |
| 05-gateway | 路由、断言（Predicate）、过滤器（Filter） | 一个请求在网关里经过了哪些步骤？ |

### L2 进阶

| 模块 | 内容 |
|---|---|
| 01-loadbalancer-strategy | 自定义负载均衡策略（如同机房优先、灰度标签路由） |
| 02-circuit-breaker | Resilience4j 熔断、重试、舱壁隔离，演示熔断器的状态切换 |
| 03-gateway-custom-filter | 自定义 GlobalFilter：鉴权、限流（Redis RateLimiter）、traceId 透传 |
| 04-feign-advanced | 拦截器传递 Header、自定义错误解码器、调用降级 |
| 05-gray-release | 基于 Header / 元数据的灰度路由，需要网关和 LoadBalancer 配合 |
| 06-tracing | 跨服务链路追踪，在 Zipkin 中查看调用链 |

### L3 原理（重点）

| 模块 | 内容 |
|---|---|
| 01-mini-registry | **手写**简易注册中心：注册、心跳、剔除、拉取，并与 Nacos 的 AP/CP 设计对照 |
| 02-mini-feign | **手写**基于 JDK 动态代理的声明式 HTTP 客户端，对照 `FeignClientFactoryBean` |
| 03-mini-loadbalancer | **手写** `ClientHttpRequestInterceptor` 实现服务名 → 实例的解析，对照 `LoadBalancerInterceptor` |
| 04-auto-configuration | 拆解 `@EnableDiscoveryClient`、`AutoConfiguration.imports`，手写一个 starter |
| 05-refresh-scope | 用断点和日志观察 `RefreshScope` 的代理和 Bean 重建过程 |

### L4 生产（可选）

- 优雅上下线（先摘流量再停机，处理注册中心的缓存延迟）
- 网关高可用与限流的分层设计
- Seata AT 模式演示，以及它的适用边界
- 配置中心的权限、灰度发布配置
- 微服务拆分边界讨论（放在 docs 中，不写代码）

## 4. 注释与原理讲解重点

- **自动装配链路**：每个组件都要指出它的入口 AutoConfiguration 类（`// 【源码】`）。
- **客户端缓存**：服务实例列表在客户端有缓存，这是很多「下线了还有流量」问题的根源。
- **Release Train 机制**：讲清楚 BOM 如何保证一组组件之间的兼容。
- **Nacos AP / CP**：临时实例与持久实例的区别，对照 CAP。
- **对比 Dubbo**：用户可能熟悉 Dubbo，在调用方式、注册模型（接口级 vs 应用级）等方面做对比。

## 5. 常见坑（写进 docs/faq.md 和对应代码的 `// 【坑】`）

1. Boot / Cloud / Alibaba 版本不匹配导致启动失败：报错信息不直观，给出排查方法。
2. Gateway 基于 WebFlux：引入 `spring-boot-starter-web` 会冲突。
3. Feign 默认超时和 LoadBalancer 重试叠加，导致请求被放大。
4. `@RefreshScope` 和 `@ConfigurationProperties` 混用时的刷新行为差异。
5. 服务下线后，消费端的实例缓存没有及时更新，导致调用失败。
6. Nacos namespace / group 配置错误，导致服务互相看不到对方。

## 6. 运行环境

docker-compose 默认包含：

| 服务 | 用途 | 端口 |
|---|---|---|
| nacos（standalone） | 注册中心 + 配置中心 | 8848、9848 |
| redis | 网关限流 | 6379 |
| zipkin | 链路追踪（L2-06 才需要） | 9411 |

建议的应用端口：gateway 8080；provider 从 8081 开始；consumer 从 8091 开始。在根 README 中列出端口表。

L3 中的手写模块**不依赖 docker**，单独运行 main 方法或测试就能看到效果。
