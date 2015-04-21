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

#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;

#include braxi\_common;
#include braxi\_dvar;

main()
{
	if( !isDefined( level.suiciderModel ) )
		level.suiciderModel = "com_barrel_benzin";


	braxi\_dvar::setupDvars(); // all dvars are there
	precache();
	braxi\_cod4stuff::main(); // setup vanilla cod4 variables
	thread braxi\_bots::addTestClients();
	initScoreboard();

	level.mapName = toLower( getDvar( "mapname" ) );
	level.tempEntity = spawn( "script_model", (0,0,0) ); // entity used to link players
	
	game["timeLeft"] = 60 * level.dvar["timeLimit"];	
	game["round"] = 0;
	game["state"] = "readyup";

	level.spawns = [];
	level.spawns["axis"] = getEntArray( "mp_yolo_suicider", "classname" );
	level.spawns["allies"] = getEntArray( "mp_yolo_soldier", "classname" );
	level.spawns["spectator"] = getEntArray( "mp_global_intermission", "classname" );

	level.wins["axis"] = 0;
	level.wins["allies"] = 0;	

	setDvar( "jump_slowdownEnable", 1 );

	thread braxi\_menus::init();

	visionSetNaked( level.mapName, 0 );

	thread timeLimit();
	thread endRound( "allies", "..." );

	if( level.dvar["music"] )
		thread music();
}


music()
{
	i = 0;
	while(1)
	{
		sng = "slow_music_"+i;
		//iprintln( sng );
		ambientstop( 2 );
		ambientplay( "slow_music_"+i, 2 );
		i++;
		if( i > 7 )
			i = 0;
		wait 120 + randomInt(60);
	}
}

initScoreboard()
{
	precacheShader( "faction_128_sas" );
	precacheShader( "killiconsuicide" );

	setdvar("g_TeamName_Allies", "^2Humans");
	setdvar("g_TeamIcon_Allies", "faction_128_sas");
	setdvar("g_TeamColor_Allies", "0 0.8 0");
	setdvar("g_ScoresColor_Allies", "0.1 0.8 0.1");

	setdvar("g_TeamName_Axis", "^1Suiciders");
	setdvar("g_TeamIcon_Axis", "killiconsuicide");
	setdvar("g_TeamColor_Axis", "0.8 0 0");
	setdvar("g_ScoresColor_xis", "0.8 0.1 0.1");

	setdvar("g_ScoresColor_Spectator", ".25 .25 .25");
	setdvar("g_ScoresColor_Free", ".76 .78 .10");
	setdvar("g_teamColor_MyTeam", ".6 .8 .6" );
	setdvar("g_teamColor_EnemyTeam", "1 .45 .5" );	
}



precache()
{
	level.fx = [];
	precacheModel( "tag_origin" );
	precacheModel( "body_mp_usmc_cqb" );
	precacheModel( "fake" );
	precacheModel( level.suiciderModel );


	precacheModel( "com_flashlight_on" ); // used to play the flashlight view effect :>

	level.fx["embers"] = loadFx( "yolo/embers" );
	level.fx["explosion"] = loadFx( "yolo/explosion" );
	level.fx["flashlight_fake"] = loadFx( "yolo/flashlight" );
	level.fx["flashlight"] = loadFx( "yolo/flashlight2" );

	precacheItem( "brick_mp" );
	precacheItem( "colt45_mp" );
	//precacheItem( "flashlight_mp" );

	precacheStatusIcon( "hud_status_connecting" );
	precacheStatusIcon( "hud_status_dead" );

	precacheShader( "black" );
	precacheShader( "white" );
}


playerConnect() // Called when player is connecting to server
{
	level notify( "connected", self );
	self.statusicon = "hud_status_connecting";

	self.sessionstate = "spectator";
	self.team = "spectator";
	self.pers["team"] = "spectator";

	self.pers["score"] = 0;
	self.pers["kills"] = 0;
	self.pers["deaths"] = 0;
	self.pers["assists"] = 0;

	self spawnSpectator();
	//self.pers["team"] = "axis";
	//self spawnPlayer();

	logPrint( "J;" + self getGuid() + ";" + self getEntityNumber() + ";" + self.name + "\n" );
}


