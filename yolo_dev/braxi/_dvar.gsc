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

setupDvars()
{
	level.dvar = [];

	RegisterDvar( "timeLimit", "bx_timeLimit", 15, 0, 60, "int" );
	RegisterDvar( "respawnDelay", "bx_respawnDelay", 4, 0, 60, "int" );

	RegisterDvar( "flashlight", "bx_flashlight", 0, 0, 1, "int" );

	RegisterDvar( "music", "bx_music", 1, 0, 1, "int" );

	RegisterDvar( "anticamp", "bx_anticamp", 1, 0, 1, "int" );
	RegisterDvar( "ac_dist", "bx_anticamp_dist", 20, 5, 256, "float" );
	RegisterDvar( "ac_warn", "bx_anticamp_warn", 10, 5, 60, "int" );
	RegisterDvar( "ac_time", "bx_anticamp_kill", 15, level.dvar["ac_warn"], 90, "int" );

	RegisterDvar( "bots", "bx_numBots", 3, 0, 63, "int" );

	if( getDvar( "last_picked_player" ) == "" )
		setDvar( "last_picked_player", ("bxownu" + randomInt(100)) );
}


// Originally from Bell's AWE mod for CoD 1
RegisterDvar( scriptName, varname, vardefault, min, max, type )
{
	if(type == "int")
	{
		if(getdvar(varname) == "")
			definition = vardefault;
		else
			definition = getdvarint(varname);
	}
	else if(type == "float")
	{
		if(getdvar(varname) == "")
			definition = vardefault;
		else
			definition = getdvarfloat(varname);
	}
	else
	{
		if(getdvar(varname) == "")
			definition = vardefault;
		else
			definition = getdvar(varname);
	}

	if((type == "int" || type == "float") && min != 0 && definition < min)
		definition = min;

	if((type == "int" || type == "float") && max != 0 && definition > max)
		definition = max;

	if(getdvar( varname ) == "")
		setdvar( varname, definition );

	level.dvar[scriptName] = definition;
//	return definition;
}
