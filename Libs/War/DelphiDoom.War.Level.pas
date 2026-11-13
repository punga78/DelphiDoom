{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - a level                                           }
{                                                                              }
{  Port of war1 (acoto87/war1), the levelInfo, levelVisual and levelPassable   }
{  resources, (c) 2019 Alejandro Coto Gutierrez, zlib License (see Libs\War\   }
{  LICENSE-war1.txt). This is an altered version, not the original.            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Level;

interface

uses
  System.SysUtils, DelphiDoom.War.Level.Types, DelphiDoom.War.Level.Intf;

type
  /// <summary>A level read from the archive: the info and the two maps</summary>
  TWarLevel = class(TInterfacedObject, IWarLevel)
  strict private
    FInfo: TWarLevelInfo;
    FVisual: TArray<Word>;
    FPassable: TArray<Word>;
    class procedure CheckCell(AX, AY: Integer); static;
  public
    constructor Create(const AInfo: TWarLevelInfo; const AVisual, APassable: TArray<Word>);
    function GetInfo: TWarLevelInfo;
    function GetVisual: TArray<Word>;
    function GetPassable: TArray<Word>;
    function VisualAt(AX, AY: Integer): Word;
    function PassableAt(AX, AY: Integer): Word;
  end;

implementation

uses
  DelphiDoom.War.Types;

{ TWarLevel }

constructor TWarLevel.Create(const AInfo: TWarLevelInfo; const AVisual, APassable: TArray<Word>);
begin
  inherited Create;
  FInfo := AInfo;
  FVisual := AVisual;
  FPassable := APassable;
end;

class procedure TWarLevel.CheckCell(AX, AY: Integer);
begin
  if (AX < 0) or (AX >= WAR_MAP_TILES_WIDTH) or (AY < 0) or (AY >= WAR_MAP_TILES_HEIGHT) then
    raise EWarException.CreateFmt(SWarLevelIndexOutOfRange, [AX, AY]);
end;

function TWarLevel.GetInfo: TWarLevelInfo;
begin
  Result := FInfo;
end;

function TWarLevel.GetVisual: TArray<Word>;
begin
  Result := FVisual;
end;

function TWarLevel.GetPassable: TArray<Word>;
begin
  Result := FPassable;
end;

function TWarLevel.VisualAt(AX, AY: Integer): Word;
begin
  CheckCell(AX, AY);
  Result := FVisual[AY * WAR_MAP_TILES_WIDTH + AX];
end;

function TWarLevel.PassableAt(AX, AY: Integer): Word;
begin
  CheckCell(AX, AY);
  Result := FPassable[AY * WAR_MAP_TILES_WIDTH + AX];
end;

end.
