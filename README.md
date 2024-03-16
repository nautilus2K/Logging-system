# Logging system

**The logging system is a channel-based output mechanism which allows**
**subsystems to route their text/diagnostic output to various listeners.**
**This system is designed for Valve games with Squirrel (VScript) language**

## Functions

```C++
// Standart output functions
void roottable::Msg(const char *MsgFormat, ...)
void roottable::Warning(const char *MsgFormat, ...)
void roottable::Error(const char *MsgFormat, ...)

// A couple of super-common dynamic spew messages, here for convenience 
// These looked at the "developer" group, print if it's level 1 or higher 
void roottable::DevMsg(int level, const char *MsgFormat, ...)
void roottable::DevWarning(int level, const char *MsgFormat, ...)
void roottable::ConMsg(int level, const char *MsgFormat, ...)
void roottable::ConDMsg(const char *MsgFormat, ...)

// Implementing function from util.h, "developer verbose (level 2 or higher)" and "gl_UtilLogEnabled" requied
void getroottable::UTIL_LogPrintf(const char *MessageFmt, ...)

// The function resolves the log if your situation is correct
bool roottable::Log_CustomSituationAllows()
{
  return ( Convars.GetFloat( "z_debug" ).tointeger() );
}
```

## Usage

To use, place `logsys.nut` in the `.../scripts/vscripts/logsys.nut` folder

**Include:**
```C
IncludeScript("logsys.nut");
```
