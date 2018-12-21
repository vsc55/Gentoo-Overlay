# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: $

EAPI="2"

inherit eutils user

DESCRIPTION="Servidor UrBackup, permite hacer copias de sguridad de documentos de todos los puestos de la red."
HOMEPAGE="http://www.urbackup.org"
KEYWORDS="x86 amd64"
SRC_URI="https://hndl.urbackup.org/Server/${PV}/${P}.tar.gz"
SLOT="0"
LICENSE="GPL-3"
IUSE="systemd +logrotate"

RDEPEND="dev-libs/crypto++"
DEPEND="${RDEPEND}"


INIT_SCRIPT_OLD="${ROOT}/etc/init.d/urbackup_srv"
INIT_SCRIPT="${ROOT}/etc/init.d/urbackupsrv"
S="${WORKDIR}/${P}"

pkg_setup() {
	enewgroup urbackup
	enewuser urbackup -1 -1 /var/lib/urbackup  urbackup --system
}

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
	
	insinto /etc/conf.d ; newins ${FILESDIR}/urbackupsrv.conf_v2 urbackupsrv
	exeinto /etc/init.d ; newexe ${FILESDIR}/urbackupsrv.init_v2 urbackupsrv
	insinto /etc/urbackup ; newins ${FILESDIR}/urbackupsrv.defaults_server urbackupsrv
	
	if use systemd; then
		exeinto /etc/systemd/system ; newexe ${FILESDIR}/urbackupsrv.systemd urbackup-server.service
		#systemctl enable urbackup-server.service
	fi
	if use logrotate; then
		insinto /etc/logrotate.d ; newins ${FILESDIR}/urbackupsrv.logrotate urbackupsrv
		#systemctl start urbackup-server
	fi
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
	einfo "Stopping running instances of UrBackup Server"
	if [ -e "${INIT_SCRIPT_OLD}" ]; then
		${INIT_SCRIPT_OLD} stop
	fi
	if [ -e "${INIT_SCRIPT}" ]; then
		${INIT_SCRIPT} stop
	fi
}

pkg_postinst() {
	einfo ""
	elog "Browse to http://localhost:55414 and setup an admin user and the backup storage path."
	elog ""
	elog "Setup auto start daemon:"
	elog "# rc-update add urbackupsrv default"
	elog ""
	elog "Start service:"
	elog "# /etc/init.d/urbackupsrv start"
	einfo ""
	#If your distribution is not Debian or Debian based you have to either build your own init script or just put /usr/local/sbin/urbackupsrv run -d into /etc/rc.local.
}