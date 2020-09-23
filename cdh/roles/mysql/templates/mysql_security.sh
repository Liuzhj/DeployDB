mysql_secure_installation <<EOF
{{password.stdout}}
y
{{cdh_mysql_password}}
{{cdh_mysql_password}}
y
n
y
y
EOF
