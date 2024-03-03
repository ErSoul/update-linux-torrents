#!/bin/bash

type curl > /dev/null 2>&1 || (echo "ERROR: curl must be installed." >&2 && exit 1)
type awk > /dev/null 2>&1 || (echo "ERROR: awk must be installed." >&2 && exit 1)
type transmission-remote > /dev/null 2>&1 || (echo "ERROR: transmission must be installed." >&2 && exit 1)

TRANSMISSION="transmission-remote --auth transmission:transmission"
DOWNLOAD_DIR="/srv/DATA/ISOS"

ubuntu() {
	echo "Checking if Ubuntu is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep ubuntu | awk '{print $1}'`
	local CURRENT_NAME=`$TRANSMISSION --list | grep ubuntu | awk '{print $10}'`
	local CURRENT_VER=`echo $CURRENT_NAME | cut -d "-" -f 2`
	local RELEASE_VER=`curl -s https://releases.ubuntu.com/ | grep LTS | grep -o '[[:digit:]]\+\.[[:digit:]]\+\(\.[[:digit:]]\+\)\?' | sort -V | tail -n1`
	
	if ! printf "$RELEASE_VER\n$CURRENT_VER" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://releases.ubuntu.com/$RELEASE_VER/ubuntu-$RELEASE_VER-live-server-amd64.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Ubuntu $RELEASE_VER"
	fi
}

kali() {
	echo "Checking if Kali is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep kali | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep kali | awk '{print $10}' | cut -d "-" -f 3`
	local RELEASE=`curl -s https://cdimage.kali.org/current/ | grep -o kali-linux-.*-live-amd64.iso.torrent | grep -o '[[:digit:]]\+\.[[:digit:]]' | sort -V | tail -n1`
	
	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://cdimage.kali.org/kali-$RELEASE/kali-linux-$RELEASE-live-amd64.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Kali Linux $RELEASE"
	fi
}

tails() {
	echo "Checking if TailsOS is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep tails | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep tails | awk '{print $10}' | cut -d "-" -f 3`
	local RELEASE=`curl -s https://tails.net/torrents/files/ | grep -o tails-amd64-.*.iso.torrent | grep -v rc | grep -o '[[:digit:]]\+\.[[:digit:]]\+' | sort -V | tail -n1`
	
	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://tails.net/torrents/files/tails-amd64-$RELEASE.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to TailsOS $RELEASE"
	fi
}

debian() {
	echo "Checking if Debian is updated..."
	local CURRENT_ID=`$TRANSMISSION --list | grep debian | awk '{print $1}'`
	local CURRENT=`$TRANSMISSION --list | grep debian | awk '{print $10}' | cut -d "-" -f 2`
	local RELEASE=`curl -s https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/ | grep "amd64-netinst.iso.torrent" | grep -v "edu\|mac" | grep -o '[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+' | sort -V | tail -n1`
	
	if ! printf "$RELEASE\n$CURRENT" | sort -C
	then
		$TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a "https://cdimage.debian.org/debian-cd/current/amd64/bt-cd/debian-$RELEASE-amd64-netinst.iso.torrent"
		$TRANSMISSION -t $CURRENT_ID --remove-and-delete
		echo "Updating to Debian $RELEASE"
	fi
}

elementary() {
    echo "Checking if elementaryOS is updated..."
    local CURRENT_ID=`$TRANSMISSION --list | grep elementary| awk '{print $1}'`
    local CURRENT=`$TRANSMISSION --list | grep elementary | awk '{print $10}' | cut -d "-" -f 2`
    local RELEASE=`curl -s https://elementary.io | grep magnet | grep -o "elementaryos.*\.iso&" | cut -d - -f 2`

    if ! printf "$RELEASE\n$CURRENT" | sort -C
    then
        $TRANSMISSION --trash-torrent --download-dir $DOWNLOAD_DIR -a https://elementary.io/`curl -s https://elementary.io | grep -o "magnet:.*\.iso"`
        $TRANSMISSION -t $CURRENT_ID --remove-and-delete
        echo "Updating to ElementaryOS $RELEASE"
    fi
}

help_msg() {
	printf "usage: `basename $0` [-d <distros>]\n\n"
cat << EOF
Specify linux distributions to be updated with transmission-cli.

Options:

-h		Show this help message
-d <distros>	List of the distro's to be updated. (comma separated)
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
			-d)
				DEFAULT=false
				local DISTROS="$2"
				for DISTRO in `echo $DISTROS | tr , ' '`; do
					$DISTRO 2>/dev/null || echo "$DISTRO is not defined" >&2
				done
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

	! $DEFAULT && exit 0 # Nothing else to do. Avoid default behaviour.

	FUNCTIONS=`declare -F | grep -Ev "help|main" | awk '{print $3}'`
	for FUNCTION in `echo $FUNCTIONS | tr , ' '`; do
		$FUNCTION 2>/dev/null || echo "$FUNCTION is not defined" >&2
	done
}

main $@
