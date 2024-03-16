//-----------------------------------------------------------------------------------------------
//
// Language:	Squirrel
//
// Description:	Source Engine™ functions for logs implementations
//				The logging system is a channel-based output mechanism which allows
//				subsystems to route their text/diagnostic output to various listeners
//
//-----------------------------------------------------------------------------------------------

//-----------------------------------------------------------------------------------------------
// Local definitions for correct calling of log functions
// gl_StreamEnabled is a local global variable that is responsible for enabling the log stream
//-----------------------------------------------------------------------------------------------

local LOG_GENERAL			= -2;	// Default logging channel, with a level < 1
local LOG_CONSOLE			= 0;	// Default logging channel, with a level < 1
local LOG_DEVELOPER_CONSOLE	= -1;	// Developer only channle, with a level < 0
local LOG_DEVELOPER			= 1;	// Developer only channle, with a level >= 1
local LOG_DEVELOPER_VERBOSE	= 2;	// Developer only channle, with a level >= 2

local LS_MESSAGE			= 0;	// An informative logging message
local LS_WARNING			= 1;	// A warning, typically non-fatal
local LS_ERROR				= 3;	// An error, typically fatal/unrecoverable

local gl_StreamEnabled		= true;
local gl_UtilLogEnabled		= false;						// UTIL_LogPrintf will be work
pRoot						<- getroottable().weakref();	// Just weak reference to sq root table

//-----------------------------------------
// Initial local functions for logs
//-----------------------------------------

local LogDev = function()
{
	return ( Convars.GetFloat( "developer" ) ).tointeger();
}

local LogMsg = function( fmt )
{ 
	if ( gl_StreamEnabled )
		print( fmt + "\n" );					// Blue color
}

local LogWarn = function( fmt )
{
	if ( gl_StreamEnabled )
		error( fmt + "\n" );					// Red color. @TODO: How i can do orange color for warning message?
}

local LogCon = function( fmt )
{
	if ( gl_StreamEnabled )
		SendToServerConsole( "echo " + fmt );	// White color
}

local DoLog = function( ExistChannel, ExistSeverity, ExistMessage )
{
	//
	// LOG_GENERAL, LOG_CONSOLE, LOG_DEVELOPER_CONSOLE, LOG_DEVELOPER, LOG_DEVELOPER_VERBOSE
	// LS_MESSAGE, LS_WARNING, LS_ERROR
	//
	
	switch ( ExistChannel )
	{
		case LOG_GENERAL:
		{
			switch ( ExistSeverity )
			{
				case LS_MESSAGE:
					LogMsg( ExistMessage );
					break;
				
				case LS_WARNING:
				case LS_ERROR:
					LogWarn( ExistMessage );
					break;
			}
		}
		break;
		
		case LOG_CONSOLE:
		{
			switch ( ExistSeverity )
			{
				case LS_MESSAGE:
				case LS_WARNING:
				case LS_ERROR:
					LogCon( ExistMessage );
					break;
			}
		}
		break;
		
		case LOG_DEVELOPER_CONSOLE:
		{
			if ( LogDev() <= LOG_DEVELOPER_CONSOLE || Log_CustomSituationAllows() )
			{
				switch ( ExistSeverity )
				{
					case LS_MESSAGE:
					case LS_WARNING:
					case LS_ERROR:
						LogCon( ExistMessage );
						break;
				}
			}
		}
		break;
		
		case LOG_DEVELOPER:
		{
			if ( LogDev() >= LOG_DEVELOPER || Log_CustomSituationAllows() )
			{
				switch ( ExistSeverity )
				{
					case LS_MESSAGE:
						LogMsg( ExistMessage );
						break;
					
					case LS_WARNING:
					case LS_ERROR:
						LogWarn( ExistMessage );
						break;
				}
			}
		}
		break;
		
		case LOG_DEVELOPER_VERBOSE:
		{
			if ( LogDev() >= LOG_DEVELOPER_VERBOSE || Log_CustomSituationAllows() )
			{
				local fTime = format( "%3.2f: ", Time() );
				switch ( ExistSeverity )
				{
					case LS_MESSAGE:
						LogMsg( fTime + ExistMessage );
						break;
					
					case LS_WARNING:
					case LS_ERROR:
						LogWarn( fTime + ExistMessage );
						break;
				}
			}
		}
		break;
		
		default:
		{
			LogCon( "NO CHANNEL MESSAGE: " + ExistMessage );
		}
	}
}

local Log_LegacyHelper = function( Channel, Severity, MessageFmt, args )
{
	if ( gl_StreamEnabled )
	{
		if ( ( Channel >= -2 && Channel <= 2 ) && ( Severity >= 0 && Severity <= 3 ) && MessageFmt != null )
		{
			local argslist = [ this, MessageFmt ];
			argslist.extend( args );
			DoLog( Channel, Severity, format.acall( argslist ) );
		}
	}
}

//------------------------------------------------------------------------------------------
// The function resolves the log if your situation is correct
//------------------------------------------------------------------------------------------

function pRoot::Log_CustomSituationAllows()
{
	return ( false );
}

//------------------------------------------------------------------------------------------
// Functions with ready-made parameters for logs that can call initial local functions
//------------------------------------------------------------------------------------------

function pRoot::Msg( MsgFormat, ... )
{
	Log_LegacyHelper( LOG_GENERAL, LS_MESSAGE, MsgFormat, vargv );
}

function pRoot::Warning( MsgFormat, ... )
{
	Log_LegacyHelper( LOG_GENERAL, LS_WARNING, MsgFormat, vargv );
}

function pRoot::Error( MsgFormat, ... )
{
	Log_LegacyHelper( LOG_GENERAL, LS_ERROR, MsgFormat, vargv );
}

//-----------------------------------------------------------------------------
// A couple of super-common dynamic spew messages, here for convenience 
// These looked at the "developer" group, print if it's level 1 or higher 
//-----------------------------------------------------------------------------

function pRoot::DevMsg( level, MsgFormat, ... )
{
	local channel = 0;
	if ( level < 0 )
		channel = LOG_DEVELOPER_CONSOLE;
	else 
		channel = level >= 2 ? LOG_DEVELOPER_VERBOSE : LOG_DEVELOPER;
	Log_LegacyHelper( channel, LS_MESSAGE, MsgFormat, vargv );
}

function pRoot::DevWarning( level, MsgFormat, ... )
{
	local channel = 0;
	if ( level < 0 )
		channel = LOG_DEVELOPER_CONSOLE;
	else 
		channel = level >= 2 ? LOG_DEVELOPER_VERBOSE : LOG_DEVELOPER;
	Log_LegacyHelper( channel, LS_WARNING, MsgFormat, vargv );
}

function pRoot::ConMsg( MsgFormat, ... )
{
	Log_LegacyHelper( LOG_CONSOLE, LS_MESSAGE, MsgFormat, vargv );
}

function pRoot::ConDMsg( MsgFormat, ... )
{
	Log_LegacyHelper( LOG_DEVELOPER_CONSOLE, LS_MESSAGE, MsgFormat, vargv );
}

//------------------------------------------------
// Implementing function from util.h
//------------------------------------------------

function pRoot::UTIL_LogPrintf( MessageFmt, ... )
{
	if ( ( LogDev() >= LOG_DEVELOPER_VERBOSE && gl_UtilLogEnabled ) || Log_CustomSituationAllows() )
	{
		local argslist = [ this, MessageFmt ];
		argslist.extend( vargv );
		LogMsg( format.acall( argslist ) );
	}
}

