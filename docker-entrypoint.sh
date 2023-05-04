#!/bin/bash

# ulimit -SHc unlimited
# ulimit -SHu unlimited
# ulimit -SHs unlimited
# ulimit -SHl unlimited
# ulimit -SHi unlimited
# ulimit -SHq unlimited
# ulimit -SHn 655360

# 运行supervisord
exec /usr/bin/supervisord -c /etc/supervisor/supervisord.conf
