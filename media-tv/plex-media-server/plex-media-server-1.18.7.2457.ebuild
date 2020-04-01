# Copyright 1999-2013 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils user systemd

MAGIC1=${PV}
MAGIC2="77cb9455c"

URI="http://downloads.plex.tv/plex-media-server-new"

DESCRIPTION="Plex Media Server is a free media library that is intended for use with a plex client available for OS X, iOS and Android systems. It is a standalone product which can be used in conjunction with every program, that knows the API. For managing the library a web based interface is provided."
HOMEPAGE="http://www.plex.tv/"

KEYWORDS="-* x86 amd64"
SRC_URI="
	x86?	( ${URI}/${MAGIC1}-${MAGIC2}/debian/plexmediaserver_${MAGIC1}-${MAGIC2}_i386.deb )
	amd64?	( ${URI}/${MAGIC1}-${MAGIC2}/debian/plexmediaserver_${MAGIC1}-${MAGIC2}_amd64.deb )
"
SLOT="0"
LICENSE="Plex"
IUSE="systemd"

DEPEND=""
RDEPEND="net-dns/avahi"

INIT_SCRIPT="${ROOT}/etc/init.d/plex-media-server"

pkg_setup() {
	enewgroup plex
	enewuser plex -1 /bin/bash /var/lib/plexmediaserver "plex,video" --system
}

pkg_preinst() {
	einfo "Unpacking DEB File"
	cd "${WORKDIR}"
	ar x "${DISTDIR}/${A}"
	mkdir data
	tar -Jxf data.tar.xz -C data

	# remove useless files
	rm -fr data/usr/share
	rm -r data/etc/apt
	
	einfo "Preparing config files"
	# config default
	mkdir data/etc/plex
	cp "${FILESDIR}/plexmediaserver.conf" data/etc/plex/plexmediaserver.conf
	
	einfo "Patching Startup"
	# apply patch for start_pms to use the new config file
	cd data/usr/sbin
	epatch "${FILESDIR}"/start_pms_1.18.5.2260.patch || die "patch startup failed"
	cd ../../..
	
	# as the patch doesn't seem to correctly set the permissions on new files do this now
	# now copy to image directory for actual installation
	cp -R data/* "${D}"  || die "install cp failed"
	
	einfo "preparing logging targets"
	# make sure the logging directory is created
	mkdir "${D}"var
	mkdir "${D}"var/log
	mkdir "${D}"var/log/pms
	chown plex:plex "${D}"var/log/pms

	einfo "Prepare default library destination"
	# also make sure the default library folder is pre created with correct permissions
	mkdir "${D}"var/lib
	mkdir "${D}"var/lib/plexmediaserver
	chown plex:plex "${D}"var/lib/plexmediaserver
	
	einfo "Stopping running instances of Media Server"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

src_install() {
	if use systemd; then
		systemd_newunit "${FILESDIR}"/plex-media-server.service plex-media-server.service	
	fi
	newinitd ${FILESDIR}/pms_initd_1 plex-media-server
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