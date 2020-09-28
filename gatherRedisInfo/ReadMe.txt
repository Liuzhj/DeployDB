# Gather Redis Info

## 目标

通过收集处理 redis info 中的信息，批量汇总 Redis 状态，达到信息收集和巡检。

## 采集指标

待采集指标可动态调整，收集部分或全部信息

```
host              主机名
ipaddress         ip 地址
redis_version     redis 版本
os                操作系统
arch_bits         操作系统位数
process_id        pid
run_id            redis 服务器的随机标识符
tcp_port          tcp/ip 监听端口
uptime_in_days    自 redis 服务器启动以来，经过的天数
connected_clients 已连接客户端的数量
blocked_clients   正在等待阻塞命令
used_memory_human 内存使用
role              角色
connected_slaves  已连接从库
```

## 采集方式

- 在 Redis 服务器本地通过 redis-cli 登录本地 redis 服务，执行命令

  ```
  redis-cli info > redis_${host}_${ip}.txt
  ```

- 使用 redis-cli 客户端远程登录 redis 服务器，执行命令

  ```
  redis-cli -hxx -pxx -axx info > redis_${host}_${ip}.txt
  ```

## 结果处理

生成的文件名规则 `redis_{host}_{ip}.txt`

```
awk -F: -f redis.awk redis_server* > redisInfo.csv
```

```
host,ipaddress,redis_version,os,arch_bits,process_id,run_id,tcp_port,uptime_in_days,connected_clients,blocked_clients,used_memory_human,role,connected_slaves,
server1,192,3.2.11,Linux 3.10.0-693.el7.x86_64 x86_64,64,3785,18b580a0355771467aff7a2c3a863c9316df4d1c,6379,0,1,0,793.21K,master,0,
server2,192,3.2.12,Linux 3.10.0-693.el7.x86_64 x86_64,64,3785,18b580a0355771467aff7a2c3a863c9316df4d1c,6379,0,1,0,793.21K,master,0,
```

redis.awk

```
#!/usr/bin/env  awk
# awk -F: -f redis.awk redis_host* > redisInfo.csv

function pout(b){
    for(i=1; i<=length(b); ++i){
        printf("%s,", a[b[i]]);
    }
    print ""
}BEGIN{
    header = "host ipaddress redis_version os arch_bits process_id run_id tcp_port uptime_in_days connected_clients blocked_clients used_memory_human role connected_slaves";
    split(header, headers, " ");
    for(i=1; i<=length(headers); ++i){
        printf("%s,", headers[i]);
        a[headers[i]] = "DFT";
        b[i] = headers[i]
    }
    print ""
}filename!=FILENAME{
    if(ARGIND>=2)
        pout(b);
    filename=FILENAME;
    split(filename, name, "[_.]");
    a["host"]=name[2];
    a["ipaddress"]=name[3]
}NF==2 && a[$1]{
    a[$1]=$2
}END{
    pout(b)
}

```
