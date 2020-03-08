#!/bin/bash
#Desciption:cobbler自动化部署系统启动/停止脚本
#Author:WeiyiGeek

cat >> /etc/init.d/cobbler<<EOF
#!/bin/bash
# chkconfig: 345 80 90
# description:cobbler

case \$1 in
  start)
    service httpd start
    service xinetd start
    service dhcpd start
    service cobblerd start
    ;;

  stop)
    service httpd stop
    service xinetd stop
    service dhcpd stop
    service cobblerd stop
    ;;

  restart)
    service httpd restart
    service xinetd restart
    service dhcpd restart
    service cobblerd restart
    ;;

  status)
    service httpd status
    service xinetd status
    service dhcpd status
    service cobblerd status
    ;;

  sync)
    cobbler sync
    ;;

  *)
    echo "Input error,please in put 'start|stop|restart|status|sync'!"
    exit 2
    ;;

esac
EOF
chmod +x /etc/init.d/cobbler
/etc/init.d/cobbler start
#下载bootloaders
cobbler get-loaders
#检查cobber安装问题
cobber check