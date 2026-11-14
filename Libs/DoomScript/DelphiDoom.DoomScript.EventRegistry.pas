{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptEventRegistry              }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\gamesys\Event.cpp   }
{  (the static list of idEventDef). Copyright (C) 1999-2011 id Software LLC,   }
{  a ZeniMax Media company.                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.EventRegistry;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef;

type
  /// <summary>
  ///   The list of the event definitions (the static <c>idEventDef::eventDefList</c> of the original, here
  ///   an object the composition root creates). An event defined twice with the same name, format and
  ///   return type is the same definition; a different format or return type is an error.
  /// </summary>
  TDoomScriptEventRegistry = class
  strict private
    FDefs: TObjectList<TDoomScriptEventDef>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>idEventDef::idEventDef: defines an event or returns the one already defined</summary>
    function Define(const AName: AnsiString; const AFormat: AnsiString = '';
      const AReturnType: AnsiChar = DS_EVENT_VOID): TDoomScriptEventDef;
    /// <summary>idEventDef::FindEvent: nil if there is none (the name is case sensitive)</summary>
    function FindEvent(const AName: AnsiString): TDoomScriptEventDef;
    /// <summary>idEventDef::NumEventCommands</summary>
    function Count: Integer;
    /// <summary>idEventDef::GetEventCommand</summary>
    function GetEvent(const AEventNum: Integer): TDoomScriptEventDef;
  end;

implementation

const
  SDifferentFormat =
    'idEvent ''%s'' defined twice with same name but differing format strings (''%s''!=''%s'').';
  SDifferentReturn = 'idEvent ''%s'' defined twice with same name but differing return types (''%s''!=''%s'').';
  STooManyEvents = 'numEventDefs >= MAX_EVENTS';
  SBadEventNum = 'idEventDef::GetEventCommand: event %d out of range';

constructor TDoomScriptEventRegistry.Create;
begin
  inherited Create;
  FDefs := TObjectList<TDoomScriptEventDef>.Create(True);
end;

destructor TDoomScriptEventRegistry.Destroy;
begin
  FDefs.Free;
  inherited;
end;

function TDoomScriptEventRegistry.Count: Integer;
begin
  Result := FDefs.Count;
end;

function TDoomScriptEventRegistry.FindEvent(const AName: AnsiString): TDoomScriptEventDef;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDefs.Count - 1 do
    if FDefs[LIndex].Name = AName then
      Exit(FDefs[LIndex]);
  Result := nil;
end;

function TDoomScriptEventRegistry.GetEvent(const AEventNum: Integer): TDoomScriptEventDef;
begin
  if (AEventNum < 0) or (AEventNum >= FDefs.Count) then
    raise EDoomScriptMemoryError.CreateFmt(SBadEventNum, [AEventNum]);
  Result := FDefs[AEventNum];
end;

function TDoomScriptEventRegistry.Define(const AName, AFormat: AnsiString;
  const AReturnType: AnsiChar): TDoomScriptEventDef;
begin
  Result := FindEvent(AName);
  if Assigned(Result) then
  begin
    if Result.ArgFormat <> AFormat then
      raise EDoomScriptError.CreateFmt(SDifferentFormat, [string(AName), string(AFormat), string(Result.ArgFormat)]);
    if Result.ReturnType <> AReturnType then
      raise EDoomScriptError.CreateFmt(SDifferentReturn, [string(AName), string(AnsiString(AReturnType)),
        string(AnsiString(Result.ReturnType))]);
    Exit;
  end;
  if FDefs.Count >= DS_MAX_EVENTS then
    raise EDoomScriptError.Create(STooManyEvents);
  Result := TDoomScriptEventDef.Create(AName, AFormat, AReturnType, FDefs.Count);
  FDefs.Add(Result);
end;

end.
