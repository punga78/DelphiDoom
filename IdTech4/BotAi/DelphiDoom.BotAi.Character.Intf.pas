{******************************************************************************}
{                                                                              }
{  DelphiDoom: bot AI - IBotCharacterSystem, the characters of the bots        }
{                                                                              }
{  Port of Quake III Arena (id Software, GPL v2 or later): the interface of    }
{  code\game\be_ai_char.h. Based on the Quake III Arena GPL Source Code        }
{  (id Software). Copyright (C) 1999-2005 Id Software, Inc.                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.BotAi.Character.Intf;

interface

uses
  DelphiDoom.BotAi.Character.Data;

type
  /// <summary>
  ///   be_ai_char.h with the handles of the original (1..64, 0 is "no character"): load a character
  ///   for a skill level between 1 and 5 and read its characteristics.
  /// </summary>
  IBotCharacterSystem = interface
    ['{4F0C1A52-7B63-4C57-9E2D-3A6B8D1E0F77}']
    /// <summary>BotLoadCharacter: skill is limited to [1, 5]; 0 if no character could be made</summary>
    function LoadCharacter(const AFileName: AnsiString; const ASkill: Single): Integer;
    /// <summary>BotFreeCharacter: does nothing unless <c>bot_reloadcharacters</c> is set</summary>
    procedure FreeCharacter(const AHandle: Integer);
    /// <summary>Characteristic_Float: 0 (and an error printed) if the characteristic is not a number</summary>
    function CharacteristicFloat(const AHandle, AIndex: Integer): Single;
    /// <summary>Characteristic_BFloat</summary>
    function CharacteristicBoundedFloat(const AHandle, AIndex: Integer; const AMin, AMax: Single): Single;
    /// <summary>Characteristic_Integer: a float is truncated</summary>
    function CharacteristicInteger(const AHandle, AIndex: Integer): Integer;
    /// <summary>Characteristic_BInteger</summary>
    function CharacteristicBoundedInteger(const AHandle, AIndex, AMin, AMax: Integer): Integer;
    /// <summary>Characteristic_String: the text cut to ASize - 1 characters (the C buffer size minus the zero)</summary>
    function CharacteristicString(const AHandle, AIndex, ASize: Integer): AnsiString;
    /// <summary>BotShutdownCharacters</summary>
    procedure Shutdown;
    /// <summary>The character of a handle (nil, nothing printed, if there is none); for tests and tools</summary>
    function FindCharacter(const AHandle: Integer): TBotCharacter;
  end;

implementation

end.
