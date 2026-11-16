{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - TBotCharacter, a bot character                         }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): bot_character_t,    }
{  BotDumpCharacter and BotDefaultCharacteristics of code\botlib\be_ai_char.c. }
{  Based on the Quake III Arena GPL Source Code (id Software).                 }
{  Copyright (C) 1999-2005 Id Software, Inc.                                   }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.Data;

interface

uses
  DelphiDoom.BotAi.Import.Intf, DelphiDoom.BotAi.Character.Types;

type
  /// <summary>
  ///   bot_character_t: the file it comes from, the skill level and the characteristics. The original
  ///   allocates room for 81 characteristics and accepts the index 80 in a file (the check is
  ///   <c>index > MAX_CHARACTERISTICS</c>) although nothing reads it: the array has 81 elements too.
  /// </summary>
  TBotCharacter = class
  public
    FileName: AnsiString;
    Skill: Single;
    Characteristics: array[0..MAX_CHARACTERISTICS] of TBotCharacteristic;
    /// <summary>
    ///   BotDumpCharacter: the characteristics set, to the log of the library. The original writes
    ///   the skill with %d but passes a float (undefined): here it is the whole number.
    /// </summary>
    procedure Dump(const AImport: IBotImport);
    /// <summary>BotDefaultCharacteristics: copies what this character does not have from the default</summary>
    procedure ApplyDefaults(const ADefault: TBotCharacter);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Text.CFormat;

{ TBotCharacter }

procedure TBotCharacter.Dump(const AImport: IBotImport);
var
  LIndex: Integer;
begin
  AImport.LogWrite(FileName);
  AImport.LogWrite('skill ' + TBotCFormat.Int(Trunc(Skill)) + #10);
  AImport.LogWrite('{'#10);
  for LIndex := 0 to MAX_CHARACTERISTICS - 1 do
  begin
    case Characteristics[LIndex].CharType of
      CT_INTEGER:
        AImport.LogWrite(AnsiString(Format(' %4d %d', [LIndex, Characteristics[LIndex].IntegerValue])) + #10);
      CT_FLOAT:
        AImport.LogWrite(AnsiString(Format(' %4d ', [LIndex])) +
          TBotCFormat.Fixed6(Characteristics[LIndex].FloatValue) + #10);
      CT_STRING:
        AImport.LogWrite(AnsiString(Format(' %4d ', [LIndex])) + Characteristics[LIndex].StringValue + #10);
    end;
  end;
  AImport.LogWrite('}'#10);
end;

procedure TBotCharacter.ApplyDefaults(const ADefault: TBotCharacter);
var
  LIndex: Integer;
begin
  for LIndex := 0 to MAX_CHARACTERISTICS - 1 do
  begin
    if Characteristics[LIndex].CharType <> 0 then
      Continue;
    if ADefault.Characteristics[LIndex].CharType = CT_FLOAT then
    begin
      Characteristics[LIndex].CharType := CT_FLOAT;
      Characteristics[LIndex].FloatValue := ADefault.Characteristics[LIndex].FloatValue;
    end
    else if ADefault.Characteristics[LIndex].CharType = CT_INTEGER then
    begin
      Characteristics[LIndex].CharType := CT_INTEGER;
      Characteristics[LIndex].IntegerValue := ADefault.Characteristics[LIndex].IntegerValue;
    end
    else if ADefault.Characteristics[LIndex].CharType = CT_STRING then
    begin
      Characteristics[LIndex].CharType := CT_STRING;
      Characteristics[LIndex].StringValue := ADefault.Characteristics[LIndex].StringValue;
    end;
  end;
end;

end.
