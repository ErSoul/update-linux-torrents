#!/bin/bash

type curl > /dev/null 2>&1 || (echo "ERROR: curl must be installed." >&2 && exit 1)
type awk > /dev/null 2>&1 || (echo "ERROR: awk must be installed." >&2 && exit 1)
type transmission-remote > /dev/null 2>&1 || (echo "ERROR: transmission must be installed." >&2 && exit 1)
type zsync > /dev/null 2>&1 || (echo "ERROR: zsync must be installed." >&2 && exit 1)

TRANSMISSION="transmission-remote --auth transmission:transmission"

notify() {
	[ -n "$NTFY_TOPIC" ] && \
		curl -s \
		-H "Title: Failed to fetch $1" \
		-H "Priority: default" \
		-H "Tags: warning" \
		-d "Review the $1 function for necessary updates on the code" \
		ntfy.sh/$NTFY_TOPIC
}

help_msg() {
	printf "usage: `basename $0` [-d <distros>]\n\n"
cat << EOF
Specify linux distributions to be updated with transmission-cli.

Args:
-d	<DIR>	Download directory

Options:

-h		Show this help message
-t <distros>	List of the distro's to be updated. (comma separated)
-n <TOPIC>	Send a notification to the specified NTFY Topic in case of failure
EOF
}

main() {
	local DEFAULT=true
	while [ $# -gt 0 ]; do
		case $1 in
			-h|--help)
				help_msg
				exit 0
				;;
			-t)
				DEFAULT=false
				local DISTROS="$2"
				shift
				;;
			-n)
				NTFY_TOPIC=$2
				shift
				;;
			-d)
				DOWNLOAD_DIR="$2"
				shift
				;;
			-*|--*)
				echo "Invalid option $1"
				exit 1
				;;
			*)
				shift
				;;
		esac
	done

	[ -z "$DOWNLOAD_DIR" ] && echo "ERROR: You must set a directory for downloads." >&2 && exit 1

	if $DEFAULT; then
		FUNCTIONS=`declare -F | grep -Ev "help|main|notify" | awk '{print $3}'`
		for FUNCTION in `echo $FUNCTIONS | tr , ' '`; do
			$FUNCTION 2>/dev/null || echo "$FUNCTION is not defined" >&2
		done
	else
		for DISTRO in `echo $DISTROS | tr , ' '`; do
			$DISTRO 2>/dev/null || echo "$DISTRO is not defined" >&2
		done
	fi
}

ubuntu() {
	echo "Checking if Ubuntu is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep ubuntu | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep ubuntu | awk '{print $NF}' | cut -d "-" -f 2`
	local RELEASE=`curl -s https://releases.ubuntu.com/ | grep LTS | grep -o '[[:digit:]]\+\.[[:digit:]]\+\(\.[[:digit:]]\+\)\?' | sort -V | tail -n1`

	[ -z "$RELEASE" ] && notify Ubuntu && return

	if [ -z "$CURRENT" ]; then
		echo "Ubuntu isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://releases.ubuntu.com/$RELEASE/ubuntu-$RELEASE-live-server-amd64.iso.torrent"
	fi
	
	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://releases.ubuntu.com/$RELEASE/ubuntu-$RELEASE-live-server-amd64.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Ubuntu $RELEASE"
	else
		echo "Ubuntu is updated..."
	fi
}

kali() {
	echo "Checking if Kali is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep kali | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep kali | awk '{print $NF}' | cut -d "-" -f 3`
	local RELEASE=`curl -s https://cdimage.kali.org/current/ | grep -o kali-linux-.*-live-amd64.iso.torrent | grep -o '[[:digit:]]\+\.[[:digit:]]' | sort -V | tail -n1`

	[ -z "$RELEASE" ] && notify Kali && return
	
	if [ -z "$CURRENT" ]; then
		echo "Kali Linux isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://cdimage.kali.org/kali-$RELEASE/kali-linux-$RELEASE-live-amd64.iso.torrent"
	fi

	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://cdimage.kali.org/kali-$RELEASE/kali-linux-$RELEASE-live-amd64.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Kali Linux $RELEASE"
	else
		echo "Kali is updated..."
	fi
}

