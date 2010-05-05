--[[
Copyright (c) 2010 MTA: Paradise

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program. If not, see <http://www.gnu.org/licenses/>.
]]

local p = { }
local factions = { }

local function loadFaction( factionID, name, factionType )
	factions[ factionID ] = { name = name, factionType = factionType }
end

local function loadPlayer( player )
	local characterID = exports.players:getCharacterID( player )
	if characterID then
		p[ player ] = { factions = { }, rfactions = { }, types = { } }
		local result = exports.sql:query_assoc( "SELECT factionID FROM character_to_factions WHERE characterID = " .. characterID )
		for key, value in ipairs( result ) do
			local factionID = value.factionID
			if factions[ factionID ] then
				table.insert( p[ player ].factions, factionID )
				p[ player ].rfactions[ factionID ] = true
				p[ player ].types[ factions[ factionID ].factionType ] = true
				outputDebugString( "Set " .. getPlayerName( player ):gsub( "_", " " ) .. " to " .. factions[ factionID ].name )
			else
				outputDebugString( "Faction " .. factionID .. " does not exist, removing players from it." )
				-- exports.sql:query_assoc( "DELETE FROM characters_to_factions WHERE factionID = " .. factionID )
			end
		end
	end
end

addEventHandler( "onResourceStart", resourceRoot,
	function( )
		if not exports.sql:create_table( 'factions',
			{
				{ name = 'factionID', type = 'int(10) unsigned', auto_increment = true, primary_key = true },
				{ name = 'groupID', type = 'int(10) unsigned' }, -- see wcf1_group
				{ name = 'factionType', type = 'tinyint(3) unsigned' }, -- we do NOT have hardcoded factions or names of those.
			} ) then cancelEvent( ) return end
		
		if not exports.sql:create_table( 'character_to_factions',
		{
			{ name = 'characterID', type = 'int(10) unsigned', default = 0, primary_key = true },
			{ name = 'factionID', type = 'int(10) unsigned', default = 0, primary_key = true },
			} ) then cancelEvent( ) return end
		
		--
		
		local result = exports.sql:query_assoc( "SELECT f.*, g.groupName FROM factions f LEFT JOIN wcf1_group g ON f.groupID = g.groupID" )
		for key, value in ipairs( result ) do
			if value.groupName then
				loadFaction( value.factionID, value.groupName, value.factionType )
			else
				outputDebugString( "Faction " .. value.factionID .. " has no valid group. Ignoring..." )
			end
		end
		
		--
		
		for key, value in ipairs( getElementsByType( "player" ) ) do
			if exports.players:isLoggedIn( value ) then
				loadPlayer( value )
			end
		end
	end
)

addEventHandler( "onCharacterLogin", root,
	function( )
		loadPlayer( source )
	end
)

addEventHandler( "onCharacterLogout", root,
	function( )
		p[ source ] = nil
	end
)

addEventHandler( "onPlayerQuit", root,
	function( )
		p[ source ] = nil
	end
)

--

function getPlayerFactions( player )
	return p[ player ] and p[ player ].factions or false
end

function sendMessageToFaction( factionID, message, ... )
	if factions[ factionID ] then
		for key, value in pairs( p ) do
			if value.rfactions[ factionID ] then
				outputChatBox( message, key, ... )
			end
		end
		return true
	end
	return false
end

function isPlayerInFactionType( player, type )
	return p[ player ] and p[ player ].types and p[ player ].types[ type ] or false
end
