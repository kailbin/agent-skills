# AWS 学习项目

> 先读 java-maven.md，本文件只补充 AWS 特有的内容。用 Java 学习 AWS 服务，重点放在后端开发最常用的服务上。

## 1. 版本基线

- **AWS SDK for Java 2.x**（通过 `software.amazon.awssdk:bom` 管理版本）。SDK v1 已停止维护，只在【对比】中提及。
- 需要和 Spring 集成的模块使用 **Spring Cloud AWS**（`io.awspring.cloud`），生成前核对它和 Spring Boot 的兼容版本。
- IaC（L4）：默认用 **AWS CDK（Java）**，备选 Terraform。

## 2. 运行环境：默认本地模拟，不产生费用

| 方式 | 说明 |
|---|---|
| **默认：LocalStack** | docker-compose 启动，一个端点模拟多个服务。生成前核对 LocalStack 当前的版本和授权要求（是否需要 auth token、哪些服务免费）；有限制时改用下面的单服务模拟器 |
| 单服务模拟器 | S3 → MinIO；SQS → ElasticMQ；DynamoDB → DynamoDB Local（AWS 官方提供） |
| 测试 | Testcontainers（`localstack` 模块或上面的单服务镜像） |
| 真实 AWS | 只有用户明确要求时才使用。README 顶部提示**可能产生费用**，提供 `cleanup.sh`，并使用独立的 profile |

代码要求：

- 客户端统一通过 `endpointOverride` + 配置项切换本地或真实环境，**业务代码不改动**。
  把这个工厂放到 common 模块，并在注释中讲清楚凭证链和 region 的解析顺序。
- 凭证：本地环境使用 `test/test` 这类假值；**任何真实凭证都不能写进代码或配置文件**，真实环境只用 profile 或环境变量。
- 资源（bucket、queue、table）由启动脚本或代码幂等创建，用户不需要手动去控制台操作。

## 3. 必学知识点

### L1 入门

| 模块 | 内容 | 学完能回答 |
|---|---|---|
| 01-sdk-client-basics | 客户端创建、凭证提供链、region、同步 vs 异步客户端 | SDK 是按什么顺序查找凭证的？客户端为什么要复用？ |
| 02-s3-basics | 创建 bucket、上传、下载、列举、删除 | S3 的「目录」其实是什么？ |
| 03-sqs-basics | 发送、接收、删除消息，长轮询 | 消息被接收后为什么还要再删除一次？ |
| 04-sns-fanout | SNS → 多个 SQS 订阅的扇出 | SNS 和 SQS 各自的定位是什么？ |
| 05-dynamodb-basics | 建表、PutItem、GetItem、Query，使用 Enhanced Client | 分区键和排序键分别起什么作用？ |

### L2 进阶

| 模块 | 内容 |
|---|---|
| 01-s3-advanced | 预签名 URL、分段上传、S3 Transfer Manager、事件通知 |
| 02-sqs-reliability | 可见性超时、死信队列（DLQ）、FIFO 队列与去重、批量操作 |
| 03-dynamodb-modeling | 单表设计、GSI、条件写入（乐观锁）、事务写入 |
| 04-spring-cloud-aws | `@SqsListener`、S3 资源抽象、Parameter Store / Secrets Manager 配置 |
| 05-lambda-java | Java Handler、本地调用、处理 SQS / S3 事件 |
| 06-eventbridge | 事件总线、规则匹配、和 SNS 的区别 |

### L3 原理（重点）

| 模块 | 内容 |
|---|---|
| 01-sdk-pipeline | SDK v2 的请求执行管线：拦截器（`ExecutionInterceptor`）、重试策略与退避、超时分层，用自定义拦截器打印每个阶段 |
| 02-mini-sigv4 | **手写** SigV4 签名，并与 SDK 的签名结果比对，理解 AWS API 的鉴权方式 |
| 03-sqs-delivery-semantics | 用实验说明「至少一次投递」：模拟消费者崩溃、可见性超时到期后重复投递，再手写幂等消费 |
| 04-dynamodb-partitioning | 用实验和文档讲解分区、热点键、容量模式；手写写分片（write sharding） |
| 05-lambda-lifecycle | 冷启动、执行环境复用、SnapStart 原理；对比 Spring Boot 在 Lambda 中的启动开销 |

### L4 生产（可选）

- IAM 最小权限：为每个模块写出所需的 policy，讲解 Role 和 AssumeRole
- CDK（Java）定义上面用到的资源，`cdk synth` 查看 CloudFormation 输出
- 可观测性：CloudWatch 指标、日志、告警，X-Ray / OpenTelemetry
- 成本：各服务的计费维度，以及示例中哪些做法在生产环境会很贵
- 多账号与环境隔离的组织方式（放在 docs 中）

## 4. 注释与原理讲解重点

- **对比用户熟悉的中间件**：SQS ↔ RocketMQ / Kafka（没有分区和消费位点，靠可见性超时实现可靠性）；
  DynamoDB ↔ MySQL / Redis（为访问模式建模，不是为实体建模）；S3 ↔ MinIO / OSS。
- **托管服务的取舍**：每个服务都要说明「AWS 帮你做了什么，代价是什么」。
- **最终一致性**：哪些操作是最终一致的，代码里怎样处理。
- 每个 API 调用旁边用 `// 【生产】` 标注：需要哪个 IAM 权限，有什么限额（Quota）。

## 5. 常见坑

1. region 没有配置，或和资源所在的 region 不一致，导致找不到资源。
2. 本地 endpoint 下 S3 需要开启 path-style 访问，否则 bucket 域名解析失败。
3. SQS 消息处理完没有删除，可见性超时后被重复消费。
4. DynamoDB Scan 用在大表上，性能和费用都会出问题；应改用 Query + GSI。
5. 每次请求都新建 SDK 客户端，导致连接池和线程资源泄漏。
6. Lambda 中在 handler 内初始化客户端，没有利用执行环境复用。

## 6. docker-compose 默认内容

| 服务 | 用途 | 端口 |
|---|---|---|
| localstack | 模拟 S3、SQS、SNS、DynamoDB、Lambda、EventBridge 等 | 4566 |
| （备选）minio / elasticmq / dynamodb-local | LocalStack 不可用时替代 | 9000 / 9324 / 8000 |

提供 `init/` 初始化脚本（LocalStack 的 ready hook 或 awslocal 命令），启动时自动创建示例资源。