tails() {
	echo "Checking if TailsOS is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep tails | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep tails | awk '{print $NF}' | cut -d "-" -f 3`
	local RELEASE=`curl -s https://tails.net/torrents/files/ | grep -o tails-amd64-.*.iso.torrent | grep -v rc | grep -o '[[:digit:]]\+\.[[:digit:]]\+' | sort -V | tail -n1`

	[ -z "$RELEASE" ] && notify TailsOS && return
	
	if [ -z "$CURRENT" ]; then
		echo "Tails isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://tails.net/torrents/files/tails-amd64-$RELEASE.iso.torrent"
	fi

	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://tails.net/torrents/files/tails-amd64-$RELEASE.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to TailsOS $RELEASE"
	else
		echo "TailOS is updated..."
	fi
}

debian() {
	echo "Checking if Debian is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep debian | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep debian | awk '{print $NF}' | cut -d "-" -f 2`
	local RELEASE=`curl -s https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/ | grep "amd64-netinst.iso.torrent" | grep -v "edu\|mac" | grep -o '[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+' | sort -V | tail -n1`

	[ -z "$RELEASE" ] && notify Debian && return

	if [ -z "$CURRENT" ]; then
		echo "Debian isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-$RELEASE-amd64-netinst.iso.torrent"
	fi
	
	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-$RELEASE-amd64-netinst.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Debian $RELEASE"
	else
		echo "Debian is updated..."
	fi
}

elementary() {
    echo "Checking if elementaryOS is updated..."
    local CURRENT_ID=`$TRANSMISSION --list | grep elementary| awk '{print $1}'`
    local CURRENT=`$TRANSMISSION --list | grep elementary | awk '{print $NF}' | cut -d "-" -f 2`
    local RELEASE=`curl -s https://elementary.io | grep magnet | grep -o "elementaryos.*\.iso&" | cut -d - -f 2`

	[ -z "$RELEASE" ] && notify ElementaryOS && return

	if [ -z "$CURRENT" ]; then
		echo "ElementaryOS isn't in the download directory. Downloading it..."
        $TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a https://elementary.io/`curl -s https://elementary.io | grep -o "magnet:.*\.iso"`
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -C
    then
        $TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a https://elementary.io/`curl -s https://elementary.io | grep -o "magnet:.*\.iso"`
        $TRANSMISSION -t $CURRENT_ID --remove-and-delete
        echo "Updating to ElementaryOS $RELEASE"
	else
		echo "ElementaryOS is updated..."
    fi
}

tinyServer() {
    echo "Checking if TinyCore Server is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep ^Core | grep -o "[[:digit:]]\+\.[[:digit:]]\+"`
    local RELEASE=`curl -s http://tinycorelinux.net/ | grep "The latest version" | grep -o "[[:digit:]]\+\.[[:digit:]]\+"`

	[ -z "$RELEASE" ] && notify TinyCoreOS && return

	if [ -z "$CURRENT" ]; then
		echo "TinyCore isn't in the download directory. Downloading it..."
        zsync -o $DOWNLOAD_DIR/Core-$RELEASE.iso http://tinycorelinux.net/${RELEASE%.*}.x/x86/release/Core-$RELEASE.iso.zsync
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -C
    then
		rm $DOWNLOAD_DIR/Core-$CURRENT.iso
        echo "Updating to TinyCore Server $RELEASE"
        zsync -o $DOWNLOAD_DIR/Core-$RELEASE.iso http://tinycorelinux.net/${RELEASE%.*}.x/x86/release/Core-$RELEASE.iso.zsync
	else
		echo "TinyCore is updated..."
    fi
}

