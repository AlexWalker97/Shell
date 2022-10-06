menu() {
    echo -e "——————————————————————————————————————————————————————————————————————————————————————\n"	
    echo "Linux服务器初始化工作脚本（V1.0）, 请保证此脚本在root用户下运行。此脚本在AlmaLinux8，9系统上测试通过，其它版本系统无法保证全部功能正常运行。"
	echo -e "注意：推荐仅在全新的服务器操作系统上运行此脚本，如二次执行可能会出现未知错误。欢迎关注博主csdn: https://blog.csdn.net/weixin_43045613\n"
	
	echo "请选择需要执行的命令，直接按回车键会按顺序执行所有任务，推荐回车键顺序执行："
	echo "1.修改主机名"
	echo "2.禁用ICMP协议(禁用ping)"
	echo "3.关闭selinux"
	echo "4.修改ssh端口"
	echo "5.创建新用户"
	echo "6.禁止root用户远程登陆"
	echo -e "7.(可选)为服务器开启bbr\n"
	
	read -p "请选择:" task	
	case $task in
    '')
      changehostname
	  disableICMP
	  disableSelinux
	  editSSHPort
	  addUser
	  forbidRootSSH
	  enableBBR
	  rebootDevice
      ;;	  
	1)
	  changehostname
	  ;;
	2)
	  disableICMP
	  ;;
	3)
	  disableSelinux
	  ;;
	4)
	  editSSHPort
	  ;;
	5)
	  addUser
	  ;;
	6)
	  forbidRootSSH
	  ;;
	7)
	  enableBBR
	  ;;
	esac
}

#修改主机名
changehostname() {
  read -p "请输入您想要设置的主机名：" host_name 
  hostnamectl set-hostname "${host_name}"
  echo -e "设置主机名完成\n"
}

#禁用ICMP协议
disableICMP() {
  echo "net.ipv4.icmp_echo_ignore_all = 1" >> /etc/sysctl.conf
  sysctl -p
  echo -e "禁用ping完成\n"
}

#关闭selinux
disableSelinux() {
   isSeLinuxOpen=$(getenforce)
   case $isSeLinuxOpen in
       Enforcing|Permissive) 
	   setenforce 0
	   sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
	   echo -e "已关闭selinux\n"
		 ;;	   
	   Disabled)
	   echo -e "selinux未启用，无需关闭\n"
	     ;;
   esac
}

#检查输入端口号
checkPort() {
   str="^[0-9]*$"
  
   if [[ $1 =~ $str && $1 -gt 0 && $1 -lt 65535 ]];
   then return 1
   else return 0
   fi
}

#修改ssh端口
editSSHPort() {
  #标志是否有合法port 0无 1有
  res=0
  #标志是否初次进入循环 0否 1是
  init=1

  while [ $res -eq 0 ]
  do 
    if [ $init -eq 1 ];
	then read -p "请输入您想要使用ssh的端口：" ssh_port 
	else read -p "输入不合法，请重新输入您想要使用ssh的端口：" ssh_port 
	fi
    checkPort $ssh_port
    res=$?
	init=0
  done
  
  firewall-cmd --add-port=$ssh_port/tcp --permanent
  firewall-cmd --reload
 
  sed -i "/^#Port/c\Port $ssh_port" /etc/ssh/sshd_config
  sed -i "/^Port/c\Port $ssh_port" /etc/ssh/sshd_config
  systemctl restart sshd  
  echo -e "已修改ssh端口为：$ssh_port，下次连接请使用$ssh_port端口\n" 
}

#创建新用户
addUser() {
  read -p "请输入您创建的用户名：" user_name 
  adduser $user_name
  echo "下面请按指令输入用户$user_name的密码："
  passwd $user_name
  usermod -aG wheel $user_name
  echo -e "已将用户$user_name设置为wheel组成员，创建用户完成\n"
}

#禁止root用户远程登陆
forbidRootSSH() {
  sed -i "s/Permitrootlogin yes/Permitrootlogin no/g" /etc/ssh/sshd_config
  systemctl restart sshd
  echo -e "已禁用root用户ssh登陆，下次连接请使用非root用户登录。\n若您未创建新用户请先不要断开此次会话，否则下次将无法登录！！！\n"
}
 
#(可选)为服务器开启bbr
enableBBR() {
  echo "net.ipv4.tcp_congestion_control = bbr" >> /etc/sysctl.conf
  echo "net.core.default_qdisc = fq_codel" >> /etc/sysctl.conf
  sysctl -p
  echo -e "bbr开启完成，建议重启服务器\n"
}

#确认是否重启系统
rebootDevice() {
  read -p "所选任务全部完成，是否重启电脑？[y/n]：" is_restart 
  case $is_restart in
    Y|y)
	echo -e "系统即将重启，下次请使用新用户名及新ssh端口登录，祝您生活愉快！\n"
	reboot;;
    N|n) 
	echo -e "即将退出脚本，祝您生活愉快！\n";;
  esac
}

menu