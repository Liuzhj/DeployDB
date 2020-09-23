#!/bin/bash

if [ -d /sys/kernel/mm/transparent_hugepage ]; then
  thp_path=/sys/kernel/mm/transparent_hugepage
elif [ -d /sys/kernel/mm/redhat_transparent_hugepage ]; then
  thp_path=/sys/kernel/mm/redhat_transparent_hugepage
else
  return 0
fi

echo 'never' > ${thp_path}/enabled
echo 'never' > ${thp_path}/defrag

echo "echo 'never' > ${thp_path}/enabled" >> /etc/rc.local
echo "echo 'never' > ${thp_path}/defrag" >> /etc/rc.local
