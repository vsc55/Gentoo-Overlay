# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="7"

inherit eutils user

MAGIC1="2261"
MAGIC2="a17e99e"
URI="http://downloads.plexapp.com/plex-media-server"

DESCRIPTION="Plex Media Server is a free media library that is intended for use with a plex client available for OS X, iOS and Android systems. It is a standalone product which can be used in conjunction with every program, that knows the API. For managing the library a web based interface is provided."
HOMEPAGE="http://www.plex.tv/"
KEYWORDS="-* x86 amd64"
SRC_URI="
	x86?	( ${URI}/${PV}-${MAGIC2}/plexmediaserver_${PV}-${MAGIC2}_i386.deb )
	amd64?	( ${URI}/${PV}-${MAGIC2}/plexmediaserver_${PV}-${MAGIC2}_amd64.deb )
"
SLOT="0"
LICENSE="PMS-License"
IUSE="systemd"

#RESTRICT="fetch"

RDEPEND="net-dns/avahi"
DEPEND="${RDEPEND}"

INIT_SCRIPT="${ROOT}/etc/init.d/plex-media-server"

pkg_setup() {
	enewgroup plex
	enewuser plex -1 /bin/bash /var/lib/plexmediaserver "plex" --system
}

pkg_preinst() {
	einfo "Unpacking DEB File"
	cd ${WORKDIR}
	ar x ${DISTDIR}/${A}
        mkdir data
        mkdir control
        tar -xzf data.tar.gz -C data
        tar -xzf control.tar.gz -C control

	einfo "Preparing files for installation"
	# replace debian specific init scripts with gentoo specific ones
        rm data/etc/init.d/plexmediaserver
		rm -r data/etc/init
		cp "${FILESDIR}"/pms_initd_1 data/etc/init.d/plex-media-server
		chmod 755 data/etc/init.d/plex-media-server


	einfo "moving config files"
	# move the config to the correct place
		mkdir data/etc/plex
		mv data/etc/default/plexmediaserver data/etc/plex/plexmediaserver.conf
		rmdir data/etc/default

		
	if ! use systemd; then
		einfo "delete systemd"
		rmdir data/lib
	fi
	
	
	einfo "patching startup"
	# apply patch for start_pms to use the new config file
		cd data/usr/sbin
		epatch "${FILESDIR}"/start_pms_1.patch
		cd ../../..
		# remove debian specific useless files
		rm data/usr/share/doc/plexmediaserver/README.Debian
		# as the patch doesn't seem to correctly set the
		# permissions on new files do this now
		# now copy to image directory for actual
		# installation
		cp -R data/* "${D}"
	
	
	einfo "preparing logging targets"
	# make sure the logging directory is created
		mkdir "${D}"var
		mkdir "${D}"var/log
		mkdir "${D}"var/log/pms
		chown plex:plex "${D}"var/log/pms


	einfo "prepare default library destination"
		# also make sure the default library folder is pre created with correct
		# permissions
		mkdir "${D}"var/lib
		mkdir "${D}"var/lib/plexmediaserver
		chown plex:plex "${D}"var/lib/plexmediaserver
	
	
	einfo "Stopping running instances of Media Server"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}


pkg_prerm() {
	einfo "Stopping running instances of Media Server"
        if [ -e "${INIT_SCRIPT}" ]; then
                ${INIT_SCRIPT} stop
        fi
}

pkg_postinst() {
	einfo ""
	elog "Plex Media Server is now fully installed. Please check the configuration file in /etc/plex if the defaults please your needs."
	elog "To start please call '/etc/init.d/plex-media-server start'. You can manage your library afterwards by navigating to http://<ip>:32400/web/"
	einfo ""
	ewarn "Please note, that the URL to the library management has changed from http://<ip>:32400/manage to http://<ip>:32400/web!"
	ewarn "If the new management interface forces you to log into myPlex and afterwards gives you an error that you need to be a plex-pass"
	ewarn "subscriber please delete the folder WebClient.bundle inside the Plug-Ins folder found in your library!"
	einfo ""
}
