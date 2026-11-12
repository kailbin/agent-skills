# Stack：Python

学习 Python 生态的技术（FastAPI、LangChain、数据处理等）时使用。读者是 Java 开发，要随时用 Java 的概念做类比。

> 这份 stack 还没有经过实际项目的检验。第一次使用后，按 SKILL.md 第 7 步把经验沉淀回来。

## 版本基线

- Python：使用本机已安装的最新稳定版（3.12+），在 `pyproject.toml` 的 `requires-python` 中声明。
- 包管理：**uv**（类比 Maven：依赖管理 + 虚拟环境 + 运行），用 `uv.lock` 锁定版本（类比依赖树完全固定）。
  本机没有 uv 时，退回到 `python -m venv` + `pip`，并在 README 中说明。
- 版本按 research.md 从 PyPI 查询。

## 项目结构

用 uv 的 **workspace** 组织多模块（类比 Maven 的聚合 POM）：

```
<project>/
├── pyproject.toml              # 根：[tool.uv.workspace] members = ["common", "level*/*"]
├── uv.lock
├── common/                     # 公共代码，其他模块通过 workspace 依赖引用
│   ├── pyproject.toml
│   └── src/<prefix>_common/
├── level1-basic/
│   └── 01-<topic>/
│       ├── pyproject.toml      # name = "<prefix>-l1-01-<topic>"
│       ├── src/<prefix>_l1_01_<topic>/
│       └── tests/
└── ...
```

- 包名用下划线，项目名用连字符；每个模块用 `src/` 布局，避免意外导入。
- 依赖 common：`dependencies = ["<prefix>-common"]` + `[tool.uv.sources] <prefix>-common = { workspace = true }`。

## 与 Java 的类比（写进根 README）

| Python | Java |
|---|---|
| uv / pyproject.toml / uv.lock | Maven / pom.xml / 固定版本的依赖树 |
| 虚拟环境 .venv | 项目独立的 classpath |
| 类型注解 + mypy / pyright | 编译期类型检查（但运行时不强制） |
| async / await + asyncio | 虚拟线程 / Reactor（单线程事件循环，更接近 Netty） |
| pydantic | Bean Validation + Jackson |
| pytest fixture | JUnit 扩展 / Spring 测试上下文 |
| 装饰器 | AOP 切面 / 注解处理 |

## 可运行入口

| 场景 | 入口 |
|---|---|
| 脚本示例 | `uv run --package <module> python -m <package>.main` |
| 原理实验、对照测试 | pytest，测试函数名用中文描述规则 |
| Web 服务 | FastAPI + uvicorn，提供 `requests.http` |
| 交互式探索（可选） | 只在数据、AI 方向使用 notebook，并且要能用 `uv run` 执行 |

## 自检

```bash
uv sync --all-packages        # 安装全部模块
uv run pytest                 # 全部测试
uv run ruff check .           # 静态检查（可选）
```
