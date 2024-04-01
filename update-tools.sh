#!/bin/bash

type curl > /dev/null 2>&1 || (echo "ERROR: curl must be installed." >&2 && exit 1)
type awk > /dev/null 2>&1 || (echo "ERROR: awk must be installed." >&2 && exit 1)

notify() {
	[ -n "$NTFY_TOPIC" ] && \
		curl -s \
		-H "Title: Failed to fetch $*" \
		-H "Priority: default" \
		-H "Tags: warning" \
		-d "Review the $* function for necessary updates on the code" \
		ntfy.sh/$NTFY_TOPIC
}

firefox() {
    echo "Checking if firefox is updated..."
    local CURRENT=`find $DOWNLOAD_DIR -iname firefox* | head -n1 | grep -o "[[:digit:]]\+\(\.[[:digit:]]\+\)\+"`
	local RELEASE=`curl -fsSIL "https://www.mozilla.org/en-US/firefox/notes/" | grep -i "^Location: " | cut -d / -f 4`

	[ -z "$RELEASE" ] && notify "Firefox" && return

	if [ -z $CURRENT ]; then
		echo "Firefox isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/firefox-$RELEASE.exe -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=win&lang=es-ES"
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/firefox-$RELEASE.exe -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=es-ES"
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		find $DOWNLOAD_DIR -iname firefox* -delete
        echo "Updating Firefox to $RELEASE"
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/firefox-$RELEASE.exe -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=win&lang=es-ES"
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/firefox-$RELEASE.exe -L "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=es-ES"
    fi
}

gdrive() {
    echo "Checking if Google Drive is updated..."
    local CURRENT=`ls $DOWNLOAD_DIR | grep gdrive* | grep -o "[[:digit:]]\+\(\.[[:digit:]]\+\)\+"`
    local RELEASE=`curl -sL "https://support.google.com/a/answer/7577057?hl=es" | grep -o "versión [[:digit:]]\+\.[[:digit:]]\+" | awk '{print $2}' | head -n1`

	[ -z "$RELEASE" ] && notify "Google Drive" && return

	if [ -z $CURRENT ]; then
		echo "Google Drive isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/gdrive-$RELEASE.exe -L https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/gdrive*
        echo "Updating Google Drive to $RELEASE"
		curl -s -o $DOWNLOAD_DIR/gdrive-$RELEASE.exe -L https://dl.google.com/drive-file-stream/GoogleDriveSetup.exe
    fi
}

sumatrapdf() {
    echo "Checking if SumatraPDF is updated..."
    local CURRENT=`find $DOWNLOAD_DIR -iname sumatrapdf* | head -n1 | grep -o "[[:digit:]]\+\(\.[[:digit:]]\)\+"`
    local RELEASE=`curl -sL https://www.sumatrapdfreader.org/free-pdf-reader | grep "Latest release" | grep -o "[[:digit:]]\+\(\.[[:digit:]]\)\+"`

	[ -z "$RELEASE" ] && notify "SumatraPDF" && return

	if [ -z $CURRENT ]; then
		echo "SumatraPDF isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/SumatraPDF-$RELEASE-install.exe -L https://www.sumatrapdfreader.org/dl/rel/$RELEASE/SumatraPDF-$RELEASE-install.exe
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/SumatraPDF-$RELEASE-64-install.exe -L https://www.sumatrapdfreader.org/dl/rel/$RELEASE/SumatraPDF-$RELEASE-64-install.exe
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		find $DOWNLOAD_DIR -iname Sumatra* -delete
        echo "Updating SumatraPDF to $RELEASE"
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/SumatraPDF-$RELEASE-install.exe -L https://www.sumatrapdfreader.org/dl/rel/$RELEASE/SumatraPDF-$RELEASE-install.exe
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/SumatraPDF-$RELEASE-64-install.exe -L https://www.sumatrapdfreader.org/dl/rel/$RELEASE/SumatraPDF-$RELEASE-64-install.exe
    fi
}

7zip() {
    echo "Checking if 7zip is updated..."
    local CURRENT=`find $DOWNLOAD_DIR -iname 7z* -exec basename {} + | head -n1 | grep -o "[[:digit:]][[:digit:]]\+"`
    local RELEASE=`curl -sL https://www.7-zip.org/ | grep Download | grep -o "[[:digit:]]\+\.[[:digit:]]\+" | head -n1 | tr -d '.'`

	[ -z "$RELEASE" ] && notify "7zip" && return

	if [ -z $CURRENT ]; then
		echo "7zip isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/7z$RELEASE.exe https://www.7-zip.org/a/7z$RELEASE.exe
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/7z$RELEASE.exe https://www.7-zip.org/a/7z$RELEASE-x64.exe
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		find $DOWNLOAD_DIR -iname 7z* -delete
        echo "Updating 7zip to $RELEASE"
		curl -s -o "$DOWNLOAD_DIR/Windows 32 bits/7z$RELEASE.exe" https://www.7-zip.org/a/7z$RELEASE.exe
		curl -s -o "$DOWNLOAD_DIR/Windows 64 bits/7z$RELEASE.exe" https://www.7-zip.org/a/7z$RELEASE-x64.exe
    fi
}

