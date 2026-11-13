{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvars, shared types                  }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.h                }
{  (cvarFlags_t and the declaration of an idCVar).                             }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.Types;

interface

uses
  DelphiDoom.Console.CmdSystem.Types;

const
  /// <summary>CVAR_ALL: all flags</summary>
  CVAR_ALL = -1;
  /// <summary>variable is a boolean</summary>
  CVAR_BOOL = 1 shl 0;
  /// <summary>variable is an integer</summary>
  CVAR_INTEGER = 1 shl 1;
  /// <summary>variable is a float</summary>
  CVAR_FLOAT = 1 shl 2;
  /// <summary>system variable</summary>
  CVAR_SYSTEM = 1 shl 3;
  /// <summary>renderer variable</summary>
  CVAR_RENDERER = 1 shl 4;
  /// <summary>sound variable</summary>
  CVAR_SOUND = 1 shl 5;
  /// <summary>gui variable</summary>
  CVAR_GUI = 1 shl 6;
  /// <summary>game variable</summary>
  CVAR_GAME = 1 shl 7;
  /// <summary>tool variable</summary>
  CVAR_TOOL = 1 shl 8;
  /// <summary>sent to servers, available to menu</summary>
  CVAR_USERINFO = 1 shl 9;
  /// <summary>sent from servers, available to menu</summary>
  CVAR_SERVERINFO = 1 shl 10;
  /// <summary>cvar is synced from the server to clients</summary>
  CVAR_NETWORKSYNC = 1 shl 11;
  /// <summary>statically declared, not user created</summary>
  CVAR_STATIC = 1 shl 12;
  /// <summary>variable is considered a cheat</summary>
  CVAR_CHEAT = 1 shl 13;
  /// <summary>variable is not considered a cheat</summary>
  CVAR_NOCHEAT = 1 shl 14;
  /// <summary>can only be set from the command-line</summary>
  CVAR_INIT = 1 shl 15;
  /// <summary>display only, cannot be set by user at all</summary>
  CVAR_ROM = 1 shl 16;
  /// <summary>set to cause it to be saved to a config file</summary>
  CVAR_ARCHIVE = 1 shl 17;
  /// <summary>set when the variable is modified</summary>
  CVAR_MODIFIED = 1 shl 18;

type
  /// <summary>
  ///   The declaration of a variable (the constructors of idCVar): name, initial value, flags,
  ///   description, and optionally a range (a number type) or the valid strings, and the completion
  ///   of the value. CVAR_STATIC is added by the constructors. Without a range, the minimum is 1 and
  ///   the maximum is -1 (the original's way of saying "no range").
  /// </summary>
  TCVarDefinition = record
    Name: AnsiString;
    Value: AnsiString;
    Description: AnsiString;
    Flags: Integer;
    ValueMin: Single;
    ValueMax: Single;
    ValueStrings: TArray<AnsiString>;
    ValueCompletion: TCmdArgCompletion;
    /// <summary>idCVar( name, value, flags, description, valueCompletion )</summary>
    class function Create(const AName, AValue: AnsiString; const AFlags: Integer;
      const ADescription: AnsiString): TCVarDefinition; overload; static;
    /// <summary>idCVar( name, value, flags, description, valueMin, valueMax, valueCompletion )</summary>
    class function Create(const AName, AValue: AnsiString; const AFlags: Integer; const ADescription: AnsiString;
      const AValueMin, AValueMax: Single): TCVarDefinition; overload; static;
    /// <summary>idCVar( name, value, flags, description, valueStrings, valueCompletion )</summary>
    class function Create(const AName, AValue: AnsiString; const AFlags: Integer; const ADescription: AnsiString;
      const AValueStrings: TArray<AnsiString>): TCVarDefinition; overload; static;
  end;

implementation

class function TCVarDefinition.Create(const AName, AValue: AnsiString; const AFlags: Integer;
  const ADescription: AnsiString): TCVarDefinition;
begin
  Result := Create(AName, AValue, AFlags, ADescription, 1, -1);
end;

class function TCVarDefinition.Create(const AName, AValue: AnsiString; const AFlags: Integer;
  const ADescription: AnsiString; const AValueMin, AValueMax: Single): TCVarDefinition;
begin
  Result.Name := AName;
  Result.Value := AValue;
  Result.Description := ADescription;
  Result.Flags := AFlags or CVAR_STATIC;
  Result.ValueMin := AValueMin;
  Result.ValueMax := AValueMax;
  Result.ValueStrings := nil;
  Result.ValueCompletion := nil;
end;

class function TCVarDefinition.Create(const AName, AValue: AnsiString; const AFlags: Integer;
  const ADescription: AnsiString; const AValueStrings: TArray<AnsiString>): TCVarDefinition;
begin
  Result := Create(AName, AValue, AFlags, ADescription, 1, -1);
  Result.ValueStrings := AValueStrings;
end;

end.
