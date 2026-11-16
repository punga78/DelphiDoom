{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - a game lookup that accepts everything       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Anim.PermissiveLookup;

interface

uses
  DelphiDoom.Models.Anim.Intf;

type
  /// <summary>
  ///   The lookup of the game when there is no game: every function, event, skin, fx and entity
  ///   def exists (an event has no arguments) and every sound shader exists. A parse of a
  ///   MODELDEF then checks only what the file itself says.
  /// </summary>
  TModelDefPermissiveLookup = class(TInterfacedObject, IModelDefGameLookup)
  public
    function FindScriptFunction(const AName: AnsiString): Boolean;
    function FindEvent(const AName: AnsiString; out AArgumentCount: Integer): Boolean;
    function FindSkin(const AName: AnsiString): Boolean;
    function FindFx(const AName: AnsiString): Boolean;
    function FindEntityDef(const AName: AnsiString): Boolean;
    function IsSoundDefaulted(const AName: AnsiString): Boolean;
  end;

implementation

{ TModelDefPermissiveLookup }

function TModelDefPermissiveLookup.FindScriptFunction(const AName: AnsiString): Boolean;
begin
  Result := True;
end;

function TModelDefPermissiveLookup.FindEvent(const AName: AnsiString; out AArgumentCount: Integer): Boolean;
begin
  AArgumentCount := 0;
  Result := True;
end;

function TModelDefPermissiveLookup.FindSkin(const AName: AnsiString): Boolean;
begin
  Result := True;
end;

function TModelDefPermissiveLookup.FindFx(const AName: AnsiString): Boolean;
begin
  Result := True;
end;

function TModelDefPermissiveLookup.FindEntityDef(const AName: AnsiString): Boolean;
begin
  Result := True;
end;

function TModelDefPermissiveLookup.IsSoundDefaulted(const AName: AnsiString): Boolean;
begin
  Result := False;
end;

end.
