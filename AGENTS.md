# AGENTS.md — HowToLiveBetterSkill

多 Agent 分发版 skill 项目：把《高性价比人生指南》（上游 github.com/eternity4719/HowToLiveBetter，CC-BY-4.0）的规则逻辑封装成所有支持 Agent Skills 标准的 Agent 都能装的 skill，名 `how-to-live-better`。远程：git@github.com:dllen/HowToLiveBetterSkill.git（main）。

## 布局

```
skills/how-to-live-better/SKILL.md   # 唯一规则文件，所有 Agent 共用，不维护多份
upstream/                            # git submodule：上游书仓库，同步/离线安装用
install.sh                            # 唯一脚本：安装/更新/卸载 skill 和正文缓存
README.md                             # 面向用户的安装说明 + 署名（CC-BY-4.0 义务）
LICENSE                               # 双轨：skills/ 文档 CC-BY-4.0（沿袭上游），脚本 MIT
```

无 package.json / CI / 测试框架——纯 bash + markdown 项目。

## 命令（均已在模拟 HOME 下实测）

```bash
./install.sh                 # 自动检测 Agent 并安装 + 克隆书正文到缓存
./install.sh --all           # 不检测全装；--no-book 跳过克隆；可与 --all 组合
./install.sh --list          # 列出支持目标及检测结果
./install.sh --uninstall     # 移除所有安装 + 正文缓存
# 测试安装脚本的标准做法（不污染真实 HOME）：
FAKEHOME=$(mktemp -d); FAKECACHE=$(mktemp -d); mkdir -p "$FAKEHOME/.hermes"
HOME="$FAKEHOME" XDG_CACHE_HOME="$FAKECACHE" ./install.sh
```

## 约定（代码里实际遵守的）

- **单文件原则**：SKILL.md 是唯一规则文件，所有 Agent 共用。改逻辑只改它，README 里只放安装/署名信息。
- **改编边界**：SKILL.md 逻辑骨架与上游 `upstream/skills/life-decision-guide/SKILL.md` 保持一致，改动只许落在工具层和路径。同步上游：`git -C upstream pull`，对照 `upstream/skills/life-decision-guide/SKILL.md` 的 diff 改动，同步后更新 README「署名与改编说明」里的同步日期（CC-BY-4.0 要求注明改编和版本日期）。
- **安装策略**：实体文件装到通用目录 `~/.agents/skills/<name>`（Codex/Cursor/Gemini CLI/Copilot/OpenCode 都读），其余 Agent 目录建符号链接指过去；检测依据是各 Agent 配置目录是否存在（`~/.claude`、`~/.hermes` 等）。
- **正文缓存**：`${XDG_CACHE_HOME:-~/.cache}/how-to-live-better/repo`。install.sh 优先从本地 `upstream/` 子模块克隆（离线可装），子模块未检出才回退在线浅克隆；从子模块克隆后必须把缓存的 origin 重设回上游 URL（`remote set-url`），否则后续 pull 会打到本地路径。运行时距上次 pull 超 24h 才更新；离线/拉取失败用旧缓存并如实说明，**禁止凭模型记忆补书的内容**。
- **frontmatter**：description 中文、含核心触发词（自动触发靠它）、≤80 字符、含中文冒号时整段用引号包。
- 文档与脚本注释一律简体中文。
- 提交用 `git -c user.name="dllen" -c user.email="dllen@users.noreply.github.com"`，commit message 中文一句话。

## 坑（都实际踩过）

- **bash `set -u` + 全角标点**：`echo "$VAR："` 变量名紧跟全角字符（：。（，）时多字节字符被并进变量名，报 `unbound variable`。变量后接非 ASCII 字符一律写 `${VAR}`。改完 install.sh 后扫一遍：
  `perl -ne 'print "$.: $_" if /\$[A-Za-z_][A-Za-z_0-9]*(?![}\/\w":.,])[^\x00-\x7F]/' install.sh`
- **`git clone` 不产生 FETCH_HEAD**：用 `.git/FETCH_HEAD` mtime 判断缓存新鲜度时，clone 后必须 `touch` 一个，否则下次永远误判过期、每次都 pull。
- **交付前 grep 占位符**：README 里的 clone URL 曾是 `<你的用户名>` 占位符；改动 README 后 `grep -rn '你的用户名' .` 确认无残留。
- **install.sh 的每条路径都要在模拟 HOME 实测**（含 `--all`/`--uninstall`/更新分支），不许交付没跑过的命令块。
