OpenClash+MosDNS配合使用，OpenClash前置：
OpenClash劫持DNS转发，nameserver配置为127.0.0.1:5335，fallback留空
MosDNS勾选防泄露，国内DNS留空用运营商的，远程DNS勾选8.8.8.8和1.0.0.1
能防DNS泄露的主要原因是MosDNS分流，同时MosDNS中缓存的都是正常的结果，不会存在Fake-IP，不会因为重启导致部分网站无法访问的情况出现

OpenClash+MosDNS配合使用，MosDNS前置：
MosDNS劫持DNS转发，国内DNS留空使用运营商的，远程DNS配置为127.0.0.1:7874
OpenClash停用DNS转发，nameserver配置为127.0.0.1:5335，fallback配置为DoT或者DoH的国外DNS服务
这样配置时MosDNS会从fallback中拿到Fake-IP，因此最好MosDNS的缓存和OpenClash的Fake-IP缓存都开或者都关，防止重启后无法访问需要代理的网站

IPv6配置：
新版本的OpenClash中即使是访问国内的IPv6网站，也必须开启IPv6的解析（14版本是不需要这样的，参考链接：https://github.com/vernesong/OpenClash/issues/4037#issuecomment-2365445276）
OpenClash+MosDNS搭配使用，并且设置的OpenClash前置，OpenClash开启IPv6解析，MosDNS勾选远程DNS优先IPv4