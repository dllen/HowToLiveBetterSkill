# how-to-live-better

让 AI 助手照[《高性价比人生指南》](https://github.com/eternity4719/HowToLiveBetter)回答具体的人生决策：该不该做、值不值、怎么选、出事了先做什么、能领哪笔钱、这么干犯不犯法。

这个 skill 做的事只有一件：**先把相关条目从书里查出来，再照书的算账方式排序回答**，每条注明出自第几节第几条。查不到就说查不到，不凭记忆编数字。

## 快速安装

```bash
git clone --recursive https://github.com/dllen/HowToLiveBetterSkill.git
cd HowToLiveBetterSkill
./install.sh
```

已经用不带 `--recursive` 的方式 clone 了的话，补一句 `git submodule update --init` 即可。`upstream/` 是上游书仓库的子模块：装了它，`install.sh` 装正文时不需要网络；不装也行，脚本会自动回退到在线克隆。

`install.sh` 会自动检测本机装了哪些 Agent，装到对应目录。也支持：

- `./install.sh --all`：不检测，全部目标都装
- `./install.sh --no-book`：跳过正文克隆（可与其它参数组合）
- `./install.sh --list`：列出支持的目标和检测结果
- `./install.sh --uninstall`：从所有目标目录移除（含正文缓存）

## 支持哪些 Agent

skill 本体只有一个 `skills/how-to-live-better/SKILL.md`，遵循 [Agent Skills 开放标准](https://agentskills.io)，所有支持该标准的 Agent 通用，只是安装目录不同：

| Agent | 全局 skill 目录 |
| --- | --- |
| Codex / Cursor / Gemini CLI / GitHub Copilot / OpenCode（通用目录） | `~/.agents/skills/` |
| Claude Code | `~/.claude/skills/` |
| Hermes Agent | `~/.hermes/skills/` |
| Gemini CLI（专属目录） | `~/.gemini/skills/` |
| Cursor（专属目录） | `~/.cursor/skills/` |
| GitHub Copilot（专属目录） | `~/.copilot/skills/` |

实体文件装在通用目录 `~/.agents/skills/how-to-live-better`，其余目录是指向它的符号链接，更新一处即可全部生效。

**手动安装**：把 `skills/how-to-live-better/` 整个目录复制到上表任意一个目录下即可。

## 用法

装好后直接问具体问题就会自动触发，例如：

- 每天通勤两小时值不值？
- 朋友让我替他担保，签不签？
- 被裁员了能领什么钱？
- 有人倒地没了呼吸，先做什么？

也可以显式说「用 how-to-live-better 回答」。

## 正文从哪来

skill 不内嵌书，但**安装时就会把整本书装到缓存目录** `${XDG_CACHE_HOME:-~/.cache}/how-to-live-better/repo`，装完即离线可用。正文来源按优先级：

1. **本地子模块** `upstream/`（上游仓库的 git submodule）——已检出时直接从本地克隆，**整个安装过程不需要网络**；装完后缓存的 origin 仍指向上游，后续更新照常在联网时进行；
2. **在线浅克隆**（约 1.3 MB）——子模块没检出时的回退路径。

更新有两条路径，不冲突：

- **自动**：skill 每次被触发时检查缓存，距上次更新超过 24 小时才 `git pull`；
- **手动**：重跑 `./install.sh` 即更新正文（已存在缓存时自动走 pull）。

离线或拉取失败时照常使用现有缓存，skill 会在答复里注明内容日期。取不到正文时会如实说明，不会凭记忆复述书的内容。

## 索引

安装时还会从正文生成三份速查文件到 `${XDG_CACHE_HOME:-~/.cache}/how-to-live-better/index/`：

- `entries.md`：全部条目的定位索引（编号、标题、钱/时间/毅力成本、收益量级、口径、证据等级）——skill 靠它直接定位条目，不再每次 grep 全书；
- `sections.md`：节目录（这节回答什么问题 → 哪个文件）；
- `algorithm.md`：性价比档位算法（`COST_W` + `e.ratio`，从 `index.html` 抠好）。

索引只用于定位，正文仍以原文为准；正文更新后（install.sh 重跑或 skill 运行时检测到更新）自动重建。索引缺失时 skill 回退到 grep 流程，不影响使用。手动重建：

```bash
bash skills/how-to-live-better/scripts/build-index.sh
```

## 署名与改编说明

- 书的内容：**《高性价比人生指南》**，作者 eternity4719，仓库 <https://github.com/eternity4719/HowToLiveBetter>，许可 [CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/)。
- 本 skill 的规则逻辑改编自上游仓库的 `skills/life-decision-guide/SKILL.md`，**同步日期 2026-10-21**。相对上游的改动：改名为 `how-to-live-better`；正文缓存路径从 `${TMPDIR}` 改为 `${XDG_CACHE_HOME:-~/.cache}` 并加了 24 小时更新检查；工具描述改为跨 Agent 通用表述。规则骨架（安全闸、四样不折算、性价比算法、答复结构）与上游一致。
- 上游更新后，对照上游 `skills/life-decision-guide/SKILL.md` 的 diff 同步即可，改动应只落在工具层和路径。

## 许可

- `skills/` 下的文档内容：[CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/)（沿袭上游许可，见上方署名）。
- `install.sh` 等脚本：MIT。