playerDisconnect() // Called when player disconnect from server
{
	level notify( "disconnected", self );
	self thread cleanUp();

	logPrint( "Q;" + self getGuid() + ";" + self getEntityNumber() + ";" + self.name + "\n" );
}


PlayerLastStand( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self suicide();
}

PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime )
{
	if( self.sessionteam == "spectator" || game["state"] == "endmap" )
		return;

	if( isPlayer( eAttacker ) && eAttacker.pers["team"] == self.pers["team"] && eAttacker != self )
		return;

	if( eAttacker.pers["team"] == "allies" && self.pers["team"] == "axis" && sMeansOfDeath != "MOD_UNKNOWN" )
		return;

	if( !isDefined(vDir) )
		iDFlags |= level.iDFLAGS_NO_KNOCKBACK;

	if( !(iDFlags & level.iDFLAGS_NO_PROTECTION) )
	{
		if(iDamage < 1)
			iDamage = 1;

		self finishPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime );
	}
}

PlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self endon( "spawned" );
	self notify( "killed_player" );
	self notify( "death" );

	if(self.sessionteam == "spectator" || game["state"] == "endmap" )
		return;

	if(sHitLoc == "head" && sMeansOfDeath != "MOD_MELEE")
	{
		sMeansOfDeath = "MOD_HEAD_SHOT";
	}

	self thread cleanUp();

	if( game["state"] == "playing" )
	{
		obituary( self, attacker, sWeapon, sMeansOfDeath );

		self.pers["deaths"] ++;
		self.deaths = self.pers["deaths"];

		if( self.pers["team"] == "allies"  )
		{
			body = self clonePlayer( deathAnimDuration );

			if( isDefined( body ) )
			{
				if ( self isOnLadder() || self isMantling() )
					body startRagDoll();
				thread delayStartRagdoll( body, sHitLoc, vDir, sWeapon, eInflictor, sMeansOfDeath );
			}
		}
		else
		{
			if( isPlayer( attacker ) && attacker != self )
			{
				attacker setWeaponAmmoClip( self getCurrentWeapon(), 15 );
				playFx( level.fx["embers"], self.origin );
			}
		}
	}

	if( isPlayer( attacker ) && attacker != self )
	{
		attacker.pers["score"] += 10;
		attacker.score = attacker.pers["score"];
		attacker.pers["kills"]++;
		attacker.kills = attacker.pers["kills"];
	}

	self.sessionstate = "dead";
	self.statusicon = "hud_status_dead";
	//self.sessionstate =  "spectator";

	self thread respawn();
}

respawn()
{
	self endon( "disconnect" );
	self endon( "joined_spectators" );
	//self endon( "spawned" );

	wait 0.05;
	if( self.pers["team"] == "allies" && game["state"] == "playing" )
		self braxi\_teams::setTeam( "axis" );

	wait level.dvar["respawnDelay"];

	if( self.sessionstate != "playing" )
		self spawnPlayer();
}


spawnPlayer( origin, angles )
{
	self endon( "disconnect" );

	if( game["state"] == "endmap" ) 
		return;
	//self notify( "spawn_player" );

	resettimeout();

	self.team = self.pers["team"];
	self.sessionteam = self.team;
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";

	self cleanUp();

	if( isDefined( origin ) && isDefined( angles ) )
		self spawn( origin,angles );
	else
	{
		spawnPoint = level.spawns[self.pers["team"]][randomInt(level.spawns[self.pers["team"]].size)];
		self spawn( spawnPoint.origin, spawnPoint.angles );
	}

	//self SetActionSlot( 1, "nightvision" );

	if( self.pers["team"] == "allies" )
	{
		self setModel( "body_mp_usmc_cqb" );
		self show();

		self.pers["weapon"] = "colt45_mp";
		self giveWeapon( self.pers["weapon"] );
		self setSpawnWeapon( self.pers["weapon"] );
		self giveMaxAmmo( self.pers["weapon"] );

		self setClientDvar( "cg_thirdperson", 0 );
			
		//self thread test();
		if( level.dvar["flashlight"] )
		{
			self iPrintlnBold( "flashlight still has a few bugs - it's alpha version, hmkay?" );
			self thread flashLight();
		}
	}
	else
	{
		self setModel( "fake" );
		self hide();
		self takeAllWeapons();
		self setClientDvar( "cg_thirdperson", 1 );
	}

	self.maxhealth = 100;
	self.health = self.maxhealth;



	self thread afterFrame();
}


