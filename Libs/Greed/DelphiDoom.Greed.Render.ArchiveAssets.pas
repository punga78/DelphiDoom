{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the renderer assets read from the archive        }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): RF_PreloadGraphics and the   }
{  lump cache of d_disk.pas, with the lumps read when they are first needed     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Render.ArchiveAssets;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Render.Assets.Intf;

type
  /// <summary>The lumps of GREED.BLO, each read the first time the renderer asks for it</summary>
  TGreedArchiveRenderAssets = class(TInterfacedObject, IGreedRenderAssets)
  strict private
    const
      GUARD_BYTES = 512;
      BACKDROP_BYTES = 256 * 256;
    var
      FArchive: IGreedArchive;
      FWallLump: Integer;
      FFlatLump: Integer;
      FWallCount: Integer;
      FFlatCount: Integer;
      FWalls: TArray<TBytes>;
      FWallLoaded: TArray<Boolean>;
      FFlats: TArray<TBytes>;
      FFlatLoaded: TArray<Boolean>;
      FSprites: TArray<TBytes>;
      FSpriteLoaded: TArray<Boolean>;
      FColorMaps: TBytes;
      FTransparency: TBytes;
      FBackdrop: TBytes;
    function ReadPadded(ALump: Integer): TBytes;
  public
    constructor Create(const AArchive: IGreedArchive);
    function GetWallCount: Integer;
    function GetFlatCount: Integer;
    function WallLump(AIndex: Integer): TBytes;
    function FlatLump(AIndex: Integer): TBytes;
    function SpriteLump(ALump: Integer): TBytes;
    function ColorMaps: TBytes;
    function Transparency: TBytes;
    function Backdrop: TBytes;
    /// <summary>
    ///   The sky of a map (the BACKDROP of its script): the pictures AFirstLump and the next one, each of
    ///   256 x 128 pixels after the 8 bytes of a picture header, as LoadEventData reads them
    /// </summary>
    procedure LoadBackdrop(AFirstLump: Integer);
    /// <summary>The sky from 65536 bytes that the caller has (the tests give a known one)</summary>
    procedure SetBackdrop(const ABytes: TBytes);
  end;

implementation

uses
  DelphiDoom.Greed.Types;

{ TGreedArchiveRenderAssets }

constructor TGreedArchiveRenderAssets.Create(const AArchive: IGreedArchive);
var
  LStart: Integer;
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FArchive := AArchive;
  FWallLump := AArchive.RequireIndexOf(GREED_LUMP_START_WALLS);
  FWallCount := AArchive.RequireIndexOf(GREED_LUMP_END_WALLS) - FWallLump;
  FFlatLump := AArchive.RequireIndexOf(GREED_LUMP_START_FLATS);
  FFlatCount := AArchive.RequireIndexOf(GREED_LUMP_END_FLATS) - FFlatLump;
  SetLength(FWalls, FWallCount + 1);
  SetLength(FWallLoaded, FWallCount + 1);
  SetLength(FFlats, FFlatCount + 1);
  SetLength(FFlatLoaded, FFlatCount + 1);
  LStart := AArchive.LumpCount;
  SetLength(FSprites, LStart);
  SetLength(FSpriteLoaded, LStart);
  SetLength(FBackdrop, BACKDROP_BYTES + GUARD_BYTES);
end;

function TGreedArchiveRenderAssets.ReadPadded(ALump: Integer): TBytes;
var
  LLump: TBytes;
begin
  LLump := FArchive.ReadLump(ALump);
  SetLength(Result, Length(LLump) + GUARD_BYTES);
  if Length(LLump) > 0 then
    Move(LLump[0], Result[0], Length(LLump));
end;

function TGreedArchiveRenderAssets.GetWallCount: Integer;
begin
  Result := FWallCount;
end;

function TGreedArchiveRenderAssets.GetFlatCount: Integer;
begin
  Result := FFlatCount;
end;

function TGreedArchiveRenderAssets.WallLump(AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex > FWallCount) or (FWallLump + AIndex >= FArchive.LumpCount) then
    Exit(nil);
  if not FWallLoaded[AIndex] then
  begin
    if FArchive.GetLumpSize(FWallLump + AIndex) > 0 then
      FWalls[AIndex] := ReadPadded(FWallLump + AIndex);
    FWallLoaded[AIndex] := True;
  end;
  Result := FWalls[AIndex];
end;

function TGreedArchiveRenderAssets.FlatLump(AIndex: Integer): TBytes;
begin
  if (AIndex < 0) or (AIndex > FFlatCount) or (FFlatLump + AIndex >= FArchive.LumpCount) then
    Exit(nil);
  if not FFlatLoaded[AIndex] then
  begin
    if FArchive.GetLumpSize(FFlatLump + AIndex) > 0 then
      FFlats[AIndex] := ReadPadded(FFlatLump + AIndex);
    FFlatLoaded[AIndex] := True;
  end;
  Result := FFlats[AIndex];
end;

function TGreedArchiveRenderAssets.SpriteLump(ALump: Integer): TBytes;
begin
  if (ALump < 0) or (ALump >= Length(FSprites)) then
    Exit(nil);
  if not FSpriteLoaded[ALump] then
  begin
    if FArchive.GetLumpSize(ALump) > 0 then
      FSprites[ALump] := ReadPadded(ALump);
    FSpriteLoaded[ALump] := True;
  end;
  Result := FSprites[ALump];
end;

function TGreedArchiveRenderAssets.ColorMaps: TBytes;
begin
  if FColorMaps = nil then
    FColorMaps := ReadPadded(FArchive.RequireIndexOf('lights'));
  Result := FColorMaps;
end;

function TGreedArchiveRenderAssets.Transparency: TBytes;
begin
  if FTransparency = nil then
    FTransparency := ReadPadded(FArchive.RequireIndexOf('TRANSPARENCY'));
  Result := FTransparency;
end;

function TGreedArchiveRenderAssets.Backdrop: TBytes;
begin
  Result := FBackdrop;
end;

procedure TGreedArchiveRenderAssets.SetBackdrop(const ABytes: TBytes);
begin
  FillChar(FBackdrop[0], Length(FBackdrop), 0);
  Move(ABytes[0], FBackdrop[0], Length(ABytes));
end;

procedure TGreedArchiveRenderAssets.LoadBackdrop(AFirstLump: Integer);
const
  HALF = 256 * 128;
  HEADER = 8;
var
  LTop, LBottom: TBytes;
begin
  FillChar(FBackdrop[0], Length(FBackdrop), 0);
  LTop := FArchive.ReadLump(AFirstLump);
  LBottom := FArchive.ReadLump(AFirstLump + 1);
  if Length(LTop) >= HEADER + HALF then
    Move(LTop[HEADER], FBackdrop[0], HALF);
  if Length(LBottom) >= HEADER + HALF then
    Move(LBottom[HEADER], FBackdrop[HALF], HALF);
end;

end.
