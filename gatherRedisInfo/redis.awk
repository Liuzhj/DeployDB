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

