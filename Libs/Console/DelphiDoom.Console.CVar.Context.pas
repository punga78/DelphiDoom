{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - idTech 4 cvars, what a variable asks of       }
{  its system                                                                  }
{                                                                              }
{  Port of Doom 3 (id Software, GPL v3): framework\CVarSystem.cpp              }
{  (the uses that idInternalCVar makes of cvarSystem, common and session).     }
{  Based on the Doom 3 GPL Source Code (id Software).                          }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CVar.Context;

interface

uses
  DelphiDoom.IdLib.Core.Intf, DelphiDoom.Console.CmdSystem.Intf;

type
  /// <summary>Gives the value of a boolean variable by name (cvarSystem->GetCVarBool)</summary>
  TCVarBoolLookup = function(const AName: AnsiString): Boolean of object;

  /// <summary>
  ///   The singletons that idInternalCVar used (<c>cvarSystem</c>, <c>common</c>, <c>session</c>)
  ///   as one object that every variable of a system shares: the log, the session, the modified
  ///   flags of the system and the lookup of "net_allowCheats". It is a plain object (the system
  ///   owns it) so that the variables, which the system owns, do not make a cycle of
  ///   references.
  /// </summary>
  TCVarContext = class
  strict private
    FLog: IIdLibLog;
    FSession: IConsoleSession;
    FModifiedFlags: Integer;
    FBoolLookup: TCVarBoolLookup;
  public
    constructor Create(const ALog: IIdLibLog; const ASession: IConsoleSession);
    procedure Print(const AText: string);
    procedure Warning(const AText: string);
    function IsMultiplayer: Boolean;
    function IsNetworkClientActive: Boolean;
    function GetCVarBool(const AName: AnsiString): Boolean;
    /// <summary>idCVarSystemLocal::SetModifiedFlags</summary>
    procedure SetModifiedFlags(const AFlags: Integer);
    property ModifiedFlags: Integer read FModifiedFlags write FModifiedFlags;
    property BoolLookup: TCVarBoolLookup read FBoolLookup write FBoolLookup;
  end;

implementation

constructor TCVarContext.Create(const ALog: IIdLibLog; const ASession: IConsoleSession);
begin
  inherited Create;
  FLog := ALog;
  FSession := ASession;
end;

procedure TCVarContext.Print(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Printf(AText);
end;

procedure TCVarContext.Warning(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Warning(AText);
end;

function TCVarContext.IsMultiplayer: Boolean;
begin
  Result := Assigned(FSession) and FSession.IsMultiplayer;
end;

function TCVarContext.IsNetworkClientActive: Boolean;
begin
  Result := Assigned(FSession) and FSession.IsNetworkClientActive;
end;

function TCVarContext.GetCVarBool(const AName: AnsiString): Boolean;
begin
  Result := Assigned(FBoolLookup) and FBoolLookup(AName);
end;

procedure TCVarContext.SetModifiedFlags(const AFlags: Integer);
begin
  FModifiedFlags := FModifiedFlags or AFlags;
end;

end.
