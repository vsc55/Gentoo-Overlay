# Copyright 1999-2006 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header:  $

EAPI="2"
inherit eutils versionator rpm user systemd

MY_PV=$(replace_version_separator 3 '-' $(replace_version_separator 4 '-'))
MY_PVA="9.3.0-5349"

IUSE="mta +pam systemd"
DESCRIPTION="Kerio Connect is designed for small and medium-sized businesses, Kerio Connect features integrated mobile email, anti-spam and anti-virus protection, Outlook and Entourage groupware support, Kerio WebMail, archiving and backup. Kerio Connect supports multiple domains and fully supports Active Directory and Apple Open Directory for user management."

SRC_URI=" http://download.kerio.com/dwn/connect/connect-${MY_PVA}/${PN}-${MY_PV}-linux-x86_64.rpm http://cdn.kerio.com/dwn/connect/connect-${MY_PVA}/${PN}-${MY_PV}-linux-x86_64.rpm http://gentoo.cerebelum.net/portage/distfiles/${PN}-${MY_PV}-linux-x86_64.rpm"
HOMEPAGE="http://www.kerio.com/"
SLOT="0"
LICENSE="Kerio"
KEYWORDS="amd64"
RESTRICT="nomirror"
DEPEND=">=sys-apps/util-linux-2.16
	>=dev-libs/glib-2.12.0
	>=sys-libs/glibc-2.10.1-r1
	>=sys-devel/gcc-4.1.2
	app-misc/ca-certificates
	app-admin/sysstat
	sys-process/lsof
	sys-apps/lsb-release
	mta? (
		!net-mail/mailwrapper
		!mail-mta/courier
		!mail-mta/esmtp
		!mail-mta/exim
		!mail-mta/mini-qmail
		!mail-mta/msmtp[mta]
		!mail-mta/nbsmtp
		!mail-mta/netqmail
		!mail-mta/nullmailer
		!mail-mta/postfix
		!mail-mta/qmail-ldap
		!mail-mta/sendmail
		!mail-mta/opensmtpd
		!mail-mta/ssmtp[mta]
	)
"
#	amd64? ( >=app-emulation/emul-linux-x86-baselibs-20140508-r12 )	
PROVIDE="virtual/mta"
RDEPEND="!net-mail/kerio-kms"
#		abi_x86_32? (
#			!<=app-emulation/emul-linux-x86-baselibs-20140508-r12
#			!app-emulation/emul-linux-x86-baselibs[-abi_x86_32(-)]
#		)"


INIT_SCRIPT="${ROOT}/etc/init.d/kerio-connect"
PATH_INSTALL_APP="/opt/kerio/mailserver"

pkg_setup() {
	WORKDIRALL="${WORKDIR}${PATH_INSTALL_APP}"
	enewgroup kerio
	enewuser kerio -1 /bin/bash /opt/kerio/mailserver "kerio" --system
}

src_unpack() {
	rpm_src_unpack
}

src_compile() {
	rm -fr "${WORKDIR}/usr"
	rm -fr "${WORKDIR}/etc/init.d"
	
	if ! use pam; then
		rm -fr "${WORKDIR}/etc/pam.d/"
	fi

}

src_install() {
	dodir ${PATH_INSTALL_APP}
	cp -r * "${D}" || die "install cp failed"
	newinitd ${FILESDIR}/kerio-connect.init_v4 kerio-connect
	newconfd ${FILESDIR}/kerio-connect.conf_v4 kerio-connect

	if use systemd; then
		systemd_newunit "${FILESDIR}"/kerio-connect.systemd_v1 kerio-connect.systemd
	fi
	
	if use mta; then
		dosym /opt/kerio/mailserver/sendmail /usr/sbin/sendmail
		dosym /opt/kerio/mailserver/sendmail /usr/bin/sendmail
		dosym /opt/kerio/mailserver/sendmail /usr/lib/sendmail
	fi
}

pkg_preinst() {
	einfo "Stopping running instances of Kerio Connect"
	if [ `ps -C mailserver | wc -l` -ne 1 ]; then
		if [ -e "${INIT_SCRIPT}" ]; then
			${INIT_SCRIPT} stop
		fi
	fi
	sleep 10
	if [ `ps -C mailserver | wc -l` -ne 1 ]; then
		killall mailserver
	fi
}

pkg_postinst() {
	elog "Kerio Connect Instalado Ok."
	elog ""
	elog "Url Admin: https://127.0.0.1:4040"
	elog ""
	elog "Para que arranque automaticamente PC ejecute	'rc-update add kerio-connect default'."
	elog ""
}
