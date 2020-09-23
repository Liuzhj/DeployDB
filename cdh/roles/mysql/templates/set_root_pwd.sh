mysql -uroot -p{{cdh_mysql_password}} <<!
GRANT ALL PRIVILEGES ON *.* TO root@"%" IDENTIFIED BY "{{cdh_mysql_password}}" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'hive'@'%' Identified by '{{cdh_mysql_password}}';
create database cdhhivemeta; 
create database cdhamon; 
create database cdhoozie; 
create database cdhhue;
!