flashLight()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "joined_spectators" );
	self endon( "disable flashlight" );

	if( isDefined( self.usingFlashLight ) )
	{
		self disableFlashLight();
		return;
	}
	self.usingFlashLight = true;


	tag = "tag_weapon_right";
	self.flashlightEnt = spawn( "script_model", (0,0,0 ) );
	self.flashlightEnt setModel( "tag_origin" );
	self.flashlightEnt hide();
	self.flashlightEnt showToPlayer( self );

	wait 0.1;
	self.fakeFlashLightFX = playFxOnTag( level.fx["flashlight_fake"], self, tag );
	playFxOnTag( level.fx["flashlight"], self.flashlightEnt, "tag_origin" );
	while( self.sessionstate == "playing" )
	{
		self.flashlightEnt.origin = self getTagOrigin( tag );
		self.flashlightEnt.angles = self getPlayerAngles();
		wait 0.05;

		if( self meleeButtonPressed() )
		{
			self disableFlashLight();
			break;
		}
	}

}

disableFlashLight()
{
/*	if ( !isDefined( self.usingFlashLight ) )
		return;

	self notify( "disable flashlight" );

	if( isDefined( self.fakeFlashLightFX ) )
		self.fakeFlashLightFX delete();
	if( isDefined( self.flashLightEnt ) )
	{
		self.flashLightEnt unlink();
		self.flashLightEnt hide();
		self.flashLightEnt delete();
	}

	self.fakeFlashLightFX = undefined;
	self.flashLightEnt = undefined;

	self.usingFlashLight = undefined;*/
}



afterFrame()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "joined_spectators" );

	wait 0.1;

	//self playLoopSound( "yolo" );

	self thread antiCamp();
	if( self.pers["team"] == "axis" )
	{
		self thread yolo();
		wait 0.1;

		while( self.sessionstate == "playing" )
		{
			while( !self attackButtonPressed() )
				wait 0.05;
			
			self playSound( "hind_helicopter_secondary_exp" );
			playFx( level.fx["explosion"], self.origin );
			radiusDamage( self.origin + (0,0,10), 192, 200, 70, self );
			self suicide();
		}
	}
}

yolo()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "joined_spectators" );

	self.modelEnt = spawn( "script_model", self.origin );
	self.modelEnt.angles = self.angles;
	self.modelEnt setModel( level.suiciderModel );
	self.modelEnt linkTo( self );
	self.modelEnt.yolo = false;
	self.modelEnt thread watchDamage( self );
	wait 0.05;

	oldPos = self.origin;

	while( isDefined( self.modelEnt ) && self.sessionstate == "playing" )
	{
		wait 0.2;
		
		dist = distance( oldPos, self.origin );
		if( dist >= 41 && !self.modelEnt.yolo && self getStance(1) == "stand" )
		{
			self.modelEnt playLoopSound( "yolo" );
			self.modelEnt.yolo = true;
		}
		else if( self.modelEnt.yolo && dist < 41 )
		{
			self.modelEnt stopLoopSound();
			self.modelEnt.yolo = false;
		}
		oldPos = self.origin;

	}
}

watchDamage( owner )
{
	owner endon( "disconnect" );
	owner endon( "death" );
	owner endon( "joined_spectators" );
	//self endon( "spawn_player" );

	wait 0.1;

	self setCanDamage( true );
	self.health = 1;

	while( isDefined( self ) && isDefined( owner ) && self.health > 0 )
	{
		self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, dflags );
			
		//iprintln( "damage: " + damage );
		if ( !isPlayer( attacker ) || isPlayer( attacker ) && attacker.pers["team"] == owner.pers["team"] || !damage )
			continue;

		self.health -= damage;
		owner PlayerDamage( attacker, attacker, owner.health+1, 0, "MOD_UNKNOWN", "none", point, direction_vec, "none", 0 );
	}
}