zorinos() {
    echo "Checking if ZorinOS is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep Zorin | cut -d - -f 3`
    local RELEASE=`curl -s https://distro.ibiblio.org/zorinos/ | awk -F 'href="' '/<a/{gsub(/".*/, "", $2); print $2}' | cut -d / -f 1 | sort -r | head -n1`
	local RELEASE_VER=`curl -s https://distro.ibiblio.org/zorinos/$RELEASE/ | awk -F 'href="' '/<a/{gsub(/".*/, "", $2); print $2}' | cut -d - -f 3 | sort -V | tail -n1`

	[ -z "$RELEASE" ] && notify ZorinOS && return

	if [ -z "$CURRENT" ]; then
		echo "ZorinOS isn't in the download directory. Downloading it..."
		curl -o $DOWNLOAD_DIR/Zorin-OS-$RELEASE_VER-Core-64-bit.iso https://distro.ibiblio.org/zorinos/$RELEASE/Zorin-OS-$RELEASE_VER-Core-64-bit.iso
	fi

    if ! printf "$RELEASE_VER\n$CURRENT" | sort -C
    then
		rm $DOWNLOAD_DIR/Zorin*
        echo "Updating ZorinOs $RELEASE_VER"
		curl -o $DOWNLOAD_DIR/Zorin-OS-$RELEASE_VER-Core-64-bit.iso https://distro.ibiblio.org/zorinos/$RELEASE/Zorin-OS-$RELEASE_VER-Core-64-bit.iso
	else
		echo "ZorinOS is updated..."
    fi
}

grml() {
	echo "Checking if GRML is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep grml | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep grml | awk '{print $NF}' | grep -o "[[:digit:]]\+.[[:digit:]]\+"`
	local RELEASE=`curl -s https://grml.org/download/ | grep -i "Download Grml" | grep -o "[[:digit:]]\+\.[[:digit:]]\+"`

	[ -z "$RELEASE" ] && notify "GRML Linux" && return

	if [ -z "$CURRENT" ]; then
		echo "Grml isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://download.grml.org/grml64-full_${RELEASE}.iso.torrent"
	fi

	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://download.grml.org/grml64-full_${RELEASE}.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Grml $RELEASE"
	else
		echo "GRML Linux is updated..."
	fi
}

clonezilla() {
    echo "Checking if CloneZilla is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep CloneZilla | grep -o "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-[[:digit:]]\+"`
    local RELEASE=`curl -s "https://clonezilla.org/downloads/download.php?branch=stable" | grep "Clonezilla live version" | grep -o "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-[[:digit:]]\+"`

	[ -z "$RELEASE" ] && notify CloneZilla && return

	if [ -z "$CURRENT" ]; then
		echo "CloneZilla isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/CloneZilla-live-$RELEASE-amd64.iso -L https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/$RELEASE/clonezilla-live-$RELEASE-amd64.iso/download
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/CloneZilla*
        echo "Updating CloneZilla $RELEASE"
		curl -s -o $DOWNLOAD_DIR/CloneZilla-live-$RELEASE-amd64.iso -L https://sourceforge.net/projects/clonezilla/files/clonezilla_live_stable/$RELEASE/clonezilla-live-$RELEASE-amd64.iso/download
	else
		echo "CloneZilla is updated..."
    fi
}

gparted() {
    echo "Checking if GParted is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep gparted | grep -o "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-[[:digit:]]\+"`
    local RELEASE=`curl -s https://sourceforge.net/projects/gparted/files/gparted-live-stable/ | grep "<a href=\"/projects/gparted/files/gparted-live-stable/" | grep -o "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+-[[:digit:]]\+" | sort -Vr | head -n1`

	[ -z "$RELEASE" ] && notify GParted && return

	if [ -z "$CURRENT" ]; then
		echo "GParted isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/gparted-live-$RELEASE-amd64.iso -L https://sourceforge.net/projects/gparted/files/gparted-live-stable/$RELEASE/gparted-live-$RELEASE-amd64.iso/download
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/gparted*
        echo "Updating GParted $RELEASE"
		curl -s -o $DOWNLOAD_DIR/gparted-live-$RELEASE-amd64.iso -L https://sourceforge.net/projects/gparted/files/gparted-live-stable/$RELEASE/gparted-live-$RELEASE-amd64.iso/download
	else
		echo "GParted is updated..."
    fi
}

systemrescue() {
    echo "Checking if System Rescue is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep systemrescue | grep -o "[[:digit:]]\+\.[[:digit:]]\+\(\.[[:digit:]]\+\)\?"`
    local RELEASE=`curl -s https://www.system-rescue.org/Download/ | grep "systemrescue.*.iso" | grep -o "[[:digit:]]\+\.[[:digit:]]\+\(\.[[:digit:]]\)\?" | sort -Vur | head -n1`

	[ -z "$RELEASE" ] && notify SystemRescueCD && return

	if [ -z "$CURRENT" ]; then
		echo "SystemRescue isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/systemrescue-$RELEASE-amd64.iso https://fastly-cdn.system-rescue.org/releases/$RELEASE/systemrescue-$RELEASE-amd64.iso
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/systemrescue*
        echo "Updating SystemRescue $RELEASE"
		curl -s -o $DOWNLOAD_DIR/systemrescue-$RELEASE-amd64.iso https://fastly-cdn.system-rescue.org/releases/$RELEASE/systemrescue-$RELEASE-amd64.iso
	echo "SystemRescue is updated..."
    fi
}

