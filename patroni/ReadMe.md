## PostgreSQL 高可用方案

使用 Patroni + ETCD + HAProxy 实现 PostgreSQL 的高可用，此方案优点容易维护，支持数据库回切。

![](https://raw.githubusercontent.com/Liuzhj/picrepo/master/img/deploy_patroni.gif)

### 先决条件

- Pypi 源，或者离线的 patroni 安装包及其依赖包
- Yum 源，或者离线的 etcd 安装包
- Ntp 时钟同步
- Firewall 关闭
- Selinux 禁用
- CetnOS 7.4.1708

### 服务器规划

数据库服务器至少需要两台，一主一备。

ETCD 集群需要三台服务器，ETCD 对网络及磁盘性能要求较高，可支持多个 PostgreSQL 集群的配置中心。

HAProxy 服务器需要两台，使用 Keepalived 实现高可用，提供 PostgreSQL 集群的连接代理及故障检测，可接入多个 PostgreSQL 集群。

---

测试环境，最少两台机器即可完成 PostgreSQL 集群部署

- 两台数据库服务器 + Patroni
- 其中一台数据库服务器上安装单节点 ETCD
- HAProxy 省略

此项目暂不支持安装单节点 ETCD，所以最少需要三个节点。

|            角色             |      IP       |
| :-------------------------: | :-----------: |
| PostgreSQL + Patroni + ETCD | 192.168.10.85 |
| PostgreSQL + Patroni+ ETCD  | 192.168.10.64 |
|            ETCD             | 192.168.10.72 |

### 部署流程

- 修改 Inventory 文件

  ```
  patroni/hosts
  ```

- 修改 group_vars/all 可配置参数

  ```
  patroni/group_vars/all
  ```

- 执行安装

  ```
  ansible-playbook -i hosts deploy-patroni.yml
  ```

- 验证ETCD集群

  ```
  # 查看 etcd 集群状态
  etcdctl --endpoints "http://192.168.10.85:2379" cluster-health
  
  # 查看 etcd 集群成员及 leader
  etcdctl --endpoints "http://192.168.10.85:2379" member list
  
  # 查看 etcd 服务状态
  systemctl status etcd
  ```

- 验证Patroni服务

  ```
  # Load postgres 用户环境变量，查看 PostgreSQL 集群状态
  source /var/lib/pgsql/.bash_profile
  patronictl -d etcd://192.168.10.85:2379 list postgres
  
  # 查看 Patroni 服务状态
  systemctl status patroni
  ```

- 配置 HAProxy

  执行完Ansible脚本后，在主控机会生成配置文件`/tmp/haproxy.cfg`，需要将配置文件中的内容追加到现有 HAProxy 集群的配置文件中，并重启 haproxy 服务生效。

- 使用客户端工具进行验证

  Navicat 或通过 psql 命令连接 HAProxy 集群的 VIP 验证数据库服务是否正常可用

### 维护 

- PostgreSQL 集群，[参考链接](https://patroni.readthedocs.io/en/latest/)

- ETCD [参考链接](https://github.com/etcd-io/etcd)

  ```
  # PostgreSQL 集群的切换
  patronictl -d etcd://192.168.10.85:2379 switchover postgres
  ```
