---
name: "check_ruleset_community"
description: "检查 ruleset 文件中的域名是否已存在于 domain-list-community，并判断分组是否正确。当用户要求核对规则重复、检查域名归属分组、或对比社区规则库时调用。"
---

# Check Ruleset Community

对比 `ruleset/` 下的 Clash 规则文件与 `domain-list-community` 社区域名库，检查每条域名规则是否已存在、归属分组是否合理，并输出统计报告。

## 项目路径

路径一律用相对写法，不写死绝对路径；以当前工作目录（本项目根目录）为基准：

- 规则目录：`ruleset/`（相对项目根目录，`.list` 文件，Clash 规则格式）
- 对比库：`domain-list-community/data/`——即 domain-list-community 仓库下的 `data/` 目录。该仓库通常与本项目**并列存放**（同级目录），请按实际检出位置定位；若不确定，可在项目根目录附近查找名为 `domain-list-community` 的目录。
  - 每个分类是一个**无扩展名的小写文件名**，内容为纯域名列表

## 数据源格式说明

### ruleset 文件（Clash 格式）
```
DOMAIN-SUFFIX,example.com   # 后缀匹配
DOMAIN-KEYWORD,keyword      # 关键词匹配
DOMAIN,example.com          # 完全匹配
IP-CIDR,1.2.3.0/24,no-resolve  # IP 段
URL-REGEX,^https?://...     # 正则
```
以 `#` 开头的行是注释，跳过。

### domain-list-community（纯域名格式）
每个分类文件每行一个域名，支持特殊语法：
- `include:xxx` — 引用其他分类
- `full:xxx.domain` — 仅完全匹配该完整域名
- `domain @cn` / `@ads` — 带属性标签（@cn 表示国内域名，@ads 表示广告）
- 纯域名 = 匹配该域名及其所有子域（等价于 DOMAIN-SUFFIX）

## 工作流程

0. **更新两个仓库到远程最新**（每次运行前必做）：
   - 在本项目根目录执行 `git pull`
   - 在 domain-list-community 仓库目录执行 `git pull`
   > 若 pull 因本地改动冲突失败：不要强推或丢弃本地改动，先在对应仓库执行 `git status` 查看冲突文件，将本地对 ruleset 的修改与远程合并后继续
1. **读取规则文件**：读取 `ruleset/` 下所有 `.list` 文件，跳过 `AutoSelect.list`、`NodeSelect.list` 等仅含注释的预留文件
2. **提取域名**：解析每条规则，记录「规则类型 + 匹配值 + 所属文件」，IP-CIDR 和 URL-REGEX 单独归类
3. **逐条对比**：对每个 `DOMAIN-SUFFIX` / `DOMAIN` / `DOMAIN-KEYWORD`，在 `domain-list-community/data/` 下搜索是否已存在
   - `DOMAIN-SUFFIX,example.com`：检查是否有分类文件包含 `example.com` 或 `full:example.com` 或其父域
   - `DOMAIN-KEYWORD,xxx`：检查分类文件中是否含该关键词的域名
   - `IP-CIDR`：domain-list-community 不收录 IP，标记为「不适用」
   - `URL-REGEX`：超出 domain-list-community 收录范围，标记为「不适用」
4. **判断分组**：对已存在的域名，核对 DC 中所在分类是否与规则文件意图一致（如规则文件名为 HK，但域名在 `cloudflare` 分类 → 分组不匹配）
5. **输出报告**：按下方格式汇报

## 输出报告格式

报告必须包含以下四部分：

### 1. ✅ 已存在且分组正确
| 规则文件 | 域名 | DC 中的分组 |
|:---|:---|:---|

### 2. ⚠️ 已存在但分组不匹配
| 规则文件 | 域名 | 你的分组 | DC 中的分组 | 建议 |
|:---|:---|:---|:---|:---|

### 3. ❌ 未在 domain-list-community 中找到
按文件列出，标注该域名的类型（如直播 CDN、第三方服务等），说明大概率不会被社区库收录、保留在 suppl 文件即可

### 4. 📋 不适用条目
列出所有 IP-CIDR / URL-REGEX / 纯 KEYWORD 泛规则，说明 domain-list-community 不覆盖此类条目

最后用一句话总结主要问题（分组错误、社区未覆盖的独有域名等）。

## 规则

- 对比以 `data/` 目录实际内容为准，注意分类文件名全小写（如 `twitch`、`pbs`、`litv`）
- 判断分组是否合理时，参考 DC 分类名与规则文件名的语义对应（如 HK ↔ `cabletv`/`rthk` 等香港服务；TW ↔ `litv`/`ftv`/`hinet`）
- 对 `include:xxx` 引用链，需展开到实际域名后再判断存在性
- `@cn` / `@ads` 标签不影响存在性判断
- 除第 0 步拉取更新外，不改动任何文件，仅输出分析报告
