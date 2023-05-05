#!/bin/bash

# ulimit -SHc unlimited
# ulimit -SHu unlimited
# ulimit -SHs unlimited
# ulimit -SHl unlimited
# ulimit -SHi unlimited
# ulimit -SHq unlimited
# ulimit -SHn 655360

# 设置YACD地址
sed -i 's#http://127.0.0.1:9090#$YACD_DEFAULT_BACKEND#g' /www/index.html

# 运行supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
