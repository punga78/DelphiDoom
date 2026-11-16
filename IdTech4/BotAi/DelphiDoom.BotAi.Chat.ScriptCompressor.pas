{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotScriptCompressor, COM_Compress                     }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): COM_Compress of     }
{  code\game\q_shared.c, which LoadScriptFile of l_script.c applies to every   }
{  file. Based on the Quake III Arena GPL Source Code (id Software).           }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.ScriptCompressor;

interface

type
  /// <summary>
  ///   Takes out the comments and the extra white space of a script: line and block comments go, every
  ///   run of spaces and tabs is one space, every run of line ends is one line feed (so the line
  ///   numbers of the messages are those of the compressed text), quoted strings are copied as they are.
  ///   The code is TQ3ScriptCompressor of Framework\Scanner (issue #236: one copy for the whole library)
  /// </summary>
  TBotScriptCompressor = class
  public
    /// <summary>COM_Compress; the text stops at the first zero byte as the C string does</summary>
    class function Compress(const AText: AnsiString): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.Scanner.Q3.Compressor;

{ TBotScriptCompressor }

class function TBotScriptCompressor.Compress(const AText: AnsiString): AnsiString;
begin
  Result := TQ3ScriptCompressor.Compress(AText);
end;

end.
