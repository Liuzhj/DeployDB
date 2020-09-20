## PostgreSQL高可用方案

使用Patroni + ETCD + HAProxy实现PostgreSQL的高可用，此方案优点容易维护，实现数据库回切。

### 先决条件

- Pypi源，或者离线的patroni安装包及其依赖包
- Yum源，或者离线的etcd安装包
- Ntp时钟同步
- Firewall关闭
- Selinux禁用
- CetnOS 7.4.1708
- PostgreSQL 10
- 服务器有默认网关

### 服务器规划

PostgreSQL 为一主两从，主节点可提供读写，从节点提供只读

ETCD三台服务器与PostgreSQL复用了，实际部署中建议有三台低配服务器用做ETCD集群

HAProxy提供PostgreSQL集群的切换和读写分离（通过区分端口实现，需要业务层适配），实际部署中要考虑HAProxy的高可用

|            角色             |      IP       |
| :-------------------------: | :-----------: |
| PostgreSQL + Patroni + ETCD | 192.168.10.85 |
| PostgreSQL + Patroni+ ETCD  | 192.168.10.64 |
| PostgreSQL + Patroni+ ETCD  | 192.168.10.72 |
|           HAProxy           | 192.168.10.69 |

### 部署

- 修改Inventory文件

```shell
[pg_master]
192.168.10.85

[pg_slave]
192.168.10.64
192.168.10.72

[etcd_cluster]
192.168.10.85
192.168.10.64
192.168.10.72

[pg_cluster:children]
pg_master
pg_slave

[patroni:children]
pg_cluster
etcd_cluster

[patroni:vars]
ansible_user=root
ansible_ssh_pass=password  # 受控机root用户口令

```

- 修改group_vars/all 可配置参数

```yaml
# postgresql
pg_data_dir: /data/pg_data
pg_home: /usr/pgsql-10
pg_bin_dir: '{{ pg_home }}/bin'
postgresql_encoding: UTF8

# pypi
pypi_addr: 192.168.10.41
pypi_user: test
pypi_passwd: test
pypi_repo_name: moonshot
pypi_url: 'http://{{ pypi_user }}:{{ pypi_passwd }}@{{ pypi_addr }}:8081/repository/{{ pypi_repo_name }}'
pip_index: '{{ pypi_url }}/pypi'
pip_index_url: '{{ pypi_url }}/simple'

# patroni
patroni_namespace: db
patroni_scope: postgres
patroin_name: pg_ha

# etcd
etcd_name: etcd
etcd_port: 2379
etcd_initial_port: 2380
etcd_initial_cluster_token: etcd_cluster
etcd_data_dir: /var/lib/etcd/default.etcd
```

- 开始安装

```yaml
ansible-playbook -i hosts deploy-patroni.yml
```

- 验证ETCD集群

```shell
# 查看etcd集群状态
etcdctl --endpoints "http://192.168.10.85:2379" cluster-health

# 查看etcd集群成员及leader
etcdctl --endpoints "http://192.168.10.85:2379" member list

# 查看etcd服务状态
systemctl status etcd
```

- 验证Patroni服务

```shell
# Load postgres用户环境变量，查看postgres集群状态
source  /var/lib/pgsql/.bash_profile
patronictl -d etcd://192.168.10.85:2379 list postgres

# 查看Patroni服务状态
systemctl status patroni
```

- 配置HAProxy

  执行完Ansible脚本后，在主控机会生成配置文件`/tmp/haproxy.cfg`，需要将配置文件中的内容追加到现有HAProxy集群的配置文件中，并重启haproxy服务生效。

- 使用客户端工具进行验证

  Navicat或通过psql命令连接HAProxy集群的VIP验证数据库服务是否正常可用

### 维护 

- PostgreSQL集群，[参考链接](https://patroni.readthedocs.io/en/latest/)
- ETCD [参考链接](https://github.com/etcd-io/etcd)

```shell
# PostgreSQL集群的切换
patronictl -d etcd://192.168.10.85:2379 switchover postgres

# 详见patronictl帮助
patronictl --help
Usage: patronictl [OPTIONS] COMMAND [ARGS]...

Options:
  -c, --config-file TEXT  Configuration file
  -d, --dcs TEXT          Use this DCS
  -k, --insecure          Allow connections to SSL sites without certs
  --help                  Show this message and exit.

Commands:
  configure    Create configuration file
  dsn          Generate a dsn for the provided member, defaults to a dsn of...
  edit-config  Edit cluster configuration
  failover     Failover to a replica
  flush        Flush scheduled events
  list         List the Patroni members for a given Patroni
  pause        Disable auto failover
  query        Query a Patroni PostgreSQL member
  reinit       Reinitialize cluster member
  reload       Reload cluster member configuration
  remove       Remove cluster from DCS
  restart      Restart cluster member
  resume       Resume auto failover
  scaffold     Create a structure for the cluster in DCS
  show-config  Show cluster configuration
  switchover   Switchover to a replica
  version      Output version of patronictl command or a running Patroni...
```