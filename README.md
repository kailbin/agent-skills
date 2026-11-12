# agent-skills

积累个人 AI Agent Skill。所有 skill 以 `kai-` 开头，放在 `skills/` 目录下。

## 安装

```bash
# 列出仓库中的 skill
npx skills add kailbin/agent-skills --list

# 安装指定 skill
npx skills add kailbin/agent-skills --skill kai-learn-by-demo

# 更新已安装的 skill
npx skills update
```

## Skill 清单

| Skill | 用途 | 已支持的技术方向 |
|---|---|---|
| [kai-learn-by-demo](skills/kai-learn-by-demo/SKILL.md) | 学习新技术时，生成注释详尽、按难度分层的示例项目 | Spring Cloud、AWS（其他技术走通用规则） |

## 贡献

仓库规则见 [AGENTS.md](AGENTS.md)。提交前运行：

```bash
./scripts/validate.sh
```
