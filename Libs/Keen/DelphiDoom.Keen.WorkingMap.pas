{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the map that is played                            }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  mapsegs[] of id_ca.c                                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.WorkingMap;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   The 3 planes of the map of the level, that the game changes (the animation of the tiles, the tiles
  ///   that an actor takes away): a copy of a map of the file, so the file is not touched
  /// </summary>
  TKeenWorkingMap = class(TInterfacedObject, IKeenWorkingMap)
  strict private
    FNumber: Integer;
    FName: string;
    FWidth: Integer;
    FHeight: Integer;
    FPlanes: array[0..2] of TArray<Word>;
  public
    /// <summary>A copy of the map of the file</summary>
    constructor Create(const AMap: IKeenMap); overload;
    /// <summary>An empty map (every word 0) of AWidth x AHeight tiles</summary>
    constructor Create(AWidth, AHeight: Integer); overload;
    function GetNumber: Integer;
    function GetName: string;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetPlane(APlane: Integer): TArray<Word>;
  end;

implementation

{ TKeenWorkingMap }

constructor TKeenWorkingMap.Create(const AMap: IKeenMap);
var
  LPlane: Integer;
begin
  inherited Create;
  if not Assigned(AMap) then
    raise EArgumentNilException.Create('AMap');
  FNumber := AMap.Number;
  FName := AMap.Name;
  FWidth := AMap.Width;
  FHeight := AMap.Height;
  for LPlane := 0 to 2 do
    FPlanes[LPlane] := Copy(AMap.Planes[LPlane]);
end;

constructor TKeenWorkingMap.Create(AWidth, AHeight: Integer);
var
  LPlane: Integer;
begin
  inherited Create;
  if (AWidth <= 0) or (AHeight <= 0) or (AHeight > KEEN_MAXMAPHEIGHT) then
    raise EKeenException.CreateFmt(SKeenSizeInvalid, [AWidth, AHeight]);
  FNumber := -1;
  FWidth := AWidth;
  FHeight := AHeight;
  for LPlane := 0 to 2 do
    SetLength(FPlanes[LPlane], AWidth * AHeight);
end;

function TKeenWorkingMap.GetNumber: Integer;
begin
  Result := FNumber;
end;

function TKeenWorkingMap.GetName: string;
begin
  Result := FName;
end;

function TKeenWorkingMap.GetWidth: Integer;
begin
  Result := FWidth;
end;

function TKeenWorkingMap.GetHeight: Integer;
begin
  Result := FHeight;
end;

function TKeenWorkingMap.GetPlane(APlane: Integer): TArray<Word>;
begin
  if (APlane < 0) or (APlane > 2) then
    raise EKeenDataException.CreateFmt(SKeenMapBadPlane, [APlane, FNumber, 'planes are 0..2']);
  Result := FPlanes[APlane];
end;

end.
