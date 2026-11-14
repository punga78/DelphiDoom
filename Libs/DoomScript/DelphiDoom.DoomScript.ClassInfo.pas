{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom script (id Tech 4) - TDoomScriptClassInfo (idTypeInfo)     }
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
unit DelphiDoom.DoomScript.ClassInfo;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.EventDef;

type
  /// <summary>
  ///   The code an object runs for an event (the <c>eventCallback_t</c> of the original). The target is the
  ///   object that receives the event (a TDoomScriptEventTarget).
  /// </summary>
  TDoomScriptEventHandler = reference to procedure(const ATarget: TObject; const AEvent: TDoomScriptEventDef;
    const AArgs: TDoomScriptEventArgs);

  /// <summary>
  ///   What the script system needs of idTypeInfo: the name of a class of the host, its superclass and the
  ///   events it responds to. A class inherits the handlers of its superclass and may replace them
  ///   (idTypeInfo::Init).
  /// </summary>
  TDoomScriptClassInfo = class
  strict private
    FName: AnsiString;
    FSuper: TDoomScriptClassInfo;
    FHandlers: TDictionary<Integer, TDoomScriptEventHandler>;
  public
    constructor Create(const AName: AnsiString; const ASuper: TDoomScriptClassInfo);
    destructor Destroy; override;
    /// <summary>EVENT( ev, function ): the handler of this class for an event; replaces a previous one</summary>
    procedure AddEvent(const AEvent: TDoomScriptEventDef; const AHandler: TDoomScriptEventHandler);
    /// <summary>The handler of this class or of the nearest superclass that has one; nil if none</summary>
    function FindHandler(const AEvent: TDoomScriptEventDef): TDoomScriptEventHandler;
    /// <summary>idTypeInfo::RespondsTo</summary>
    function RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
    /// <summary>idTypeInfo::IsType: this class is the other one or descends from it</summary>
    function IsType(const AOther: TDoomScriptClassInfo): Boolean;
    property Name: AnsiString read FName;
    property Super: TDoomScriptClassInfo read FSuper;
  end;

implementation

constructor TDoomScriptClassInfo.Create(const AName: AnsiString; const ASuper: TDoomScriptClassInfo);
begin
  inherited Create;
  FName := AName;
  FSuper := ASuper;
  FHandlers := TDictionary<Integer, TDoomScriptEventHandler>.Create;
end;

destructor TDoomScriptClassInfo.Destroy;
begin
  FHandlers.Free;
  inherited;
end;

procedure TDoomScriptClassInfo.AddEvent(const AEvent: TDoomScriptEventDef; const AHandler: TDoomScriptEventHandler);
begin
  FHandlers.AddOrSetValue(AEvent.EventNum, AHandler);
end;

function TDoomScriptClassInfo.FindHandler(const AEvent: TDoomScriptEventDef): TDoomScriptEventHandler;
var
  LClass: TDoomScriptClassInfo;
begin
  LClass := Self;
  while Assigned(LClass) do
  begin
    if LClass.FHandlers.TryGetValue(AEvent.EventNum, Result) then
      Exit;
    LClass := LClass.FSuper;
  end;
  Result := nil;
end;

function TDoomScriptClassInfo.RespondsTo(const AEvent: TDoomScriptEventDef): Boolean;
begin
  Result := Assigned(FindHandler(AEvent));
end;

function TDoomScriptClassInfo.IsType(const AOther: TDoomScriptClassInfo): Boolean;
var
  LClass: TDoomScriptClassInfo;
begin
  LClass := Self;
  while Assigned(LClass) do
  begin
    if LClass = AOther then
      Exit(True);
    LClass := LClass.FSuper;
  end;
  Result := False;
end;

end.
