{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptEventDef (idEventDef)      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\gamesys\Event.h,    }
{  Event.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media         }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.EventDef;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types;

type
  /// <summary>
  ///   The definition of an event (idEventDef): its name, the format of its arguments (one character per
  ///   argument: d f v s e E t) and the type it returns. Definitions are created by a
  ///   <c>TDoomScriptEventRegistry</c>, which owns them; there is no global list.
  /// </summary>
  TDoomScriptEventDef = class
  strict private
    FName: AnsiString;
    FFormat: AnsiString;
    FReturnType: AnsiChar;
    FEventNum: Integer;
    FArgSize: Integer;
    FArgOffset: array[0..DS_EVENT_MAXARGS - 1] of Integer;
  public
    /// <summary>Raises EDoomScriptError with the text of the original for a bad format</summary>
    constructor Create(const AName, AFormat: AnsiString; const AReturnType: AnsiChar; const AEventNum: Integer);
    function GetNumArgs: Integer;
    /// <summary>The byte offset of an argument in the data of a queued event (as in the original)</summary>
    function GetArgOffset(const AIndex: Integer): Integer;
    property Name: AnsiString read FName;
    property ArgFormat: AnsiString read FFormat;
    property ReturnType: AnsiChar read FReturnType;
    property EventNum: Integer read FEventNum;
    /// <summary>The bytes of the arguments of a queued event (idEventDef::GetArgSize, 32 bit layout)</summary>
    property ArgSize: Integer read FArgSize;
  end;

implementation

const
  SInvalidFormat = 'idEventDef::idEventDef : Invalid arg format ''%s'' string for ''%s'' event.';
  STooManyArgs = 'idEventDef::idEventDef : Too many args for ''%s'' event.';
  SArgIndex = 'idEventDef::GetArgOffset: argument %d out of range';
  // sizeof( trace_t ) + MAX_STRING_LEN + sizeof( bool ) of the 32 bit build
  TRACE_ARG_SIZE = 100 + DS_MAX_STRING_LEN + 1;

constructor TDoomScriptEventDef.Create(const AName, AFormat: AnsiString; const AReturnType: AnsiChar;
  const AEventNum: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  FName := AName;
  FFormat := AFormat;
  FReturnType := AReturnType;
  FEventNum := AEventNum;
  if Length(AFormat) > DS_EVENT_MAXARGS then
    raise EDoomScriptError.CreateFmt(STooManyArgs, [string(AName)]);
  FArgSize := 0;
  for LIndex := 0 to Length(AFormat) - 1 do
  begin
    FArgOffset[LIndex] := FArgSize;
    case AFormat[LIndex + 1] of
      DS_EVENT_FLOAT, DS_EVENT_INTEGER:
        Inc(FArgSize, 4);
      DS_EVENT_VECTOR:
        Inc(FArgSize, 12);
      DS_EVENT_STRING:
        Inc(FArgSize, DS_MAX_STRING_LEN);
      DS_EVENT_ENTITY, DS_EVENT_ENTITY_NULL:
        // sizeof( idEntityPtr<idEntity> )
        Inc(FArgSize, 4);
      DS_EVENT_TRACE:
        Inc(FArgSize, TRACE_ARG_SIZE);
    else
      raise EDoomScriptError.CreateFmt(SInvalidFormat, [string(AFormat), string(AName)]);
    end;
  end;
end;

function TDoomScriptEventDef.GetNumArgs: Integer;
begin
  Result := Length(FFormat);
end;

function TDoomScriptEventDef.GetArgOffset(const AIndex: Integer): Integer;
begin
  if (AIndex < 0) or (AIndex >= DS_EVENT_MAXARGS) then
    raise EDoomScriptMemoryError.CreateFmt(SArgIndex, [AIndex]);
  Result := FArgOffset[AIndex];
end;

end.
