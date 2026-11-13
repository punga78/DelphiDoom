{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - constants shared by the bot library                    }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): code\game\botlib.h  }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Types;

interface

const
  /// <summary>PRT_MESSAGE: the print levels of botimport.Print</summary>
  PRT_MESSAGE = 1;
  PRT_WARNING = 2;
  PRT_ERROR = 3;
  PRT_FATAL = 4;
  PRT_EXIT = 5;

  /// <summary>BLERR_NOERROR and the error codes of the library the chat returns</summary>
  BLERR_NOERROR = 0;
  BLERR_CANNOTLOADICHAT = 20;

  /// <summary>MAX_CLIENTS: the number of chat states and of cached chats</summary>
  BOT_MAX_CLIENTS = 64;

  /// <summary>BOTFILESBASEFOLDER: the folder the files of the bots are read from</summary>
  BOT_FILES_BASE_FOLDER = 'botfiles';

implementation

end.