spawnSpectator( origin, angles )
{
	if( !isDefined( origin ) )
		origin = level.spawns["spectator"][0].origin;
	if( !isDefined( angles ) )
		angles = level.spawns["spectator"][0].angles;

	//origin = (0,0,0);
	//angles = origin;

	self notify( "joined_spectators" );

	self braxi\_teams::setTeam( "spectator" );

	self thread cleanUp();
	resettimeout();
	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	self.statusicon = "";
	self spawn( origin, angles );
	self braxi\_teams::setSpectatePermissions();

	level notify( "player_spectator", self );
}

cleanUp()
{

	self disableFlashLight();
	self setClientDvars( "cg_thirdperson", 0 );

	if( isDefined( self.modelEnt ) )
	{
		self.modelEnt unLink();
		if( self.modelEnt.yolo )
			self.modelEnt stopLoopSound();
		self.modelEnt delete();
		self.modelEnt = undefined;
	}
}


pickRandomSuicider()
{
	level notify( "picking suicider" );
	level endon( "picking suicider" );

	if( game["state"] != "playing" || level.numSuiciders )
		return;

	players = getAllPlayers();
	if( !isDefined( players ) || isDefined( players ) && !players.size )
		return;

	num = randomInt( players.size );
	guy = players[num];

	if( guy getEntityNumber() == getDvarInt( "last_picked_player" ) )
	{	
		if( isDefined( players[num-1] ) && isPlayer( players[num-1] ) )
			guy = players[num-1];
		else if( isDefined( players[num+1] ) && isPlayer( players[num+1] ) )
			guy = players[num+1];
	}
	
	if( !isDefined( guy ) && !isPlayer( guy ) || guy.sessionstate == "spectator" )
	{
		level thread pickRandomSuicider();
		return;
	}

	logPrint( ("FS:" + guy.name + ";" + guy getGuid() ) );
	//iPrintlnBold( guy.name + " is the first ^1Suicider." );

	braxi\_hudutils::annoucement( 1.8, (guy.name + "^7 is the first Suicider.") );
	thread braxi\_common::playSoundOnAllPlayers( "first_suicider" );


	guy thread braxi\_teams::setTeam( "axis" );
	guy spawnPlayer();
		
	setDvar( "last_picked_player", guy getEntityNumber() );
	level notify( "firstsuicider", guy );
	level.activ = guy;
	wait 0.1;
}


roundLogic()
{
	level endon( "end round" );
	level endon( "game over" );

	if( game["state"] == "endmap" )
		return;

	//waitForPlayers( 2 );

	level notify( "round_started", game["roundsplayed"] );
	game["state"] = "playing";

	while( game["state"] == "playing" )
	{
		wait 0.1;

		level.soldiers = [];
		level.suiciders = [];

		level.numSoldiers = 0;
		level.numSuiciders = 0;

		level.totalPlayers = 0;
		level.totalPlayingPlayers = 0;

		players = getAllPlayers();

		if( players.size > 0 )
		{
			for( i = 0; i < players.size; i++ )
			{
				level.totalPlayers++;

				if( isDefined( players[i].pers["team"] ) )
				{
					level.totalPlayingPlayers ++;

					if( players[i].pers["team"] == "allies" )
					{
						level.soldiers[level.soldiers.size] = players[i];
						level.numSoldiers ++;
					}
					else if( players[i].pers["team"] == "axis" )
					{
						level.suiciders[level.suiciders.size] = players[i];
						level.numSuiciders ++;
					}
				}
			}		
		}	
			
		if( game["state"] != "playing" )
			continue;

		if( level.numSoldiers > 1 && !level.numSuiciders  )
		{
			pickRandomSuicider();
			wait 0.1;
			continue;
		}

		if( !level.numSoldiers )
		{
			thread endRound( "axis", "   " );
			break;
		}
	}
}


