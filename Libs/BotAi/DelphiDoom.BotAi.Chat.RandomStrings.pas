{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotRandomStrings, RandomString                        }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): RandomString of     }
{  code\botlib\be_ai_chat.c. Based on the Quake III Arena GPL Source Code      }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Chat.RandomStrings;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Chat.Tables;

type
  /// <summary>Chooses a string of a named list of random strings</summary>
  TBotRandomStrings = class
  strict private
    FTables: TBotChatTables;
    FRandom: IBotRandom;
  public
    constructor Create(const ATables: TBotChatTables; const ARandom: IBotRandom);
    /// <summary>
    ///   RandomString: false if no list has the name (compared with case). The generator is called once
    ///   for every list with the name, even a failed lookup for an empty list uses it.
    /// </summary>
    function TryChoose(const AName: AnsiString; out AText: AnsiString): Boolean;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Chat.RandomList;

{ TBotRandomStrings }

constructor TBotRandomStrings.Create(const ATables: TBotChatTables; const ARandom: IBotRandom);
begin
  inherited Create;
  FTables := ATables;
  FRandom := ARandom;
end;

function TBotRandomStrings.TryChoose(const AName: AnsiString; out AText: AnsiString): Boolean;
var
  LList: TBotRandomList;
  LValue: Single;
  LIndex: Integer;
begin
  AText := '';
  for LList in FTables.RandomLists do
  begin
    if LList.Name = AName then
    begin
      // i = random() * numstrings, a float truncated
      LValue := FRandom.NextFloat * LList.Strings.Count;
      LIndex := Trunc(LValue);
      if (LIndex >= 0) and (LIndex < LList.Strings.Count) then
      begin
        AText := LList.Strings[LIndex];
        Exit(True);
      end;
    end;
  end;
  Result := False;
end;

end.
