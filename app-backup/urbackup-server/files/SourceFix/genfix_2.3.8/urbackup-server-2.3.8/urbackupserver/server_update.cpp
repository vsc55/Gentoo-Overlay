/*************************************************************************
*    UrBackup - Client/Server backup system
*    Copyright (C) 2011-2016 Martin Raiber
*
*    This program is free software: you can redistribute it and/or modify
*    it under the terms of the GNU Affero General Public License as published by
*    the Free Software Foundation, either version 3 of the License, or
*    (at your option) any later version.
*
*    This program is distributed in the hope that it will be useful,
*    but WITHOUT ANY WARRANTY; without even the implied warranty of
*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
*    GNU Affero General Public License for more details.
*
*    You should have received a copy of the GNU Affero General Public License
*    along with this program.  If not, see <http://www.gnu.org/licenses/>.
**************************************************************************/
#include "server_update.h"
#include "../urlplugin/IUrlFactory.h"
#include "../Interface/Server.h"
#include "../Interface/File.h"
#include "../stringtools.h"
#include "../urbackupcommon/os_functions.h"
#include "DataplanDb.h"
#include <stdlib.h>
#include <memory>

extern IUrlFactory *url_fak;

namespace
{
	std::string urbackup_update_url = "http://127.0.0.1/";
	std::string urbackup_update_url_alt;

	struct SUpdatePlatform
	{
		SUpdatePlatform(std::string extension,
			std::string basename, std::string versionname)
			: extension(extension), basename(basename),
			versionname(versionname)
		{}
		std::string extension;
		std::string basename;
		std::string versionname;
	};
}

ServerUpdate::ServerUpdate(void)
{
}

void ServerUpdate::update_client()
{
	Server->Log("Option disable. Cannot download client for autoupdate.", LL_INFO);
	return;
}

void ServerUpdate::update_server_version_info()
{
	Server->Log("Option disable. Cannot download server version info.", LL_INFO);
	return;
}

void ServerUpdate::update_dataplan_db()
{
	Server->Log("Option disable. Cannot download dataplan database.", LL_INFO);
	return;
}

void ServerUpdate::read_update_location()
{
	Server->Log("Option disable. Cannot read update location.", LL_INFO);
	return;
}