rufus() {
    echo "Checking if Rufus is updated..."
    local CURRENT=`find $DOWNLOAD_DIR -iname rufus* | head -n1 | grep -o "[[:digit:]]\+\.[[:digit:]]\+"`
    local RELEASE=`curl -sL https://rufus.ie/downloads/ | grep -o ">rufus.*.exe" | grep -o "[[:digit:]]\+\.[[:digit:]]\+\(\.[[:digit:]]\+\)\?" | sort -Vur | head -n1`

	[ -z "$RELEASE" ] && notify "Rufus" && return

	if [ -z $CURRENT ]; then
		echo "Rufus isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/rufus-$RELEASE.exe https://github.com/pbatard/rufus/releases/download/v$RELEASE/rufus-${RELEASE}_x86.exe
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/rufus-$RELEASE.exe https://github.com/pbatard/rufus/releases/download/v$RELEASE/rufus-$RELEASE.exe
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		find $DOWNLOAD_DIR -iname rufus* -delete
        echo "Updating Rufus to $RELEASE"
		curl -s -o $DOWNLOAD_DIR/Windows\ 32\ bits/rufus-$RELEASE.exe https://github.com/pbatard/rufus/releases/download/v$RELEASE/rufus-${RELEASE}_x86.exe
		curl -s -o $DOWNLOAD_DIR/Windows\ 64\ bits/rufus-$RELEASE.exe https://github.com/pbatard/rufus/releases/download/v$RELEASE/rufus-$RELEASE.exe
    fi
}

ventoy() {
    echo "Checking if Ventoy is updated..."
    local CURRENT=`find $DOWNLOAD_DIR -iname ventoy* | head -n1 | cut -d - -f 2`
    local RELEASE=`curl -sL https://www.ventoy.net/en/download.html | grep -o "\"version\":.*" | grep -o "[[:digit:]]\+\.[[:digit:]]\+\.[[:digit:]]\+" | head -n1`

	[ -z "$RELEASE" ] && notify "Ventoy" && return

	if [ -z $CURRENT ]; then
		echo "Ventoy isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/ventoy-$RELEASE-windows.zip -L https://sourceforge.net/projects/ventoy/files/latest/download
		curl -s -o $DOWNLOAD_DIR/ventoy-$RELEASE-linux.tar.gz -L https://sourceforge.net/projects/ventoy/files/v$RELEASE/ventoy-$RELEASE-linux.tar.gz/download
		curl -s -o $DOWNLOAD_DIR/ventoy-$RELEASE-livecd.iso -L https://sourceforge.net/projects/ventoy/files/v$RELEASE/ventoy-$RELEASE-livecd.iso/download
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/ventoy*
        echo "Updating Ventoy to $RELEASE"
		curl -s -o $DOWNLOAD_DIR/ventoy-$RELEASE-windows.zip -L https://sourceforge.net/projects/ventoy/files/latest/download
		curl -s -o $DOWNLOAD_DIR/ventoy-$RELEASE-linux.tar.gz -L https://sourceforge.net/projects/ventoy/files/v$RELEASE/ventoy-$RELEASE-linux.tar.gz/download
		curl -s -o $DOWNLOAD_DIR/ventoy-$RELEASE-livecd.iso -L https://sourceforge.net/projects/ventoy/files/v$RELEASE/ventoy-$RELEASE-livecd.iso/download
    fi
}

iventoy() {
    echo "Checking if iVentoy is updated..."
    local CURRENT=`find $DOWNLOAD_DIR -iname iventoy* | head -n1 | cut -d - -f 2`
    local RELEASE=`curl -sL https://github.com/ventoy/PXE/releases/latest | grep -o -i "iventoy .* release" | head -n1 | grep -o "[[:digit:]]\+\(\.[[:digit:]]\+\)\+"`

	[ -z "$RELEASE" ] && notify "iVentoy" && return

	if [ -z $CURRENT ]; then
		echo "iVentoy isn't in the download directory. Downloading it..."
		curl -s -o $DOWNLOAD_DIR/iventoy-$RELEASE-linux-free.tar.gz -L https://github.com/ventoy/PXE/releases/download/v$RELEASE/iventoy-$RELEASE-linux-free.tar.gz
	fi

    if ! printf "$RELEASE\n$CURRENT" | sort -VC
    then
		rm $DOWNLOAD_DIR/iventoy*
        echo "Updating iVentoy to $RELEASE"
		curl -s -o $DOWNLOAD_DIR/iventoy-$RELEASE-linux-free.tar.gz -L https://github.com/ventoy/PXE/releases/download/v$RELEASE/iventoy-$RELEASE-linux-free.tar.gz
    fi
}

help_msg() {
	printf "usage: `basename $0` [-d <distros>]\n\n"
cat << EOF
Update common windows applications.

Args:
-d	<DIR>	Download directory

Options:

-h		Show this help message
-t	<TOOL>	List of the tools to be updated. (comma separated)
-n	<TOPIC>	Topic to be subscribed on ntfy.sh
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
				local TOOLS="$2"
				shift
				;;
			-n)
				NTFY_TOPIC=$2
				shift
				;;
			-d)
				DOWNLOAD_DIR=$2
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

	[ -z "$DOWNLOAD_DIR" ] && echo "ERROR: You must set a directory for downloads" >&2 && exit 1

	if $DEFAULT; then
		FUNCTIONS=`declare -F | grep -Ev "help|main|notify" | awk '{print $3}'`
		for FUNCTION in $FUNCTIONS; do
			$FUNCTION 2>/dev/null || echo "$FUNCTION is not defined" >&2
		done
	else
		for TOOL in `echo "$TOOLS" | tr , ' '`; do
			$TOOL 2>/dev/null || echo "$TOOL is not defined" >&2
		done
	fi
}

main $@
