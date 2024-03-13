## Description 

Script to download/update different linux distributions using the most convenient available download tool offered by the respective distribution.

Available distros:

- [Ubuntu](https://ubuntu.com/)
- [Kali Linux](https://www.kali.org/)
- [Tails](https://tails.net/)
- [Debian](https://www.debian.org/)
- [Elementary OS](https://elementary.io/)
- [TinyCore Linux](http://tinycorelinux.net/)
- [Zorin OS](https://zorin.com/os/)
- [Grml Live Linux](https://grml.org/)
- [CloneZilla](https://clonezilla.org/)
- [GParted](https://gparted.org/)
- [SystemRescue](https://www.system-rescue.org/)
- [Whonix](https://www.whonix.org/)

## TODO

- Download directory should be an argument.
- Torrent client credentials should be setted from arguments.
- Verify torrent's ID status (Downloading/Seeding) in case torrent(s) is(are) still downloading and avoid mistakes in consecutives short-time executions of the script. 
- Add preferred download tool option (torrent, zsync, curl). If any of the former tools are not available, default to CURL.
- Check download integrity with available hashing methods.
- Verify download with PGP signatures.
- Offer rtorrent client as an option.
- Add different flavors for the same distribution.
- Separate each distribution function to a different file, and source them to the main file.

## EXAMPLES

Run script daily through crontab:

`0 0 * * * /usr/local/bin/update-distros.sh`

Download only ubuntu:

`update-distros.sh -d ubuntu`

Download Debian and Kali:

`update-distros.sh -d debian,kali`

## NON-POSIX COMPLIANT

The `declare -F` statement at the end of the `main` function is only available for BASH.

