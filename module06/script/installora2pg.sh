#!/bin/bash
# $Id: installora2pg.sh 321 2020-08-19 10:04:37Z bpahlawa $
# Created 20-AUG-2019
# $Author: bpahlawa $
# $Date: 2020-08-19 18:04:37 +0800 (Wed, 19 Aug 2020) $
# $Revision: 321 $


#url basic and sdk instantclient for oracle 19c now doesnt require to accept license agreement
ORAINSTBASICURL="https://download.oracle.com/otn_software/linux/instantclient/19800/instantclient-basic-linux.x64-19.8.0.0.0dbru.zip?xd_co_f=27c74c5ade0e8f3e1141595923378611"
ORAINSTSDKURL="https://download.oracle.com/otn_software/linux/instantclient/19800/instantclient-sdk-linux.x64-19.8.0.0.0dbru.zip"
ORA2PG_GIT="https://github.com/darold/ora2pg.git"
DBD_ORACLE="https://www.cpan.org/modules/by-module/DBD"
PGSQLREPO="https://yum.postgresql.org/repopackages/"
PGVER="11"
INSTCLIENTKEYWORD="instantclient"
TMPFILE=/tmp/$0.$$
INTERNETCONN="1"

# User specific environment and startup programs
REDFONT="\e[01;48;5;234;38;5;196m"
GREENFONT="\e[01;38;5;46m"
NORMALFONT="\e[0m"
BLUEFONT="\e[01;38;5;14m"
YELLOWFONT="\e[0;34;2;10m"
VERSION_ID=""
ALLVER=""
export DISTRO=""
PKGDISTRO=""
RUNPKGUPDATE="1"

trap exitshell SIGINT SIGTERM


get_params()
{
   local OPTIND
   while getopts "v:sh" PARAM
   do
      case "$PARAM" in
      v)
          #pgver
          PGVER=${OPTARG}
          ;;
      s)
          #Skip oracle client library search
          IGNORESEARCH="1"
          ;;
      h)
          #display this usage
          usage
      esac
    done

    shift $((OPTIND-1))


}

#this is how to use this script
usage()
{
   echo -e "\nUsage: \n    $0 -v <pgsql-version> -s"
   echo -e "\n    -v pgsql-version [10|12|11(default)]\n    [-s] none(default)\n"
   echo -e "    E.g: $0 -v 12 -s     #using pgsql version 12 client and skip oracle client library (use instantclient instead)"
   echo -e "         $0 -v 10        #using pgsql version 10 and search oracle client library"
   exit 1
}



get_distro_version()
{
   if [ -f /etc/os-release ]
   then
      ALLVER=`sed -n ':a;N;$bb;ba;:b;s/.*VERSION_ID="\([0-9\.]\+\)".*/\1/p' /etc/os-release`
      VERSION_ID=`echo $ALLVER | cut -f1 -d"."`
      export DISTRO=`sed -n 's/^ID[ \|=]\(.*\)/\1/p' /etc/os-release | sed 's/"//g'`
      DISTRO=${DISTRO^^}
   else
      echo "Unsupported operating system version!!"
      exit 1
   fi
}

exitshell()
{
   echo -e "${NORMALFONT}Cancelling script....exiting....."
   exit 0
}

