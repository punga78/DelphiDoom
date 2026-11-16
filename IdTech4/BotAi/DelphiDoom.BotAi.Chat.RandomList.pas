{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotRandomList, a named list of random strings         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_randomlist_t,   }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.RandomList;

interface

uses
  System.Generics.Collections;

type
  /// <summary>A random string name ("greeting") with the compiled strings it can be expanded to</summary>
  TBotRandomList = class
  strict private
    FName: AnsiString;
    FStrings: TList<AnsiString>;
  public
    constructor Create(const AName: AnsiString);
    destructor Destroy; override;
    property Name: AnsiString read FName;
    /// <summary>The strings in list order: the last one read from the file is the first (the original prepends)</summary>
    property Strings: TList<AnsiString> read FStrings;
  end;

implementation

{ TBotRandomList }

constructor TBotRandomList.Create(const AName: AnsiString);
begin
  inherited Create;
  FName := AName;
  FStrings := TList<AnsiString>.Create;
end;

destructor TBotRandomList.Destroy;
begin
  FStrings.Free;
  inherited Destroy;
end;

end.
