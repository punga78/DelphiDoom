{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - creation of the game map                          }
{                                                                              }
{  Port of war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib        }
{  License (see Libs\War\LICENSE-war1.txt). This is an altered version.        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Map.Factory;

interface

uses
  DelphiDoom.War.Map.Intf, DelphiDoom.War.Map.Builder;

type
  /// <summary>The place that knows the concrete classes of the game map</summary>
  TWarMapFactory = class
  public
    /// <summary>The tables of the units of the game</summary>
    class function CreateUnitCatalog: IWarUnitCatalog; static;
    /// <summary>The builder of the maps, with the tables of the units of the game</summary>
    class function CreateBuilder: TWarMapBuilder; static;
  end;

implementation

uses
  DelphiDoom.War.Map.Units;

{ TWarMapFactory }

class function TWarMapFactory.CreateUnitCatalog: IWarUnitCatalog;
begin
  Result := TWarUnitCatalog.Create;
end;

class function TWarMapFactory.CreateBuilder: TWarMapBuilder;
begin
  Result := TWarMapBuilder.Create(CreateUnitCatalog);
end;

end.
