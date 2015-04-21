///////////////////////////////////////////////////////////////
////|         |///|        |///|       |/\  \/////  ///|  |////
////|  |////  |///|  |//|  |///|  |/|  |//\  \///  ////|__|////
////|  |////  |///|  |//|  |///|  |/|  |///\  \/  /////////////
////|          |//|  |//|  |///|       |////\    //////|  |////
////|  |////|  |//|         |//|  |/|  |/////    \/////|  |////
////|  |////|  |//|  |///|  |//|  |/|  |////  /\  \////|  |////
////|  |////|  |//|  | //|  |//|  |/|  |///  ///\  \///|  |////
////|__________|//|__|///|__|//|__|/|__|//__/////\__\//|__|////
///////////////////////////////////////////////////////////////
/*
	BraXi's Death Run Mod
	
	Website: www.braxi.org
	E-mail: paulina1295@o2.pl

	[DO NOT COPY WITHOUT PERMISSION]
*/

#include braxi\_common;

init()
{
	LoadMenu( "about", "mod_about" );
	LoadMenu( "main", "mod_main" );
	LoadMenu( "stats", "mod_stats" );
	
	precacheMenu( "scoreboard" );

	while( 1 )
	{
		level waittill( "connected", player );
		
		player setClientDvars( "ui_3dwaypointtext", "1", "ui_deathicontext", "1" );
		player.enable3DWaypoints = true;
		player.enableDeathIcons = true;
		
		player thread onMenuResponse();
		player openMenu( game["menu_main"] );
	}
}

LoadMenu( scrName, menuName )
{
	game[ "menu_"+scrName ] = menuName;
	precacheMenu( game["menu_"+scrName] );
}


onMenuResponse()
{
	self endon( "disconnect" );

	self setClientDvars( "g_scriptMainMenu", game["menu_main"] );
	wait 1;
	self openMenu( game["menu_main"] );

	while( 1 )
	{
		self waittill( "menuresponse", menu, response );
		
		//iprintln( self getEntityNumber() + " menuresponse: " + menu + " '" + response +"'" );
		//tokens = strTok( response, ":" );

		if ( response == "back" )
		{
			self closeMenu();
			self closeInGameMenu();
			continue;
		}


		if( menu == game["menu_main"] )
		{
			switch(response)
			{
			case "allies":
			case "axis":
			case "autoassign":
				self closeMenu();
				self closeInGameMenu();

				//self braxi\_teams::setTeam( "allies" );
				//self braxi\_mod::spawnPlayer();

				if( game["state"] == "endmap" )
					continue;

				if( game["state"] == "playing" )
				{
					self braxi\_teams::setTeam( "axis" );
					self braxi\_mod::spawnPlayer();
				}
				else
				{
					self braxi\_teams::setTeam( "allies" );
					self braxi\_mod::spawnPlayer();
				}
				break;

			case "spectator":
				self closeMenu();
				self closeInGameMenu();
				self braxi\_teams::setTeam( "spectator" );
				self braxi\_mod::spawnSpectator();
				break;
			}
		}
	}
}
