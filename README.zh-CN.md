<div align="center">

# 🌿 MuType

**通过打字进入“无”的境界。平静节奏、低干扰、稳定流畅。**

[![English](https://img.shields.io/badge/README-English-blue)](README.md) [![MELPA](https://melpa.org/packages/mutype-badge.svg)](https://melpa.org/packages/mutype) ![Requires: Emacs 25.1+](https://img.shields.io/badge/Requires-Emacs%2025.1%2B-7F5AB6) [![License: MIT](https://img.shields.io/badge/License-MIT-yellow)](LICENSE)

</div>

---

## 📖 MuType 是什么？

> *菩提本无树，明镜亦非台；*  
> *本来无一物，何处惹尘埃？*  
> 
> — 六祖慧能

MuType 中的 **“Mu”** 源于中文**“无/無”**，常见含义是“没有/不”。

在禅宗语境中，“无”不只是“没有”，更是指向放下分别与执著，回到当下的清明。MuType 用这个名字提醒自己：**专注于当前字符，保持平静节奏，让错误自然过去。**

MuType 是一个极简的 Emacs 打字练习插件，帮助你保持平静而稳定的节奏：专注于当前字符，持续推进。

MuType 提供两种练习模式：
- `flow`：错误不会阻塞前进。
- `precision`：必须输入正确字符才会前进。

## 📸 演示

<div align="center">
  <img src="docs/screenshots/mutype-session.png" alt="MuType session" />
</div>

## ✨ 特性

- 🧘 **禅宗哲学**：极简设计，专注当下，提供 `flow`（心流）和 `precision`（精准）模式。
- 📊 **多维度统计**：HUD 位于 mode line，实时显示计时、进度、准确率及状态分区（`·`、`:`、`*`、`●`）。
- 📚 **多元练习素材**：
  - **经典文学**：狄更斯、奥斯汀、莎士比亚等英文名篇。
  - **中华瑰宝**：《道德经》、唐诗宋词、现代散文。
  - **编程实战**：Elisp、Python 等常用代码片段。
- 🚀 **即时报告**：练习结束自动生成详细分析报告。

## 🚀 安装

### MELPA（推荐）

MuType 现已上线 MELPA，可用以下方式安装：

```elisp
M-x package-install RET mutype RET
```

<details>
<summary>若尚未启用 MELPA，请展开查看配置</summary>

```elisp
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
```
</details>

### 手动（load-path）

```elisp
(add-to-list 'load-path "/path/to/mutype")
(require 'mutype)
```

### straight.el（可选）

```elisp
(use-package mutype
  :straight (mutype :type git :host github :repo "suxiaogang223/mutype")
  :commands (mutype-mode mutype-mode-custom))
```

## 🎮 开始

- `M-x mutype-mode` 用默认配置快速开始。
- `C-u M-x mutype-mode` 或 `M-x mutype-mode-custom` 可选择模式/时长/来源。

## ⌨️ 练习中

MuType 的 HUD 位于 mode line，包含：
- **分区符号**（`·`、`:`、`*`、`●`）
- **计时与状态**（`running`/`paused`）
- **进度、准确率、当前来源标签**（可点击）

### 常用按键与命令

| 按键 / 命令 | 动作 |
| :--- | :--- |
| `C-c C-p` | 暂停 / 继续 |
| `C-c C-q` | 结束练习 |
| `C-c C-n` | 下一来源（重启） |
| `C-c C-b` | 上一来源（重启） |
| `M-x mutype-select-source` | 选择来源（重启） |
| `M-x mutype-report-last-session` | 打开上一次报告 |

> **注意**：输入始终按 MuType 的顺序索引推进。若移动 point，输入会自动回到当前训练位置。

## 📝 文本来源

MuType 只读取包内自带的纯文本目录 `sources/*.txt`。

如需新增或调整练习文本，可在 `sources/` 下编辑或新增 `.txt` 文件。由于该目录属于安装包的一部分，升级可能覆盖本地改动——**建议备份自定义文本。**

## ⚙️ 自定义

在你的 init 文件中加入类似配置：

```elisp
(setq mutype-default-mode 'flow
      mutype-default-duration-minutes 15
      mutype-enable-guidance-text t
      mutype-prompt-on-start nil)
```

## 📈 报告

结束练习或达到时间上限时，MuType 会打开报告缓冲区。可用 `M-x mutype-report-last-session` 重新打开上一次报告。

## 🛠️ 开发（可选）

常用命令：
- **加载检查**：`emacs --batch -Q -L . --eval "(progn (load \"mutype.el\") (message \"ok\"))"`
- **字节编译**：`emacs --batch -Q --eval "(byte-compile-file \"mutype.el\")"`
- **运行测试**：`emacs --batch -Q -L . -L test -l test/mutype-test.el -f ert-run-tests-batch-and-exit`

## 📜 许可证

MuType 使用 MIT 许可证。详见 [LICENSE](LICENSE)。
