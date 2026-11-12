# agent-skills 仓库规则

本仓库用来积累个人 AI Agent Skill，通过 `npx skills` 安装与更新。
新增或修改 skill 时（无论人还是 AI），都必须遵守以下规则。

## 目录约定

```
skills/
└── kai-<name>/              # 目录名 = SKILL.md 中的 name
    ├── SKILL.md             # 必需：frontmatter + 主流程
    ├── references/          # 可选：按需加载的详细说明（一个主题一个文件）
    ├── assets/              # 可选：模板、示例文件
    └── scripts/             # 可选：skill 运行时会用到的脚本
scripts/                     # 仓库维护脚本（不随 skill 安装）
```

## 命名规则

- 所有 skill 必须以 `kai-` 开头，只用小写字母、数字和 `-`，总长 ≤ 64。
- `SKILL.md` 的 frontmatter `name` 必须与目录名完全一致。
- reference 文件用小写 kebab-case，可以按类别放在子目录中，如 `references/<类别>/<主题>.md`。

## 编写规则

1. **自包含**：每个 skill 独立安装，不得引用其他 skill 目录或仓库根目录下的文件。
   需要共用的内容，就在各个 skill 里各放一份。
2. **渐进加载**：`SKILL.md` 只放主流程和路由表，尽量控制在 300 行内；细节放进 `references/`，
   并在 `SKILL.md` 中写明「什么情况下读哪个文件」。
3. **description 是触发器**：frontmatter 的 `description` 要写清楚「做什么 + 什么时候用」，
   中英文关键词都要有，≤ 1024 字符。
4. **同类 reference 结构一致**：同一个 skill 下的同类 reference 要按统一的章节结构来写，
   方便对比，也方便 AI 照着补充新的。
5. **泛化，不要过拟合**：reference 按「类别 / 维度」组织，不为某一个具体对象单独写文件。
   具体对象的细节在运行时获取；遇到不属于任何已有类别的情况，新增一个类别，而不是新增一个针对单个对象的文件。
6. **知识沉淀**：本仓库是个人知识体系，会随着使用逐步完善。使用 skill 时发现的经验，只把**可以泛化的部分**合入 reference，
   并在 SKILL.md 的变更记录中注明来源（例如「来自 xx 的试用反馈」）。尚未经过实际使用检验的 reference，在开头注明。
7. **会过期的信息不写死**：版本号、价格、API 名称这类信息，写「怎样获取」，而不是写具体的值。
8. 文档用中文，技术术语保留英文。

## 修改后

- 运行 `scripts/validate.sh` 校验。
- 更新根目录 `README.md` 中的 skill 清单。
- 修改了某个 skill 的行为时，在它的 `SKILL.md` 末尾的「变更记录」中加一行。