pkg_install()
{
 PKGDISTRO="${DISTRO,,}"
 [[ "$PKGDISTRO" = "rhel" ]] && PKGDISTRO="centos"

 PKG2INSTALL=`echo "$1" | sed -n "s/\(^\|.*:.*\)${PKGDISTRO}:\([a-zA-Z0-9\*-]\+\)\( .*:.*\|$\)/\2/p"`
 [[ `echo $1 | grep ":" | wc -l` -eq 0 ]] && [[ "$PKG2INSTALL" = "" ]] && PKG2INSTALL="$1" 
 [[ "$PKG2INSTALL" = "" ]] && return
 echo -e "${BLUEFONT}Checking $PKG2INSTALL package....."

    case "${DISTRO}" in
    "RHEL"|"CENTOS")
            [[ "$RUNPKGUPDATE" = "1" ]] && yum update all && RUNPKGUPDATE=0
            if [ $(yum list installed | grep "^${PKG2INSTALL}" | wc -l) -eq 0 ]
            then
                echo -e "${YELLOWFONT}installing ${PKG2INSTALL}....${NORMALFONT}" 
                yum -y install "${PKG2INSTALL}"
            fi
            ;;
    "UBUNTU")
            [[ "$RUNPKGUPDATE" = "1" ]] && apt update && RUNPKGUPDATE=0
            if [ $(apt list ${PKG2INSTALL} | grep "installed" | wc -l) -eq 0 ]
            then
                echo -e "${YELLOWFONT}installing ${PKG2INSTALL}....${NORMALFONT}"
                apt-get --yes install "${PKG2INSTALL}"
            fi
            ;;
    "ARCH")
            [[ "$RUNPKGUPDATE" = "1" ]] && echo "Y" | pacman -Syu && RUNPKGUPDATE=0
            echo "Y" | pacman -Sy $PKG2INSTALL
            ;;
    "DEBIAN")
            [[ "$RUNPKGUPDATE" = "1" ]] && apt update && RUNPKGUPDATE=0
            if [ $(apt list ${PKG2INSTALL} | grep "installed" | wc -l) -eq 0 ]
            then
                echo -e "${YELLOWFONT}installing ${PKG2INSTALL}....${NORMALFONT}"
                apt-get --yes install "${PKG2INSTALL}"
            fi
            ;;
    "OPENSUSE-LEAP")
	    [[ "$RUNPKGUPDATE" = "1" ]] && zypper refresh && RUNPKGUPDATE=0
	    if [ $(rpm -qa | grep "${PKG2INSTALL}" | wc -l) -eq 0 ]
            then
	       zypper install -y "${PKG2INSTALL}"
	    fi
            ;;
    "ALPINE")
            [[ "$RUNPKGUPDATE" = "1" ]] && apk update && apk add perl perl-dev && RUNPKGUPDATE=0
            apk add $PKG2INSTALL 
            ;;
     esac
   RVAL="$?"
   [[ "$PKG2INSTALL" = "wget" ]] && INTERNETCONN="$RVAL"
   echo -e "${GREENFONT}$PKG2INSTALL package is available......"
}


check_internet_conn()
{
   pkg_install wget
   echo -e "${BLUEFONT}Checking internet connection in progress....."
   [[ "$INTERNETCONN" != "0" ]] && echo -e "${REDFONT}Unable to connect to the internet!!${NORMALFONT}" && exit 1
   echo -e "${GREENFONT}Internet connection is available${NORMALFONT}"
   pkg_install which 
   pkg_install curl
   pkg_install git
   pkg_install "alpine:musl-dev"
   pkg_install "centos:perl-open"
   pkg_install "centos:perl-version"
   pkg_install "centos:perl-ExtUtils-MakeMaker ubuntu:libmodule-cpanfile-perl debian:libmodule-cpanfile-perl arch:perl-extutils-makemaker"
   pkg_install "centos:perl-DBI ubuntu:libdbi-perl debian:libdbi-perl alpine:perl-dbi arch:perl-dbi"
   pkg_install "centos:perl-Time-HiRes ubuntu:libtime-hires-perl debian:libtime-hires-perl alpine:perl-time-hires"
   pkg_install "centos:perl-Test-Simple ubuntu:libtest-simple-perl debian:libtest-simple-perl alpine:perl-test-simple arch:perl-test-simple"
   pkg_install "centos:libaio-devel ubuntu:libaio-dev debian:libaio-dev alpine:libaio-dev"
   pkg_install make
   pkg_install gcc
   pkg_install libnsl
   pkg_install libaio
   curl -kS --verbose --header 'Host:' $ORA2PG_GIT 2> $TMPFILE
   export GITHOST=`cat $TMPFILE | sed -n -e "s/\(.*CN=\)\([a-z0-9A-Z\.]\+\)\(,.*\|$\)/\2/p"`
   export GITIP=`ping -c1 -w1 github.com | sed -n -e "s/\(.*(\)\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)\().*\)/\2/p"`
   rm -f $TMPFILE

}

