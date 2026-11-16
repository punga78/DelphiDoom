{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the defines of the game                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of sc_defines.pas (gamedefines, SC_AddDefine) of DelphiDoom            }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.GameDefines;

interface

uses
  System.Generics.Collections,
  DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>
  ///   The names that every script finds defined: in upper case, each one once, in the order
  ///   in which they were added
  /// </summary>
  TScriptGameDefines = class(TInterfacedObject, IScriptDefinesSource, IScriptGameDefines)
  strict private
    FNames: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Adds a name in upper case; a name that is already there is not added again</summary>
    procedure Add(const AName: string);
    /// <summary>Forgets every name</summary>
    procedure Clear;
    /// <summary>A copy of the names, in the order in which they were added</summary>
    function Defines: TArray<string>;
  end;

implementation

uses
  System.SysUtils;

{ TScriptGameDefines }

constructor TScriptGameDefines.Create;
begin
  inherited Create;
  FNames := TList<string>.Create;
end;

destructor TScriptGameDefines.Destroy;
begin
  FNames.Free;
  inherited;
end;

procedure TScriptGameDefines.Add(const AName: string);
var
  LName: string;
begin
  // UpperCase changes only the ASCII letters, as the old SC_AddDefine
  LName := UpperCase(AName);
  if FNames.IndexOf(LName) < 0 then
    FNames.Add(LName);
end;

procedure TScriptGameDefines.Clear;
begin
  FNames.Clear;
end;

function TScriptGameDefines.Defines: TArray<string>;
begin
  Result := FNames.ToArray;
end;

end.