whonix() {
	echo "Checking if Whonix is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep Whonix | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep Whonix | awk '{print $NF}' | grep -o "[[:digit:]]\+\(\.[[:digit:]]\)\+"`
	local RELEASE=`curl -s https://www.whonix.org/wiki/VirtualBox | grep -o "https://download.whonix.org/ova/.*.ova" | cut -d / -f 5 | head -n1`

	[ -z "$RELEASE" ] && notify WhoNIX && return

	if [ -z "$CURRENT" ]; then
		echo "Whonix isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://download.whonix.org/ova/$RELEASE/Whonix-Xfce-$RELEASE.ova.torrent"
		# $TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://download.whonix.org/ova/$RELEASE/Whonix-CLI-$RELEASE.ova.torrent"
	fi

	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://download.whonix.org/ova/$RELEASE/Whonix-Xfce-$RELEASE.ova.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Whonix $RELEASE"
	else
		echo "Whonix is updated..."
	fi
}

finnix() {
	echo "Checking if Finnix is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep finnix | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep finnix | awk '{print $NF}' | grep -o "[[:digit:]]\+"`
	local RELEASE=`curl -s https://ftp-nyc.osuosl.org/pub/finnix/current/ | grep -o "finnix.*\.iso" | grep -o "[[:digit:]]\+" | head -n1`

	[ -z "$RELEASE" ] && notify Finnix && return

	if [ -z "$CURRENT" ]; then
		echo "Finnix isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://ftp-nyc.osuosl.org/pub/finnix/current/finnix-$RELEASE.iso.torrent"
	fi

	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://ftp-nyc.osuosl.org/pub/finnix/current/finnix-$RELEASE.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Finnix $RELEASE"
	else
		echo "Finnix is updated..."
	fi
}

openfyde() {
    echo "Checking if OpenFyde is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep openfyde | grep -o "r[[:digit:]]\+\(-r[[:digit:]]\+\)\?"`
    local RELEASE=`curl -fsSIL https://github.com/openFyde/overlay-amd64-openfyde/releases/latest | grep -i "^Location: " | awk -F '/' '{print $NF}' | sed 's/\r//g'`

	[ -z "$RELEASE" ] && notify OpenFyde && return

	if [ -z "$CURRENT" ]; then
		echo "OpenFyde isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/amd64-openfyde-$RELEASE.img.xz -L https://github.com/openFyde/overlay-amd64-openfyde/releases/download/$RELEASE/amd64-openfyde-$RELEASE.img.xz
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/*openfyde*
        echo "Updating OpenFyde $RELEASE"
		curl -s -o $DOWNLOAD_DIR/amd64-openfyde-$RELEASE.img.xz -L https://github.com/openFyde/overlay-amd64-openfyde/releases/download/$RELEASE/amd64-openfyde-$RELEASE.img.xz
	else
		echo "OpenFyde is updated..."
    fi
}

antix() {
	echo "Checking if antix is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep antiX | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep antiX | awk '{print $NF}' | grep -o "[[:digit:]]\+\.[[:digit:]]\+"`
	local RELEASE=`curl -s https://l2.mxrepo.com/torrents/ | grep -o "antiX.*\.iso" | grep -o "[[:digit:]]\+\.[[:digit:]]\+" | head -n1`

	[ -z "$RELEASE" ] && notify antiX && return

	if [ -z "$CURRENT" ]; then
		echo "AntiX isn't in the download directory. Downloading it..."
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://l2.mxrepo.com/torrents/antiX-${RELEASE}_x64-core.iso.torrent"
	fi

	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://l2.mxrepo.com/torrents/antiX-${RELEASE}_x64-core.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to AntiX $RELEASE"
	else
		echo "AntiX is updated..."
	fi
}

main $@