timeLimit()
{
	level endon( "game over" );

	level.hud_time = newHudElem();
    level.hud_time.foreground = true;
	level.hud_time.alignX = "right";
	level.hud_time.alignY = "top";
	level.hud_time.horzAlign = "right";
    level.hud_time.vertAlign = "top";
    level.hud_time.x = 0;
    level.hud_time.y = 70;
    level.hud_time.sort = 0;
  	level.hud_time.fontScale = 3;
	level.hud_time.color = (0.8, 1.0, 0.8);
	level.hud_time.font = "objective";
	level.hud_time.glowColor = (0.3, 0.6, 0.3);
	level.hud_time.glowAlpha = 1;
 	level.hud_time.hidewheninmenu = false;

	level.hud_time setTimer( game["timeLeft"] );
	level.hud_time.alpha = 0;

	while( game["timeLeft"] >= 0 )
	{
		wait 1;
		if( game["state"] == "playing" )
		{
			game["timeLeft"] --;
		}
	}

	thread endMap();
}

endRound( team, notifyText )
{
	level endon( "game over" );
	
	level notify( "end round" );

	game["state"] = "readup";

	level.hud_time.alpha = 0;
	if( game["round"] != 0 ) // to avoid respawning players in 1st round
	{
		level.wins[team] ++;

		iPrintlnBold( notifyText );
		if( team == "axis" )	playSoundOnAllPlayers( "mp_victory_soviet" );
		else					playSoundOnAllPlayers( "mp_victory_sas" );

		wait 0.1;

		players = getAllPlayers();
		for( i = 0; i < players.size; i++ )
		{
			players[i] suicide();
			players[i] braxi\_teams::setTeam( "allies" );
			players[i] spawnPlayer();
		}
	}

	waitForPlayers( 2 );
	game["round"] ++;
	braxi\_hudutils::annoucement( 9, "Round " + game["round"] + " begins in 10 seconds..." );
	//iPrintlnBold( "Round " + game["round"] + " begins in 10 seconds..." );
	
	wait 10;

	game["state"] = "playing";
	thread roundLogic();
	level.hud_time setTimer( game["timeLeft"] );
	level.hud_time.alpha = 1;
}


endMap()
{
	game["state"] = "endmap";
	level notify( "intermission" );
	level notify( "game over" );

	setDvar( "g_deadChat", 1 );

	ambientstop( 0 );
	playSoundOnAllPlayers( "endmusic" );

	players = getAllPlayers();
	for( i = 0; i < players.size; i++ )
	{
		oldteam = players[i].pers["team"];
		players[i] spawnSpectator( level.spawns["spectator"][0].origin, level.spawns["spectator"][0].angles );
		players[i] braxi\_teams::setTeam( oldteam );
		players[i].sessionstate = "intermission";
	}
	wait 20;
	
	exitLevel( false );
}


antiCamp()
{
	self endon( "disconnect" );
	self endon( "spawned_player" );
	self endon( "joined_spectators" );
	self endon( "death" );
	self endon( "anticamp monitor" );

	if( !level.dvar["anticamp"] || self.pers["team"] == "axis" )
		return;

	time = 0;
	oldOrigin = self.origin - (0,0,70);
	while( isAlive( self ) )
	{
		if( game["state"] != "playing" )
		{
			wait 1;
			continue;
		}


		wait 0.2;
		if( distance(oldOrigin, self.origin) <= level.dvar["ac_dist"] )
			time++;
		else
			time = 0;

		if( time == (level.dvar["ac_warn"]*5) )
		{
			self playLocalSound( "camper" );
			self iPrintlnBold( "^1Move you camper!" );
		}

		if( time == (level.dvar["ac_time"]*5) )
		{
			iPrintln( self.name + " was killed due to camping." );
			self suicide();
			break;
		}
		oldOrigin = self.origin;
	}
}
//voiceovers/US/mp/US_1mc_new_position_01_R.wav