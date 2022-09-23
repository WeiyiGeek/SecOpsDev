#### :hammer_and_wrench: CentOS 7 系统安全加固工具

描述: 本工具集主要针对于 CentOS 7 操作系统进行安全加固以及系统初始化操作。

欢迎访问作者个人主页与博客，以及关注微信公众号【WeiyiGeek】，将会分享更多工具。

个人主页: https://www.weiyigeek.top

博客地址：https://blog.weiyigeek.top

学习交流群：https://weiyigeek.top/visit.html



:atom_symbol:**脚本说明:**  请手动按需调用进行加固。

```
## 名称: err 、info 、warning
## 用途：全局Log信息打印函数
## 参数: $@

## 名称: os::Network
## 用途: 操作系统网络配置相关脚本包括(IP地址修改)
## 参数: 无

## 名称: os::Software
## 用途: 操作系统软件包管理及更新源配置相关脚本
## 参数: 无

## 名称: os::TimedataZone
## 用途: 操作系统系统时间时区配置相关脚本
## 参数: 无

## 名称: os::Security
## 用途: 操作系统安全加固配置脚本(符合等保要求-三级要求)
## 参数: 无

## 名称: os::Operation
## 用途: 操作系统安全运维设置相关脚本
## 参数: 无

## 名称: os::DisableService
## 用途: 禁用与设置操作系统中某些服务(需要根据实际环境进行)
## 参数: 无

## 名称: os::optimizationn
## 用途: 操作系统优化设置(内核参数)
## 参数: 无

## 名称: os::Swap
## 用途: Liunx 系统创建SWAP交换分区(默认2G)
## 参数: $1(几G)

## 名称: software::Java
## 用途: java 环境安装与设置
## 参数: 无

## 名称: disk::Lvsmanager
## 用途: CentOS7 操作系统磁盘 LVS 逻辑卷添加与配置(扩容流程)
## 参数: 无
```