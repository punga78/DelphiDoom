{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a level with the info of a custom game             }
{                                                                              }
{  Port of war1 (acoto87/war1), what wmap_createCustomMap does to the level     }
{  info record, (c) 2019 Alejandro Coto Gutierrez, zlib License (see            }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level.CustomLevel;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf;

type
  /// <summary>
  ///   A level whose info is the one a custom game made (the races, the units, the gold) and whose maps are those of the
  ///   level it was made from. The maps are shared, not copied: the forests that a game plants change the visual map, and a
  ///   map that starts again from the same level finds it as the first one left it, as in the original
  /// </summary>
  TWarCustomLevel = class(TInterfacedObject, IWarLevel)
  strict private
    FBase: IWarLevel;
    FInfo: TWarLevelInfo;
  public
    constructor Create(const ABase: IWarLevel; const AInfo: TWarLevelInfo);
    function GetInfo: TWarLevelInfo;
    function GetVisual: TArray<Word>;
    function GetPassable: TArray<Word>;
    function VisualAt(AX, AY: Integer): Word;
    function PassableAt(AX, AY: Integer): Word;
  end;

implementation

{ TWarCustomLevel }

constructor TWarCustomLevel.Create(const ABase: IWarLevel; const AInfo: TWarLevelInfo);
begin
  inherited Create;
  FBase := ABase;
  FInfo := AInfo;
end;

function TWarCustomLevel.GetInfo: TWarLevelInfo;
begin
  Result := FInfo;
end;

function TWarCustomLevel.GetVisual: TArray<Word>;
begin
  Result := FBase.Visual;
end;

function TWarCustomLevel.GetPassable: TArray<Word>;
begin
  Result := FBase.Passable;
end;

function TWarCustomLevel.VisualAt(AX, AY: Integer): Word;
begin
  Result := FBase.VisualAt(AX, AY);
end;

function TWarCustomLevel.PassableAt(AX, AY: Integer): Word;
begin
  Result := FBase.PassableAt(AX, AY);
end;

end.