install_dbd_postgres()
{
   echo -e "${BLUEFONT}Finding pg_config, if it has multiple pg_config then latest version will be used"
   PGCONFIGS=`find / -name "pg_config" | grep ${PGVER} | tail -1`
   [[ "$PGCONFIGS" = "" ]] && PGCONFIGS=`find / -name "pg_config" | tail -1`

   if [ "$PGCONFIGS" = "" ]
   then
      echo -e "${REDFONT}Postgres client or server is not installed..."
      echo -e "${BLUEFONT}if you want to install postgresql library for ora2pg then press ctrl+C to cancel this installation"
      echo -e "after that, Install postgresql client then re-run this installation!\n"
      echo -e "${YELLOWFONT}However, the ora2pg will be installed without postgresql library"
      echo -e "${GREENFONT}Sleeping for 5 seconds waiting for you to decide...\n\n"
      sleep 5
      echo -e "${BLUEFONT}Installing ora2pg without Postgresql Library........"
      return 0
   fi

   VER=0
   for PGCFG in $PGCONFIGS
   do
      echo -e "${BLUEFONT}Running $PGCFG to get the PostgreSQL version..."
      if [ $VER -lt `$PGCFG | grep VERSION | sed "s/\(.* \)\([0-9]\+\).*$/\2/g"` ]
      then  
         VER=`$PGCFG | grep VERSION | sed "s/\(.* \)\([0-9]\+\).*$/\2/g"` 
         PGCONFIG="$PGCFG"
      fi
   done
   echo -e "${GREENFONT}The latest PostgreSQL Version is $VER"
      
   export POSTGRES_HOME=${PGCONFIG%/*/*}
   echo -e "${BLUEFONT}Checking DBD-Pg latest version...."
   DBDFILE=`curl -kS "${DBD_ORACLE}/" | grep "DBD-Pg-.*tar.gz" | tail -1 | sed -n 's/\(.*="\)\(DBD.*gz\)\(".*\)/\2/p'`
   [[ ! -f ${DBDFILE} ]] && echo -e "${YELLOWFONT}Downloading DBD-Pg latest version...." && wget --no-check-certificate ${DBD_ORACLE}/${DBDFILE}
   echo -e "${BLUEFONT}Checking postgres development...."

   pkg_install "centos:postgresql*${PGVER}*devel ubuntu:postgresql*dev*${PGVER} debian:postgresql*dev*${PGVER}"
   echo -e "${GREENFONT}Extracting $DBDFILE${NORMALFONT}"
   tar xvfz ${DBDFILE}
   cd ${DBDFILE%.*.*}
   perl Makefile.PL
   if [ -f Makefile ]
   then
      echo -e "${YELLOWFONT}Compiling $DBDFILE${NORMALFONT}"
      make
      make install
      [[ $? -ne 0 ]] && echo -e "${REDFONT}Error in compiling ${DBDFILE%.*.*} ${NORMALFONT}" && exit 1
   fi
   cd ..
   export DBDPGSOURCE="${DBDFILE%.*.*}"
}


install_dbd_oracle()
{
   echo -e "${BLUEFONT}Checking DBD-Oracle latest version...."
   DBDFILE=`curl -kS "${DBD_ORACLE}/" | grep "DBD-Oracle.*tar.gz" | tail -1 | sed -n 's/\(.*="\)\(DBD.*gz\)\(".*\)/\2/p'`
   [[ ! -f ${DBDFILE} ]] && echo -e "${YELLOWFONT}Downloading DBD-Oracle latest version...." && wget --no-check-certificate ${DBD_ORACLE}/${DBDFILE}
   echo -e "${GREENFONT}Extracting $DBDFILE${NORMALFONT}"
   tar xvfz ${DBDFILE}
   cd ${DBDFILE%.*.*}
   perl Makefile.PL
   if [ -f Makefile ]
   then
      echo -e "${YELLOWFONT}Compiling $DBDFILE${NORMALFONT}"
      make
      make install
      [[ $? -ne 0 ]] && echo -e "${REDFONT}Error in compiling ${DBDFILE%.*.*} ${NORMALFONT}" && exit 1
   fi
   cd ..
   export DBDSOURCE="${DBDFILE%.*.*}"
}


install_ora2pg()
{
   if [ "$GITHOST" = "github.com" ]
   then
      echo -e "${YELLOWFONT}Cloning git repository..."
      git clone $ORA2PG_GIT
   else
      echo -e "${REDFONT}Server in github.com ssl certificate is different!!, Hostname=$GITHOST ${NORMALFONT}"
      echo -e "can not continue!!, there must be something wrong...."
      echo -e "GitIP $GITIP"
      exit 1
   fi
   cd ora2pg
   perl Makefile.PL
   if [ -f Makefile ]
   then
      echo -e "${YELLOFONT}Compiling ora2pg${NORMALFONT}"
      make
      make install
      [[ $? -ne 0 ]] && echo -e "${REDFONT}Error in compiling ora2pg...${NORMALFONT}" && exit 1
   fi
   echo -e "\n${GREENFONT}ora2pg has been compiled successfully\n"
   cd ..
   [[ -d ora2pg ]] && echo -e "${YELLOWFONT}Removing ora2pg source directory" && rm -rf ora2pg
   [[ -d "${DBDSOURCE}" ]] && echo -e "${YELLOWFONT}Removing ${DBDSOURCE} source directory and gz file${NORMALFONT}" && rm -rf "${DBDSOURCE}"*
   [[ -d "${DBDPGSOURCE}" ]] && echo -e "${YELLOWFONT}Removing ${DBDPGSOURCE} source directory and gz file${NORMALFONT}" && rm -rf "${DBDPGSOURCE}"*

}

install_pgclient()
{
    case "$DISTRO" in
    "RHEL"|"CENTOS")
            PGCLIENT=`curl -kS "${PGSQLREPO}" | grep "EL-${VERSION_ID}-x86_64" | grep -v "non-free" | tail -1 | sed -n 's/\(.*="\)\(https.*rpm\)\(".*\)/\2/p'`
            rpm -ivh $PGCLIENT
            [[ ( "$DISTRO" = "CENTOS" || "$DISTRO" = "RHEL" ) && "${VERSION_ID}" -ge "8" ]] && yum -y module disable postgresql
            yum -y install postgresql${PGVER}
            ;;
    "UBUNTU")
            echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
            wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
            apt update
	    apt -y install postgresql-client-${PGVER}
            ;;
    "ARCH")
            echo "Y" | pacman -Sy postgresql
            ;;
    "DEBIAN")
            echo "deb http://apt.postgresql.org/pub/repos/apt/ $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
            wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
            apt update
	    apt -y install postgresql-client-${PGVER}
            ;;
    "OPENSUSE-LEAP")
	    zypper ar -f -G http://download.opensuse.org/repositories/server:database:postgresql/openSUSE_Tumbleweed/ PostgreSQL
	    zypper refresh
	    zypper install -y postgresql10-devel

            ;;
    "ALPINE")
            apk add postgresql-client
            apk add postgresql-dev
            ;;
     esac
   
}

install_additional_libs()
{
   if [ \( "$DISTRO" = "CENTOS" -o "$DISTRO" = "RHEL" \) -a "${VERSION_ID}" = "6" ]
   then
      yum install -y perl-Time-modules perl-Time-HiRes
   fi
}
   

checking_ora2pg()
{
   echo -e "\n${BLUEFONT}Checking whether ora2pg can be run successfully!!"
   echo -e "Running ora2pg without parameter.........\n"
   echo -e "${YELLOWFONT}This ora2pg will depend on the following ORACLE_HOME directory:${GREENFONT} $ORACLE_HOME"
   if [ "$POSTGRES_HOME" != "" ] 
   then
      echo -e "${YELLOWFONT}This ora2pg will depend on the following POSTGRES_HOME directory:${GREENFONT} $POSTGRES_HOME\n"
   else
      echo -e "${BLUEFONT}This ora2pg is not linked to POSTGRES_HOME due to the unavailability of postgresql client/server package"
      echo -e "${BLUEFONT}You can install postgresql client/server package using dnf or yum REDHAT tool, and re-run this installation at anytime...\n"
   fi
   
   if [ "$SUDO_USER" = "" ]
   then
      echo -e "${YELLOWFONT}\nYou are running this script as ${BLUEFONT}root"
    
      printf "Which Linux username who will run ora2pg tool? : $ERRCODE ";read THEUSER
      [[ "$THEUSER" = "" ]] && THEUSER=empty
      id $THEUSER 2>/dev/null
      while [ $? -ne 0 ] 
      do
          ERRCODE="Sorry!!, User : $THEUSER doesnt exist!!.. try again.."
          printf "Which user that will run this ora2pg tool? : $ERRCODE ";read THEUSER
          [[ "$THEUSER" = "" ]] && THEUSER=empty
          id $THEUSER 2>/dev/null
      done
      printf "User : $THEUSER is available....\n"
      HOMEDIR=`su - $THEUSER -c "echo ~" 2>/dev/null`
   else
      echo -e "${YELLOWFONT}\nYou are running this script as ${BLUEFONT}$SUDO_USER"
      echo -e "\nUser : $SUDO_USER is running this installation, now setting up necessary environment variable"
      HOMEDIR=`su - $SUDO_USER -c "echo ~" 2>/dev/null`
      THEUSER="$SUDO_USER"
   fi

   [[ ! -d "$HOMEDIR" ]] && mkdir "$HOMEDIR" && chown $THEUSER "$HOMEDIR" 2>/dev/null
   if [ -f $HOMEDIR/.bash_profile ]
   then
      [[ `cat $HOMEDIR/.bash_profile | grep LD_LIBRARY_PATH | wc -l` -eq 0 ]] && echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME" >> $HOMEDIR/.bash_profile
   else
      echo "export ORACLE_HOME=$ORACLE_HOME" >> $HOMEDIR/.bash_profile
      echo "export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME" >> $HOMEDIR/.bash_profile
   fi
   ln -s $HOMEDIR/.bash_profile $HOMEDIR/.profile 2>/dev/null 1>/dev/null
	
   
   export PATH=/usr/local/bin:$PATH
   ORA2PGBIN=`which ora2pg`

   if [ "$THEUSER" = "root" ]
   then
      RESULT=`$ORA2PGBIN 2>&1`
   else
      RESULT=`su - $THEUSER -c "$ORA2PGBIN" 2>&1`
      if [ $? -ne 0 ]
      then
         CHECKERROR=`su - $THEUSER -c "$ORA2PGBIN 2>&1 | grep \"Can't locate\" | sed \"s/.*contains: \(.*\) \.).*$/\1/g\""`
         for THEDIR in $CHECKERROR
         do
            [[ -d $THEDIR ]] && echo "setting read and executable permission on PERL lib directory $THEDIR" && chmod o+rx $THEDIR
         done
      fi
   fi
   if [ $? -ne 0 ]
   then
      if [[ $RESULT =~ ORA- ]]
      then
          echo -e "${GREENFONT}ora2pg can be run successfully, however the ${REDFONT}ORA- error ${GREENFONT}could be related to the following issues:"
          echo -e "ora2pg.conf has wrong configuration, listener is not up or database is down!!"          
          echo -e "This installation is considered to be successfull...${NORMALFONT}\n"
          echo -e "\nPlease logout from this user, then login as $THEUSER to run ora2pg...\n"
          exit 0
      fi
      if [[ $RESULT =~ .*find.*configuration.*file ]]
      then
          echo -e "${GREENFONT}ora2pg requires ora2pg.conf...."
          echo -e "ora2pg has been installed successfully${NORMALFONT}"
          exit 0
      fi
      echo -e "${REDFONT}There some issues with ora2pg....${NORMALFONT}"
      echo -e "Usually this is due to LD_LIBRARY_PATH that was not set...."
      echo -e "${BLUEFONT}Enforcing LD_LIBRARY_PATH to $ORACLE_HOME/lib:$ORACLE_HOME"
      export LD_LIBRARY_PATH=$ORACLE_HOME/lib:$ORACLE_HOME
      echo -e "${YELLOWFONT}Re-running ora2pg......"
      RESULT=`su - $THEUSER -c "$ORA2PGBIN" 2>&1`
      if [ $? -ne 0 ]
      then
          if [[ $RESULT =~ ORA- ]]
          then
              echo -e "${GREENFONT}ora2pg can be run successfully, however ${REDFONT}the ORA- error ${GREENFONT}could be related to the following issues:"
              echo -e "ora2pg.conf has wrong configuration, listener is not up or database is down!!"          
              echo -e "This installation is considered to be successfull...${NORMALFONT}\n"
              echo -e "\nPlease logout from this user, then login as $THEUSER to run ora2pg...\n"
              exit 0
          else
              echo -e "${REDFONT}The issues are not resolved, please check logfile....!!${NORMALFONT}"
              exit 1
          fi
      fi
   fi
   echo -e "${GREENFONT}ora2pg can be run successfully"
   echo -e "${NORMALFONT}Before running ora2pg you must do:"
   echo -e "export LD_LIBRARY_PATH=\$ORACLE_HOME/lib:\$ORACLE_HOME"
}

download_instantclient19c()
{
   FILENAME="$1"
   URL="$2"
   DESCRIPTION="$3"
   echo -e "${BLUEFONT}${DESCRIPTION}${NORMALFONT}"
   wget -O "${FILENAME}" "${URL}" 2>/dev/null 1>/dev/null
   [[ $? -ne 0 ]] && echo -e "${REDFONT}Unable to download $DESCRIPTION from URL $URL , you may need to change the URL within this script!!, or the URL has been relocated!!\nExiting....${NORMALFONT}" && exit 1

}
   


install_oracle_instantclient()
{
   pkg_install unzip
   echo -e "${YELLOWFONT}Installing oracle instant client"
   echo -e "${YELLOWFONT}Finding instantclient filename with keyword=${INSTCLIENTKEYWORD}"
   find -quit 2>/dev/null 1>/dev/null
   [[ $? -eq 0 ]] && QUITCMD="-quit"
   INSTCLIENTFILE=`find . \( -not -name "*${INSTCLIENTKEYWORD}*sdk*linux*" -a -name "*${INSTCLIENTKEYWORD}*linux*" \) -print $QUITCMD`
   if [[ "$INSTCLIENTFILE" = "" ]]
   then
      INSTCLIENTFILE=`find . -name "*${INSTCLIENTKEYWORD}*" -print $QUITCMD | grep -v sdk`
      if [[ "$INSTCLIENTFILE" = "" ]]
      then
         echo -e "${YELLOWFONT}Oracle instant client file doesnt exist....${NORMALFONT}"
      else
         echo -e "${YELLOWFONT}Oracle instant client file $INSTCLIENTFILE has been found.... but it is not for linux, please download the correct file!..${NORMALFONT}"
      fi
      echo -e "\n========================ATTENTION============ATTENTION============================================="
      echo -e "Trying to download oracle basic instant client 19c.... "
      echo -e "Pleaes NOTE that oracle instant client 19c only works with oracle 12c or later..."
      echo -e "if your Oracle database is version 11g or earlier, please cancel this script by pressing ctrl+c right now!!"
      echo -e "and then download oracle instantclient 12c from oracle website\n"
      download_instantclient19c "${INSTCLIENTKEYWORD}-basic-linux.zip" "${ORAINSTBASICURL}" "Oracle basic instantclient 19c"
      INSTCLIENTFILE="${INSTCLIENTKEYWORD}-basic-linux.zip"
   fi

   INSTCLIENTSDKFILE=`find . -name "*${INSTCLIENTKEYWORD}*sdk*linux*" -print $QUITCMD`
   if [[ "$INSTCLIENTSDKFILE" = "" ]]
   then
      INSTCLIENTSDKFILE=`find . -name "*${INSTCLIENTKEYWORD}*sdk*" -print $QUITCMD`
      if [[ "$INSTCLIENTSDKFILE" = "" ]]
      then
          echo -e "${YELLOWFONT}Oracle instant client sdk file doesnt exist....${NORMALFONT}"
      else
          echo -e "${YELLOWFONT}Oracle instant client sdk file $INSTCLIENTSDKFILE has been found.... but not for linux, please download the correct file!....${NORMALFONT}"
      fi
      echo -e "\n========================ATTENTION============ATTENTION============================================="
      echo -e "Trying to download oracle sdk instant client 19c.... "
      echo -e "Pleaes NOTE that oracle instant client 19c only works with oracle 12c or later..."
      echo -e "if your Oracle database is version 11g or earlier, please cancel this script by pressing ctrl+c right now!!"
      echo -e "and then download oracle instantclient 12c from oracle website\n"
      download_instantclient19c "${INSTCLIENTKEYWORD}-sdk-linux.zip" "${ORAINSTSDKURL}" "Oracle sdk instantclient 19c"
      INSTCLIENTSDKFILE="${INSTCLIENTKEYWORD}-sdk-linux.zip"
   fi
   
    unzip -o $INSTCLIENTSDKFILE -d /usr/local
    [[ $? -ne 0 ]] && echo -e "${REDFONT}Unzipping file $INSTCLIENTSDKFILE failed!!${NORMALFONT}" && exit 1
    unzip -o $INSTCLIENTFILE -d /usr/local
    [[ $? -ne 0 ]] && echo -e "${REDFONT}Unzipping file $INSTCLIENTFILE failed!!${NORMALFONT}" && exit 1
    echo -e "${GREENFONT}File $INSTCLIENTFILE has been unzipped successfully!!"
    LIBFILE=`find /usr/local -name "libclntsh.so*" 2>/dev/null| grep -Ev "stage|inventory" | tail -1 2>/dev/null`
    export ORACLE_HOME="${LIBFILE%/*}"
    export LD_LIBRARY_PATH="$ORACLE_HOME"
}

   [[ $(whoami) != "root" ]] && echo -e "${REDFONT}This script must be run as root or with sudo...${NORMALFONT}" && exit 1
   get_params "$@"
   [[ "$IGNORESEARCH" = "1" ]]  && export ORACLE_HOME=/usr/local
   get_distro_version
   echo "Running linux distribution $DISTRO version $ALLVER"
   check_internet_conn
   echo -e "${BLUEFONT}Checking oracle installation locally....."

   echo -e "${BLUEFONT}Checking ORACLE_HOME environment variable...."
   if [ "$ORACLE_HOME" != "" ]
   then
      if [ ! -d $ORACLE_HOME ]
      then
         echo -e "${BLUEFONT}The $ORACLE_HOME is not a directory, so searchig from root directory / ...."
         LIBFILE=`find / -name "libclntsh.so*" 2>/dev/null| grep -Ev "stage|inventory" | tail -1 2>/dev/null`
      else
         LIBFILE=`find $ORACLE_HOME -name "libclntsh.so*" 2>/dev/null| grep -Ev "stage|inventory" | tail -1 2>/dev/null`
      fi
   else
      LIBFILE=`find / -name "libclntsh.so*" 2>/dev/null| grep -Ev "stage|inventory" | tail -1 2>/dev/null`
   fi
   if [ "$LIBFILE" = "" ]
   then
      [[ "$IGNORESEARCH" = "1" ]] && unset ORACLE_HOME
      echo -e "${BLUEFONT}oracle instantclient needs to be installed or $ORACLE_HOME is not correct"
      install_oracle_instantclient
   else
      if [[ $LIBFILE =~ .*${INSTCLIENTKEYWORD}.*$ ]]
      then
         export ORACLE_HOME="${LIBFILE%/*}"
      else
         export ORACLE_HOME="${LIBFILE%/*/*}"
      fi
   fi
   install_additional_libs
   install_dbd_oracle
   install_pgclient
   install_dbd_postgres
   install_ora2pg
   checking_ora2pg
