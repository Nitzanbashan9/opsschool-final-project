#!/bin/bash
#
# https://github.com/hwdsl2/openvpn-install
#
# Based on the work of Nyr and contributors at:
# https://github.com/Nyr/openvpn-install
#
# Copyright (c) 2022-2023 Lin Song <linsongui@gmail.com>
# Copyright (c) 2013-2023 Nyr
#
# Released under the MIT License, see the accompanying file LICENSE.txt
# or https://opensource.org/licenses/MIT
​
exiterr()  { echo "Error: $1" >&2; exit 1; }
exiterr2() { exiterr "'apt-get install' failed."; }
exiterr3() { exiterr "'yum install' failed."; }
​
check_ip() {
	IP_REGEX='^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$'
	printf '%s' "$1" | tr -d '\n' | grep -Eq "$IP_REGEX"
}
​
check_os() {
	if grep -qs "ubuntu" /etc/os-release; then
		os="ubuntu"
		os_version=$(grep 'VERSION_ID' /etc/os-release | cut -d '"' -f 2 | tr -d '.')
		group_name="nogroup"
	elif [[ -e /etc/debian_version ]]; then
		os="debian"
		os_version=$(grep -oE '[0-9]+' /etc/debian_version | head -1)
		group_name="nogroup"
	elif [[ -e /etc/almalinux-release || -e /etc/rocky-release || -e /etc/centos-release ]]; then
		os="centos"
		os_version=$(grep -shoE '[0-9]+' /etc/almalinux-release /etc/rocky-release /etc/centos-release | head -1)
		group_name="nobody"
	elif grep -qs "Amazon Linux release 2 " /etc/system-release; then
		os="centos"
		os_version="7"
		group_name="nobody"
	elif grep -qs "Amazon Linux release 2023" /etc/system-release; then
		exiterr "Amazon Linux 2023 is not supported."
	elif [[ -e /etc/fedora-release ]]; then
		os="fedora"
		os_version=$(grep -oE '[0-9]+' /etc/fedora-release | head -1)
		group_name="nobody"
	else
		exiterr "This installer seems to be running on an unsupported distribution.
Supported distros are Ubuntu, Debian, AlmaLinux, Rocky Linux, CentOS, Fedora and Amazon Linux 2."
	fi
}
​
check_os_ver() {
	if [[ "$os" == "ubuntu" && "$os_version" -lt 1804 ]]; then
		exiterr "Ubuntu 18.04 or higher is required to use this installer.
This version of Ubuntu is too old and unsupported."
	fi
​
	if [[ "$os" == "debian" && "$os_version" -lt 9 ]]; then
		exiterr "Debian 9 or higher is required to use this installer.
This version of Debian is too old and unsupported."
	fi
​
	if [[ "$os" == "centos" && "$os_version" -lt 7 ]]; then
		exiterr "CentOS 7 or higher is required to use this installer.
This version of CentOS is too old and unsupported."
	fi
}
​
check_nftables() {
	if [ "$os" = "centos" ]; then
		if grep -qs "hwdsl2 VPN script" /etc/sysconfig/nftables.conf \
			|| systemctl is-active --quiet nftables 2>/dev/null; then
			exiterr "This system has nftables enabled, which is not supported by this installer."
		fi
	fi
}
​
install_wget() {
	# Detect some Debian minimal setups where neither wget nor curl are installed
	if ! hash wget 2>/dev/null && ! hash curl 2>/dev/null; then
		if [ "$auto" = 0 ]; then
			echo "Wget is required to use this installer."
			read -n1 -r -p "Press any key to install Wget and continue..."
		fi
		export DEBIAN_FRONTEND=noninteractive
		(
			set -x
			apt-get -yqq update || apt-get -yqq update
			apt-get -yqq install wget >/dev/null
		) || exiterr2
	fi
}
​
install_iproute() {
	if ! hash ip 2>/dev/null; then
		if [ "$auto" = 0 ]; then
			echo "iproute is required to use this installer."
			read -n1 -r -p "Press any key to install iproute and continue..."
		fi
		if [ "$os" = "debian" ] || [ "$os" = "ubuntu" ]; then
			export DEBIAN_FRONTEND=noninteractive
			(
				set -x
				apt-get -yqq update || apt-get -yqq update
				apt-get -yqq install iproute2 >/dev/null
			) || exiterr2
		else
			(
				set -x
				yum -y -q install iproute >/dev/null
			) || exiterr3
		fi
	fi
}
​
show_start_setup() {
	if [ "$auto" = 0 ]; then
		echo
		echo 'Welcome to this OpenVPN server installer!'
		echo 'GitHub: https://github.com/hwdsl2/openvpn-install'
		echo
		echo 'I need to ask you a few questions before starting setup.'
		echo 'You can use the default options and just press enter if you are OK with them.'
	else
		show_header
		echo
		echo 'Starting OpenVPN setup using default options.'
	fi
}
​
find_public_ip() {
	ip_url1="http://ipv4.icanhazip.com"
	ip_url2="http://ip1.dynupdate.no-ip.com"
	# Get public IP and sanitize with grep
	get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "$ip_url1" || curl -m 10 -4Ls "$ip_url1")")
	if ! check_ip "$get_public_ip"; then
		get_public_ip=$(grep -m 1 -oE '^[0-9]{1,3}(\.[0-9]{1,3}){3}$' <<< "$(wget -T 10 -t 1 -4qO- "$ip_url2" || curl -m 10 -4Ls "$ip_url2")")
	fi
}
​
detect_ip() {
	# If system has a single IPv4, it is selected automatically.
	if [[ $(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}') -eq 1 ]]; then
		ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
	else
		# Use the IP address on the default route
		ip=$(ip -4 route get 1 | sed 's/ uid .*//' | awk '{print $NF;exit}' 2>/dev/null)
		if ! check_ip "$ip"; then
			find_public_ip
			ip_match=0
			if [ -n "$get_public_ip" ]; then
				ip_list=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}')
				while IFS= read -r line; do
					if [ "$line" = "$get_public_ip" ]; then
						ip_match=1
						ip="$line"
					fi
				done <<< "$ip_list"
			fi
			if [ "$ip_match" = 0 ]; then
				if [ "$auto" = 0 ]; then
					echo
					echo "Which IPv4 address should be used?"
					number_of_ip=$(ip -4 addr | grep inet | grep -vEc '127(\.[0-9]{1,3}){3}')
					ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | nl -s ') '
					read -rp "IPv4 address [1]: " ip_number
					until [[ -z "$ip_number" || "$ip_number" =~ ^[0-9]+$ && "$ip_number" -le "$number_of_ip" ]]; do
						echo "$ip_number: invalid selection."
						read -rp "IPv4 address [1]: " ip_number
					done
					[[ -z "$ip_number" ]] && ip_number=1
				else
					ip_number=1
				fi
				ip=$(ip -4 addr | grep inet | grep -vE '127(\.[0-9]{1,3}){3}' | cut -d '/' -f 1 | grep -oE '[0-9]{1,3}(\.[0-9]{1,3}){3}' | sed -n "$ip_number"p)
			fi
		fi
	fi
	if ! check_ip "$ip"; then
		echo "Error: Could not detect this server's IP address." >&2
		echo "Abort. No changes were made." >&2
		exit 1
	fi
}
​
check_nat_ip() {
	# If $ip is a private IP address, the server must be behind NAT
	if printf '%s' "$ip" | grep -qE '^(10|127|172\.(1[6-9]|2[0-9]|3[0-1])|192\.168|169\.254)\.'; then
		find_public_ip
		if ! check_ip "$get_public_ip"; then
			if [ "$auto" = 0 ]; then
				echo
				echo "This server is behind NAT. What is the public IPv4 address?"
				read -rp "Public IPv4 address: " public_ip
				until check_ip "$public_ip"; do
					echo "Invalid input."
					read -rp "Public IPv4 address: " public_ip
				done
			else
				echo "Error: Could not detect this server's public IP." >&2
				echo "Abort. No changes were made." >&2
				exit 1
			fi
		else
			public_ip="$get_public_ip"
		fi
	fi
}
​
show_config() {
	if [ "$auto" != 0 ]; then
		echo
		printf '%s' "Server IP: "
		[ -n "$public_ip" ] && printf '%s\n' "$public_ip" || printf '%s\n' "$ip"
		echo "Port: UDP/1194"
		echo "Client name: client"
		echo "Client DNS: Google Public DNS"
	fi
}
​
detect_ipv6() {
	# If system has a single IPv6, it is selected automatically
	if [[ $(ip -6 addr | grep -c 'inet6 [23]') -eq 1 ]]; then
		ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}')
	fi
	# If system has multiple IPv6, ask the user to select one
	if [[ $(ip -6 addr | grep -c 'inet6 [23]') -gt 1 ]]; then
		if [ "$auto" = 0 ]; then
			echo
			echo "Which IPv6 address should be used?"
			number_of_ip6=$(ip -6 addr | grep -c 'inet6 [23]')
			ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | nl -s ') '
			read -rp "IPv6 address [1]: " ip6_number
			until [[ -z "$ip6_number" || "$ip6_number" =~ ^[0-9]+$ && "$ip6_number" -le "$number_of_ip6" ]]; do
				echo "$ip6_number: invalid selection."
				read -rp "IPv6 address [1]: " ip6_number
			done
			[[ -z "$ip6_number" ]] && ip6_number=1
		else
			ip6_number=1
		fi
		ip6=$(ip -6 addr | grep 'inet6 [23]' | cut -d '/' -f 1 | grep -oE '([0-9a-fA-F]{0,4}:){1,7}[0-9a-fA-F]{0,4}' | sed -n "$ip6_number"p)
	fi
}
​
select_protocol() {
	if [ "$auto" = 0 ]; then
		echo
		echo "Which protocol should OpenVPN use?"
		echo "   1) UDP (recommended)"
		echo "   2) TCP"
		read -rp "Protocol [1]: " protocol
		until [[ -z "$protocol" || "$protocol" =~ ^[12]$ ]]; do
			echo "$protocol: invalid selection."
			read -rp "Protocol [1]: " protocol
		done
	else
		protocol=1
	fi
	case "$protocol" in
		1|"")
		protocol=udp
		;;
		2)
		protocol=tcp
		;;
	esac
}
​
select_port() {
	if [ "$auto" = 0 ]; then
		echo
		echo "What port should OpenVPN listen to?"
		read -rp "Port [1194]: " port
		until [[ -z "$port" || "$port" =~ ^[0-9]+$ && "$port" -le 65535 ]]; do
			echo "$port: invalid port."
			read -rp "Port [1194]: " port
		done
		[[ -z "$port" ]] && port=1194
	else
		port=1194
	fi
}
​
enter_custom_dns() {
	read -rp "Enter primary DNS server: " dns1
	until check_ip "$dns1"; do
		echo "Invalid DNS server."
		read -rp "Enter primary DNS server: " dns1
	done
	read -rp "Enter secondary DNS server (Enter to skip): " dns2
	until [ -z "$dns2" ] || check_ip "$dns2"; do
		echo "Invalid DNS server."
		read -rp "Enter secondary DNS server (Enter to skip): " dns2
	done
}
​
select_dns() {
	if [ "$auto" = 0 ]; then
		echo
		echo "Select a DNS server for the clients:"
		echo "   1) Current system resolvers"
		echo "   2) Google Public DNS"
		echo "   3) Cloudflare DNS"
		echo "   4) OpenDNS"
		echo "   5) Quad9"
		echo "   6) AdGuard DNS"
		echo "   7) Custom"
		read -rp "DNS server [2]: " dns
		until [[ -z "$dns" || "$dns" =~ ^[1-7]$ ]]; do
			echo "$dns: invalid selection."
			read -rp "DNS server [2]: " dns
		done
	else
		dns=2
	fi
	if [ "$dns" = 7 ]; then
		enter_custom_dns
	fi
}
​
set_client_name() {
	# Allow a limited set of characters to avoid conflicts
	client=$(sed 's/[^0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-]/_/g' <<< "$unsanitized_client")
}
​
enter_client_name() {
	if [ "$auto" = 0 ]; then
		echo
		echo "Enter a name for the first client:"
		read -rp "Name [client]: " unsanitized_client
		set_client_name
		[[ -z "$client" ]] && client=client
	else
		client=client
	fi
}
​
check_firewall() {
	# Install a firewall if firewalld or iptables are not already available
	if ! systemctl is-active --quiet firewalld.service && ! hash iptables 2>/dev/null; then
		if [[ "$os" == "centos" || "$os" == "fedora" ]]; then
			firewall="firewalld"
			# We don't want to silently enable firewalld, so we give a subtle warning
			# If the user continues, firewalld will be installed and enabled during setup
			echo
...