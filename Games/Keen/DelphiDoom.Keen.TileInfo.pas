{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the tile info table                               }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  SPEED, ANIM, NORTHWALL... of id_ca.h (the bytes of MAPHEAD after the 502)    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.TileInfo;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf;

type
  /// <summary>
  ///   Nine tables one after the other: speed and animation of the 1440 background tiles, then for each of
  ///   the 1206 foreground tiles the four walls, the animation, the "intile" behaviour and the speed
  /// </summary>
  TKeenTileInfo = class(TInterfacedObject, IKeenTileInfo)
  strict private
    FBytes: TBytes;
    function ByteAt(ATable, ATile, ATileCount: Integer): Byte;
  public
    /// <param name="ABytes">The table: KEEN_TINF_SIZE bytes</param>
    constructor Create(const ABytes: TBytes);
    function GetBytes: TBytes;
    function Speed(ATile: Integer): Byte;
    function Animation(ATile: Integer): ShortInt;
    function NorthWall(ATile: Integer): Byte;
    function EastWall(ATile: Integer): Byte;
    function SouthWall(ATile: Integer): Byte;
    function WestWall(ATile: Integer): Byte;
    function MaskedAnimation(ATile: Integer): ShortInt;
    function InTile(ATile: Integer): Byte;
    function MaskedSpeed(ATile: Integer): Byte;
  end;

implementation

{ TKeenTileInfo }

constructor TKeenTileInfo.Create(const ABytes: TBytes);
begin
  inherited Create;
  if Length(ABytes) < KEEN_TINF_SIZE then
    raise EKeenDataException.CreateFmt(SKeenHeaderInvalid,
      ['the tile info', Length(ABytes), KEEN_TINF_SIZE]);
  FBytes := Copy(ABytes, 0, KEEN_TINF_SIZE);
end;

function TKeenTileInfo.ByteAt(ATable, ATile, ATileCount: Integer): Byte;
begin
  if (ATile < 0) or (ATile >= ATileCount) then
    raise EKeenDataException.CreateFmt(SKeenTileInvalid, [ATile, ATileCount]);
  Result := FBytes[ATable + ATile];
end;

function TKeenTileInfo.GetBytes: TBytes;
begin
  Result := Copy(FBytes);
end;

function TKeenTileInfo.Speed(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_SPEED, ATile, KEEN_NUMTILE16);
end;

function TKeenTileInfo.Animation(ATile: Integer): ShortInt;
begin
  Result := ShortInt(ByteAt(KEEN_TINF_ANIM, ATile, KEEN_NUMTILE16));
end;

function TKeenTileInfo.NorthWall(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_NORTHWALL, ATile, KEEN_NUMTILE16M);
end;

function TKeenTileInfo.EastWall(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_EASTWALL, ATile, KEEN_NUMTILE16M);
end;

function TKeenTileInfo.SouthWall(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_SOUTHWALL, ATile, KEEN_NUMTILE16M);
end;

function TKeenTileInfo.WestWall(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_WESTWALL, ATile, KEEN_NUMTILE16M);
end;

function TKeenTileInfo.MaskedAnimation(ATile: Integer): ShortInt;
begin
  Result := ShortInt(ByteAt(KEEN_TINF_MANIM, ATile, KEEN_NUMTILE16M));
end;

function TKeenTileInfo.InTile(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_INTILE, ATile, KEEN_NUMTILE16M);
end;

function TKeenTileInfo.MaskedSpeed(ATile: Integer): Byte;
begin
  Result := ByteAt(KEEN_TINF_MSPEED, ATile, KEEN_NUMTILE16M);
end;

end.
