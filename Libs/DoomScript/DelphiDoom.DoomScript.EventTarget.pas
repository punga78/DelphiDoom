{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptEventTarget (idClass)      }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software): game\gamesys\Class.h,    }
{  Class.cpp. Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media         }
{  company.                                                                    }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3 or later, with    }
{  the additional terms of the Doom 3 Source Code License (see README.md of    }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DoomScript.EventTarget;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef, DelphiDoom.DoomScript.ClassInfo;

type
  /// <summary>
  ///   An object that receives events (what the script system needs of idClass): a script thread, or an
  ///   object of the host (an entity). Its class says which events it responds to.
  /// </summary>
  TDoomScriptEventTarget = class
  strict private
    FClassInfo: TDoomScriptClassInfo;
  public
    constructor Create(const AClassInfo: TDoomScriptClassInfo);
    /// <summary>idClass::RespondsTo</summary>
    function RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
    /// <summary>
    ///   idClass::ProcessEventArgPtr: runs the handler of the class now. False if the class does not
    ///   respond to the event. The handler may free the target.
    /// </summary>
    function ProcessEvent(const AEvent: TDoomScriptEventDef; const AArgs: TDoomScriptEventArgs): Boolean; overload;
    /// <summary>idClass::ProcessEvent without arguments</summary>
    function ProcessEvent(const AEvent: TDoomScriptEventDef): Boolean; overload;
    /// <summary>
    ///   idClass::ProcessEvent with arguments given by the host: false if the class does not respond; otherwise
    ///   the arguments are checked against the format of the event as idEvent::CopyArgs does (number and kind;
    ///   an integer 0 passes for a missing 'e' entity) and EDoomScriptError is raised if they do not match. As in
    ///   the original, an entity argument has the kind 'e': an event with an 'E' argument cannot be sent this way.
    /// </summary>
    function ProcessHostEvent(const AEvent: TDoomScriptEventDef; const AArgs: array of TDoomScriptEventArg): Boolean;
    /// <summary>idClass::GetType</summary>
    property EventClass: TDoomScriptClassInfo read FClassInfo;
  end;

implementation

const
  SNoClass = 'TDoomScriptEventTarget: a target needs a class';
  SWrongArgCount = 'idEvent::CopyArgs : Wrong number of args for ''%s'' event.';
  SWrongArgType = 'idEvent::CopyArgs : Wrong type passed in for arg # %d on ''%s'' event.';

constructor TDoomScriptEventTarget.Create(const AClassInfo: TDoomScriptClassInfo);
begin
  inherited Create;
  if not Assigned(AClassInfo) then
    raise EDoomScriptError.Create(SNoClass);
  FClassInfo := AClassInfo;
end;

function TDoomScriptEventTarget.RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
begin
  Result := FClassInfo.RespondsTo(AEvent);
end;

function TDoomScriptEventTarget.ProcessEvent(const AEvent: TDoomScriptEventDef;
  const AArgs: TDoomScriptEventArgs): Boolean;
var
  LHandler: TDoomScriptEventHandler;
begin
  LHandler := FClassInfo.FindHandler(AEvent);
  Result := Assigned(LHandler);
  if Result then
    LHandler(Self, AEvent, AArgs);
end;

function TDoomScriptEventTarget.ProcessEvent(const AEvent: TDoomScriptEventDef): Boolean;
var
  LArgs: TDoomScriptEventArgs;
begin
  LArgs := Default(TDoomScriptEventArgs);
  Result := ProcessEvent(AEvent, LArgs);
end;

function TDoomScriptEventTarget.ProcessHostEvent(const AEvent: TDoomScriptEventDef;
  const AArgs: array of TDoomScriptEventArg): Boolean;
var
  LArgs: TDoomScriptEventArgs;
  LIndex: Integer;
  LKind: AnsiChar;
begin
  if not RespondsTo(AEvent) then
    // we don't respond to this event, so ignore it
    Exit(False);
  if Length(AArgs) <> AEvent.GetNumArgs then
    raise EDoomScriptError.CreateFmt(SWrongArgCount, [string(AEvent.Name)]);
  LArgs := Default(TDoomScriptEventArgs);
  for LIndex := 0 to Length(AArgs) - 1 do
  begin
    LKind := AEvent.ArgFormat[LIndex + 1];
    if LKind <> AArgs[LIndex].Kind then
      // when NULL is passed in for an entity, it gets cast as an integer 0, so no error then
      if not ((LKind in [DS_EVENT_TRACE, DS_EVENT_ENTITY]) and (AArgs[LIndex].Kind = DS_EVENT_INTEGER) and
        (AArgs[LIndex].IntValue = 0)) then
        raise EDoomScriptError.CreateFmt(SWrongArgType, [LIndex, string(AEvent.Name)]);
    LArgs[LIndex] := AArgs[LIndex];
    if (LKind = DS_EVENT_ENTITY) and (AArgs[LIndex].Kind = DS_EVENT_INTEGER) then
      LArgs[LIndex].IntValue := -1;
    LArgs[LIndex].Kind := LKind;
  end;
  Result := ProcessEvent(AEvent, LArgs);
end;

end.
