{******************************************************************************}
{                                                                              }
{  DelphiDoom: the lumps of the loaded files, for the AUTOLOAD reader           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.AutoLoadLumps;

interface

uses
  DelphiDoom.Scanner.AutoLoad.Intf,
  DelphiDoom.Engine.Wad.Lumps.Intf;

type
  /// <summary>The lump directory of the engine, read when asked</summary>
  TEngineAutoLoadLumps = class(TInterfacedObject, IAutoLoadLumps)
  strict private
    FLumps: IEngineLumps;
  public
    constructor Create(const ALumps: IEngineLumps);
    function GetCount: Integer;
    function NameOf(AIndex: Integer): string;
    function TextOf(AIndex: Integer): string;
  end;

implementation

uses
  System.SysUtils;

{ TEngineAutoLoadLumps }

constructor TEngineAutoLoadLumps.Create(const ALumps: IEngineLumps);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create('ALumps');
  FLumps := ALumps;
end;

function TEngineAutoLoadLumps.GetCount: Integer;
begin
  Result := FLumps.Count;
end;

function TEngineAutoLoadLumps.NameOf(AIndex: Integer): string;
begin
  Result := FLumps.NameOf(AIndex);
end;

function TEngineAutoLoadLumps.TextOf(AIndex: Integer): string;
begin
  Result := FLumps.TextOf(AIndex);
end;

end.
