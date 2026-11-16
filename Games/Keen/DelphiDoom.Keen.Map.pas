{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - a map                                             }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  maptype and mapsegs of id_ca.h                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Map;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   A map once expanded: the header and the 3 planes of Width * Height words (the background tiles,
  ///   the foreground tiles and the info plane with the actors and the special places)
  /// </summary>
  TKeenMap = class(TInterfacedObject, IKeenMap)
  strict private
    FNumber: Integer;
    FHeader: TKeenMapHeader;
    FPlanes: array[0..2] of TArray<Word>;
  public
    /// <param name="ANumber">The slot of the map in MAPHEAD</param>
    /// <param name="AHeader">The header of the map (maptype)</param>
    /// <param name="APlanes">The 3 planes; each needs Width * Height words</param>
    constructor Create(ANumber: Integer; const AHeader: TKeenMapHeader;
      const APlanes: array of TArray<Word>);
    function GetNumber: Integer;
    function GetName: string;
    function GetWidth: Integer;
    function GetHeight: Integer;
    function GetHeader: TKeenMapHeader;
    function GetPlane(APlane: Integer): TArray<Word>;
    function GetTile(APlane, AX, AY: Integer): Word;
  end;

implementation

{ TKeenMap }

constructor TKeenMap.Create(ANumber: Integer; const AHeader: TKeenMapHeader;
  const APlanes: array of TArray<Word>);
var
  LPlane: Integer;
begin
  inherited Create;
  if Length(APlanes) <> 3 then
    raise EKeenDataException.CreateFmt(SKeenMapBadPlane, [Length(APlanes), ANumber, '3 planes needed']);
  FNumber := ANumber;
  FHeader := AHeader;
  for LPlane := 0 to 2 do
  begin
    if Length(APlanes[LPlane]) <> Integer(AHeader.Width) * Integer(AHeader.Height) then
      raise EKeenDataException.CreateFmt(SKeenMapBadPlane,
        [LPlane, ANumber, Format('%d words, %d x %d needed',
          [Length(APlanes[LPlane]), AHeader.Width, AHeader.Height])]);
    FPlanes[LPlane] := APlanes[LPlane];
  end;
end;

function TKeenMap.GetNumber: Integer;
begin
  Result := FNumber;
end;

function TKeenMap.GetName: string;
var
  LIndex: Integer;
begin
  // a C string of at most 16 characters, ended by a zero when it is shorter
  Result := '';
  for LIndex := 0 to High(FHeader.Name) do
  begin
    if FHeader.Name[LIndex] = #0 then
      Break;
    Result := Result + Char(Ord(FHeader.Name[LIndex]));
  end;
end;

function TKeenMap.GetWidth: Integer;
begin
  Result := FHeader.Width;
end;

function TKeenMap.GetHeight: Integer;
begin
  Result := FHeader.Height;
end;

function TKeenMap.GetHeader: TKeenMapHeader;
begin
  Result := FHeader;
end;

function TKeenMap.GetPlane(APlane: Integer): TArray<Word>;
begin
  if (APlane < 0) or (APlane > 2) then
    raise EKeenDataException.CreateFmt(SKeenMapBadPlane, [APlane, FNumber, 'planes are 0..2']);
  Result := FPlanes[APlane];
end;

function TKeenMap.GetTile(APlane, AX, AY: Integer): Word;
begin
  if (AX < 0) or (AX >= GetWidth) or (AY < 0) or (AY >= GetHeight) then
    raise EKeenDataException.CreateFmt(SKeenTileOutside, [AX, AY, FNumber]);
  Result := GetPlane(APlane)[AY * GetWidth + AX];
end;

end.
