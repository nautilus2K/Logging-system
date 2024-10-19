//-----------------------------------------------------------------------------------------------
//
// Language:	Squirrel
//
// Description:	Source Engine™ functions for logs implementations
//				The logging system is a channel-based output mechanism which allows
//				subsystems to route their text/diagnostic output to various listeners
//
// Github:		https://github.com/nautilus2K/Logging-system
//
// Version:		1.0.3
//
// Changelog:	03/16/2024 v1.0.0 - Released.
//				07/11/2024 v1.0.1 - Added addinitional to logging into file.
//				07/23/2024 v1.0.2 - Changed string format in function __CurrentTimeFmt,
//									added timestamp in function UTIL_LogPrintf.
//				10/19/2024 v1.0.3 - Added file rotate.
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
pRoot.bAddTimestamp			<- true;						// Add timestamp in start of log message
pRoot.bEnableFileRotate		<- true;						// Enable file rotate, make copy with old date

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
		local argslist = [ this, ( __CurrentTimeFmt() + ": " + MessageFmt ) ];
		argslist.extend( vargv );
		LogMsg( format.acall( argslist ) );
	}
}

//------------------------------------------------------------------------------------------
// Functions to logging into file
//------------------------------------------------------------------------------------------

if ( !( "GetDateFromConsole" in pRoot ) )
{
	// Taken from Speedrunner Tools by Shad0w
	function pRoot::GetDateFromConsole( table )
	{
		/*
			Since in the VScript base there weren't defined any Squirrel's original date() or time(), thus get unix from the local time.
			Unfortunately, we cannot properly get local time until TLS update, only with certain difficulties. Also, legacy method
			won't work after 2.1.5.5 for some reason (because 'con_logfile' no longer functional?).
		*/
		if ("LocalTime" in getroottable())	//TLS clue
		{
			//wrapper to needed format
			LocalTime(table);
			table.min <- minute;
			table.sec <- second;
		}
		else
		{
			local sFileData = FileToString("st_config/dump/logs_total.txt");
			if (sFileData == null)
			{
				StringToFile("st_config/dump/logs_total.txt", "1");
				sFileData = "1";
			}
			local logs_total = sFileData;
			Convars.SetValue("con_timestamp", 1);
			Convars.SetValue("con_logfile", "ems/st_config/dump/timestamp_" + sFileData + ".txt"); printl("");
			Convars.SetValue("con_logfile", "");
			Convars.SetValue("con_timestamp", 0);
			sFileData = FileToString("st_config/dump/timestamp_" + sFileData + ".txt");
			local length = sFileData.len();
			if (length >= 15720) StringToFile("st_config/dump/logs_total.txt", "" + (logs_total.tointeger() + 1)); //655 total entries until error
			sFileData = split(sFileData.slice(length - 24, length - 3), " - ");
			local date = split(sFileData[0], "/"); local clock = split(sFileData[1], ":");
			table.day <- date[1].tointeger(); table.month <- date[0].tointeger(); table.year <- date[2].tointeger();
			table.hour <- clock[0].tointeger(); table.min <- clock[1].tointeger(); table.sec <- clock[2].tointeger();
		}
	}
}

function pRoot::__CurrentTimeFmt()
{
	if ( !( "__curtimefmt_calltime" in pRoot ) )
	{
		::__curtimefmt_calltime <- 0.0;
		::__curtimefmt_lastres <- "";
	}
	
	// Prevent this function from being called every frame.
	// In the pre-TLS version, we cannot find out the time using the Source engine utilities, 
	// so we find out this through the console command.
	// Due to operations on strings every frame, spikes will occur periodically!
	if ( 1.0 <= ( Time() - __curtimefmt_calltime ) )
	{
		__curtimefmt_calltime = Time();
		local tm = {};
		GetDateFromConsole( tm );
		__curtimefmt_lastres = format( "L %.02d/%.02d/%d - %.02d:%.02d:%.02d", tm.month, tm.day, tm.year, tm.hour, tm.min, tm.sec );
		return __curtimefmt_lastres;
	}
	return __curtimefmt_lastres; // Last call time less than 1.0
}

local __common_LogFile = function( sPath, AddTimestamp, MessageFmt, args )
{
	
	local str_stream = "";
	if ( AddTimestamp )
		str_stream += __CurrentTimeFmt() + ": ";
	str_stream += MessageFmt;
	
	local fmtargs = [ this, str_stream ];
	fmtargs.extend( args );
	str_stream = format.acall( fmtargs );
	if ( str_stream )
	{
		local str_file = FileToString( sPath );
		if ( str_file != null )
		{
			local file_len = str_file.len();
			// print( format( "__common_LogFile: Debug: File length %u\n", file_len ) );
			if ( file_len + str_stream.len() >= ( 16384 - 255 ) )
			{
				if ( !pRoot.bEnableFileRotate )
				{
					print( "__common_LogFile: File data cannot be more than 16384 bytes, writing a file from scratch.\n" );
					StringToFile( sPath, "" );
				}
				else 
				{
					local fname = sPath;
					local fnameold = null;
					if ( 0 )
					{
						local i = sPath.len() - 1;
						while ( sPath[i] != '/' || sPath[i] != '\\' ) { i--; }
						fname = sPath.slice( i + 1, sPath.len() );
					}
					fnameold = sPath + format( ".%f", RandomFloat( 0.0000000, 1024.0000000 ) ); // You have another idea?
					print( format( "__common_LogFile: Rotating file '%s' to '%s'.\n", fname, fnameold ) );
					StringToFile( fnameold, str_file );
				}
				str_file = "";
			}
			str_file += str_stream;
		}
		else str_file = str_stream;
		StringToFile( sPath, str_file + "\n" );
	}
}

function pRoot::LogFile( sPath, MessageFmt, ... )
{
	if ( sPath != null && MessageFmt != null || Log_CustomSituationAllows() )
		__common_LogFile( sPath, pRoot.bAddTimestamp, MessageFmt, vargv );
}

function pRoot::DevLogFile( sPath, MessageFmt, ... )
{
	if ( sPath != null && MessageFmt != null && LogDev() != 0 || Log_CustomSituationAllows() )
		__common_LogFile( sPath, pRoot.bAddTimestamp, MessageFmt, vargv );
}

function pRoot::UTIL_LogFilef( sPath, MessageFmt, ... )
{
	if ( sPath != null && MessageFmt != null && LogDev() >= LOG_DEVELOPER_VERBOSE && gl_UtilLogEnabled || Log_CustomSituationAllows() )
		__common_LogFile( sPath, pRoot.bAddTimestamp, MessageFmt, vargv );
}