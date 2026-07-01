---
name: "update_dns_list"
description: "从 AdGuard DNS 提供商页面提取非中国大陆的 DoH 域名，全量同步到 ruleset/DNS.list（增删同步）。当用户要求更新 DNS 列表或同步 AdGuard DNS 提供商时调用。"
---

# Update DNS List

从 [AdGuard DNS 已知提供商页面](https://adguard-dns.io/kb/zh-CN/general/dns-providers/) 中，提取所有非中国大陆的 DoH（DNS-over-HTTPS）服务的域名，全量同步到 `ruleset/DNS.list` 文件中（增删同步，以网页为准）。

## 项目路径

- 项目根目录：`/Users/dafan/Workspace/openclash-rules`
- 目标文件：`ruleset/DNS.list`（相对项目根目录）

## 工作流程

1. **获取页面内容**：通过 WebFetch 获取 `https://adguard-dns.io/kb/zh-CN/general/dns-providers/` 页面内容
2. **提取 DoH 域名**：从页面中匹配 `DNS-over-HTTPS` 行，提取 `https://` 后面的**主机名（hostname）**部分，忽略路径
3. **过滤中国大陆域名**：排除以下中国大陆 DNS 服务：
   - `dns.alidns.com`
   - `dns.pub`
   - `doh.18bit.cn`
   - `doh.360.cn`
   - `sm2.doh.pub`
   > 注意：中国大陆域名列表需要手动维护，如发现新的中国大陆 DoH 服务，请更新此处的过滤列表
4. **读取旧文件**：读取 `ruleset/DNS.list` 中已有的 `DOMAIN-SUFFIX` 条目，记为旧列表
5. **对比计算**：将旧列表与网页提取的域名列表做 diff，计算新增数和删除数
6. **写入文件**：以网页提取的域名列表为准，将域名以 `DOMAIN-SUFFIX,<domain>` 格式按字母排序全量写入文件（保留文件头 `# DNS`）——网页上没有的域名同步删除

## 规则

- 以网页内容为唯一数据源做全量同步，网页上没有的域名同步从文件中移除
- 不使用泛域名，全部使用精确的 `DOMAIN-SUFFIX,<domain>` 格式
- 按二级域名排序：对于有三级及以上子域的域名（如 `dns.quad9.net`），去掉第一个子域名后排序（即按 `quad9.net` 排序）；对于只有两级的域名（如 `dnsforge.de`、`v.recipes`），按自身域名排序。相同二级域名的再按完整域名排序

## 执行结果汇报

每次执行完成后，必须汇报以下统计信息：

| 指标 | 说明 |
|------|------|
| 国外 DoH 域名数 | 写入文件的总域名数（已排除中国大陆） |
| 中国大陆 DoH 域名数 | 被排除的中国大陆域名数量 |
| 本次新增数 | 相比上次文件新增的域名数量 |
| 本次删除数 | 相比上次文件删除的域名数量 |
