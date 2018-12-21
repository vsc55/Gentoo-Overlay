# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils user

DESCRIPTION="Cliente UrBackup, permite hacer copias de sguridad de documentos de todos los puestos de la red."
HOMEPAGE="http://www.urbackup.org"
KEYWORDS="x86 amd64"
SRC_URI="https://hndl.urbackup.org/Client/${PV}/${P}.tar.gz"
SLOT="0"
LICENSE="GPL-3"
IUSE=""

RDEPEND="dev-libs/crypto++ 
	     x11-libs/wxGTK
		 sys-libs/zlib"
DEPEND="${RDEPEND}"


INIT_SCRIPT_OLD="${ROOT}/etc/init.d/urbackup_client"
INIT_SCRIPT="${ROOT}/etc/init.d/urbackupclientbackend"
S="${WORKDIR}/${P}.0"

src_configure() {
	cd "${S}"
	econf
}

src_compile() {
	cd "${S}"
	emake DESTDIR="${D}"
}

src_install() {
	cd "${S}"
	emake DESTDIR="${D}" install
	
	insinto /etc/conf.d ; newins ${FILESDIR}/urbackupclientbackend.conf_v2 urbackupclientbackend
	exeinto /etc/init.d ; newexe ${FILESDIR}/urbackupclientbackend.init_v2 urbackupclientbackend
	
	insinto /etc/urbackup ; newins ${FILESDIR}/urbackupclient.defaults_client urbackupclient
}

pkg_preinst() {
	# Mata el proceso antes de copiar la nueva version de programa al HD.
	einfo "Stopping running instances of UrBackup Server"
	if [ -e "${INIT_SCRIPT_OLD}" ]; then
		${INIT_SCRIPT_OLD} stop
	fi
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_prerm() {
	# Mata el proceso antes de desintalar.
	einfo "Stopping running instances of UrBackup Client"
	if [ -e "${INIT_SCRIPT_OLD}" ]; then
		${INIT_SCRIPT_OLD} stop
	fi
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_postinst() {
	einfo ""
	elog "Setup auto start daemon:"
	elog "# rc-update add urbackupclientbackend default"
	elog ""
	elog "Start service:"
	elog "# /etc/init.d/urbackupclientbackend start"
	einfo ""
	elog "Start the UrBackup client frontend and setup your paths by executing:"
	elog "# urbackupclientgui"
	elog "and clicking on the tray icon and add paths. You can also do that on the server."
	einfo ""
	#If your distribution is not Debian or Debian based you have to either build your own init script or just put /usr/local/sbin/urbackupsrv run -d into /etc/rc.local.
}
