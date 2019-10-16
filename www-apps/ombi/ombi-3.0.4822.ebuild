# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI=2
inherit eutils user systemd

DESCRIPTION="Want a Movie or TV Show on Plex or Emby? Use Ombi! Ombi is a self-hosted web application that automatically gives your shared Plex or Emby users the ability to request content by themselves! Ombi can be linked to multiple TV Show and Movie DVR tools to create a seamless end-to-end experience for your users."
HOMEPAGE="https://github.com/tidusjar/Ombi"
SRC_URI="http://repo.ombi.turd.me/develop/pool/main/o/ombi/ombi_${PV}_amd64.deb"

SLOT="0"
LICENSE="GPL-2"
KEYWORDS="-* ~amd64"
IUSE="systemd"


RDEPEND="sys-libs/libunwind 
		 net-misc/curl[ssl]"

DEPEND="${RDEPEND}"

INIT_SCRIPT="${ROOT}/etc/init.d/ombi"

pkg_setup() {
	enewgroup ombi
	enewuser ombi -1 -1 /opt/Ombi ombi
}

pkg_preinst() {
	einfo "Unpacking DEB File"
	
	cd "${WORKDIR}"
	ar x "${DISTDIR}/${A}"
	mkdir data
	tar -Jxf data.tar.xz -C data
	
	#einfo "Preparing files for installation"
	# delete systemd debian
	rm -r data/lib
	# remove debian specific useless files
	rm -r data/usr
	
	# as the patch doesn't seem to correctly set the permissions on new files do this now
	# now copy to image directory for actual installation
	cp -R data/* "${D}" || die "install cp failed"
	
	einfo "Preparing config directory"
	mkdir "${D}"etc/Ombi
	chown -R ombi:ombi "${D}"etc/Ombi
	
	einfo "preparing logging targets"
	# make sure the logging directory is created
	mkdir -p "${D}"var/log
	touch "${D}"var/log/ombi.log
	chown ombi:ombi "${D}"var/log/ombi.log
	
	einfo "Stopping running instances of Ombi"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

src_install() {
	if use systemd; then
		systemd_newunit "${FILESDIR}"/ombi.service ombi.service
	fi
	newinitd ${FILESDIR}/ombi.init ombi
	newconfd ${FILESDIR}/ombi.conf ombi
}

pkg_prerm() {
	einfo "Stopping running instances of Ombi"
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_postinst() {
	einfo ""
	elog "Ombi is now fully installed. Please check the configuration file in /etc/Ombi."
	elog "To start please call '/etc/init.d/ombi start'. You can manage afterwards by navigating to http://<ip>:5000/"
	einfo ""
	elog "Setup auto start daemon init.d:"
	elog "# rc-update add ombi default"
	einfo ""
	if use systemd; then
		elog "Setup auto start daemon systemd:"
		elog "# systemctl enable urbackup-server.service"
		elog ""
	fi
}