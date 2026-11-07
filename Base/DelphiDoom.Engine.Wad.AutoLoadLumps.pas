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
  DelphiDoom.Scanner.AutoLoad.Intf;

type
  /// <summary>The lump directory of the engine (w_wad), read when asked</summary>
  TEngineAutoLoadLumps = class(TInterfacedObject, IAutoLoadLumps)
  public
    function GetCount: Integer;
    function NameOf(AIndex: Integer): string;
    function TextOf(AIndex: Integer): string;
  end;

implementation

uses
  w_wad;

{ TEngineAutoLoadLumps }

function TEngineAutoLoadLumps.GetCount: Integer;
begin
  Result := W_NumLumps;
end;

function TEngineAutoLoadLumps.NameOf(AIndex: Integer): string;
begin
  Result := char8tostring(W_GetNameForNum(AIndex));
end;

function TEngineAutoLoadLumps.TextOf(AIndex: Integer): string;
begin
  Result := W_TextLumpNum(AIndex);
end;

end.
