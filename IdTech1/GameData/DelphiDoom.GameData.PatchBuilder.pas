{******************************************************************************}
{                                                                              }
{  DelphiDoom: game data library - TGamePatchBuilder                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of MARS_CreateDoomPatch, RX_CreateDoomPatch and SH_CreateDoomPatch     }
{  (and the variants from lump data) of the forks Mars3D, Rad-X and Speed      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GameData.PatchBuilder;

interface

uses
  System.SysUtils, System.Classes,
  DelphiDoom.Palette.Intf, DelphiDoom.GameData.Types, DelphiDoom.GameData.Intf;

type
  /// <summary>
  ///   Builds a patch the way the forks did: a column is made of one post for every run of
  ///   pixels that are not holes (top delta, length, a byte of padding, the pixels, a byte of
  ///   padding) and ends with the pair 255, 0; the column offsets follow the header
  /// </summary>
  TGamePatchBuilder = class(TInterfacedObject, IGamePatchBuilder)
  strict private
    FOptions: TGamePatchOptions;
    FMatcher: IColorMatcher;
    function Build(const AImage: TBytes; AWidth, AHeight, AColumnStep, ARowStep: Integer;
      ASolid: Boolean; ALeftOffset, ATopOffset: Integer): TBytes;
    procedure CheckImage(const AImage: TBytes; AWidth, AHeight: Integer);
    function Recolor(const AImage: TBytes; AWidth, AHeight: Integer; const APalette: TBytes;
      ABackground: Integer; const ADefaultPalette: TArray<Cardinal>): TBytes;
  public
    /// <param name="AOptions">What differs between the games</param>
    /// <param name="AMatcher">Matches colors to a palette; EArgumentNilException when nil</param>
    constructor Create(const AOptions: TGamePatchOptions; const AMatcher: IColorMatcher);
    function FromColumns(const AImage: TBytes; AWidth, AHeight: Integer; ASolid: Boolean;
      ALeftOffset, ATopOffset: Integer): TBytes; overload;
    function FromColumns(const AImage: TBytes; AWidth, AHeight: Integer;
      ASolid: Boolean): TBytes; overload;
    function FromRows(const AImage: TBytes; AWidth, AHeight: Integer; ASolid: Boolean): TBytes;
    function FromPalettedRows(const AImage: TBytes; AWidth, AHeight: Integer;
      const APalette: TBytes; ASolid: Boolean; const ADefaultPalette: TArray<Cardinal>): TBytes;
    function FromPalettedRowsWithBackground(const AImage: TBytes; AWidth, AHeight: Integer;
      const APalette: TBytes; ABackground: Integer;
      const ADefaultPalette: TArray<Cardinal>): TBytes;
    function SkyFromColumns(const AImage: TBytes; AWidth, AHeight: Integer): TBytes;
  end;

implementation

{ TGamePatchBuilder }

constructor TGamePatchBuilder.Create(const AOptions: TGamePatchOptions;
  const AMatcher: IColorMatcher);
begin
  inherited Create;
  if not Assigned(AMatcher) then
    raise EArgumentNilException.Create('AMatcher');
  FOptions := AOptions;
  FMatcher := AMatcher;
end;

procedure TGamePatchBuilder.CheckImage(const AImage: TBytes; AWidth, AHeight: Integer);
begin
  if (AWidth < 0) or (AHeight < 0) or (AWidth > High(SmallInt)) or
    (Int64(AWidth) * AHeight > Length(AImage)) then
    raise EGameDataException.CreateFmt(SGameDataBadImage,
      [AWidth, AHeight, Int64(AWidth) * AHeight, Length(AImage)]);
  if AHeight > GAMEDATA_PATCH_MAX_HEIGHT then
    raise EGameDataException.CreateFmt(SGameDataBadHeight,
      [GAMEDATA_PATCH_MAX_HEIGHT, AHeight]);
end;

function TGamePatchBuilder.Build(const AImage: TBytes; AWidth, AHeight, AColumnStep,
  ARowStep: Integer; ASolid: Boolean; ALeftOffset, ATopOffset: Integer): TBytes;
var
  LHeader: TGamePatchHeader;
  LBody: TBytesStream;
  LOffsets: TArray<Integer>;
  LRun: TBytes;
  LRunLength: Integer;
  LColumn: Integer;
  LRow: Integer;
  LPixel: Byte;
  LByte: Byte;
  LTotal: Integer;

  procedure FlushRun(ARowAfterRun: Integer);
  begin
    if LRunLength > 0 then
    begin
      LByte := Byte(ARowAfterRun - LRunLength);
      LBody.WriteBuffer(LByte, 1);
      LByte := Byte(LRunLength);
      LBody.WriteBuffer(LByte, 1);
      LByte := 0;
      LBody.WriteBuffer(LByte, 1);
      LBody.WriteBuffer(LRun[0], LRunLength);
      LBody.WriteBuffer(LByte, 1);
      LRunLength := 0;
    end;
  end;

begin
  CheckImage(AImage, AWidth, AHeight);
  LHeader.Width := AWidth;
  LHeader.Height := AHeight;
  if ALeftOffset = GAMEDATA_PATCH_DEFAULT_OFFSET then
    LHeader.LeftOffset := AWidth div 2
  else
    LHeader.LeftOffset := ALeftOffset;
  if ATopOffset = GAMEDATA_PATCH_DEFAULT_OFFSET then
    LHeader.TopOffset := AHeight
  else
    LHeader.TopOffset := ATopOffset;

  SetLength(LOffsets, AWidth);
  SetLength(LRun, AHeight + 1);
  LBody := TBytesStream.Create;
  try
    for LColumn := 0 to AWidth - 1 do
    begin
      LOffsets[LColumn] := LBody.Size + SizeOf(TGamePatchHeader) + AWidth * SizeOf(Integer);
      LRunLength := 0;
      for LRow := 0 to AHeight - 1 do
      begin
        LPixel := AImage[LColumn * AColumnStep + LRow * ARowStep];
        if (not ASolid) and (LPixel = FOptions.TransparentIndex) then
        begin
          FlushRun(LRow);
          Continue;
        end;
        LRun[LRunLength] := LPixel;
        Inc(LRunLength);
      end;
      FlushRun(AHeight);
      // the end of the column is a post of 255 and 0
      LByte := 255;
      LBody.WriteBuffer(LByte, 1);
      LByte := 0;
      LBody.WriteBuffer(LByte, 1);
    end;

    LTotal := SizeOf(TGamePatchHeader) + AWidth * SizeOf(Integer) + LBody.Size;
    SetLength(Result, LTotal);
    Move(LHeader, Result[0], SizeOf(TGamePatchHeader));
    if AWidth > 0 then
      Move(LOffsets[0], Result[SizeOf(TGamePatchHeader)], AWidth * SizeOf(Integer));
    if LBody.Size > 0 then
      Move(LBody.Bytes[0], Result[SizeOf(TGamePatchHeader) + AWidth * SizeOf(Integer)], LBody.Size);
  finally
    LBody.Free;
  end;
end;

function TGamePatchBuilder.FromColumns(const AImage: TBytes; AWidth, AHeight: Integer;
  ASolid: Boolean; ALeftOffset, ATopOffset: Integer): TBytes;
begin
  Result := Build(AImage, AWidth, AHeight, AHeight, 1, ASolid, ALeftOffset, ATopOffset);
end;

function TGamePatchBuilder.FromColumns(const AImage: TBytes; AWidth, AHeight: Integer;
  ASolid: Boolean): TBytes;
begin
  Result := Build(AImage, AWidth, AHeight, AHeight, 1, ASolid, GAMEDATA_PATCH_DEFAULT_OFFSET,
    GAMEDATA_PATCH_DEFAULT_OFFSET);
end;

function TGamePatchBuilder.FromRows(const AImage: TBytes; AWidth, AHeight: Integer;
  ASolid: Boolean): TBytes;
begin
  Result := Build(AImage, AWidth, AHeight, 1, AWidth, ASolid, 0, 0);
end;

function TGamePatchBuilder.Recolor(const AImage: TBytes; AWidth, AHeight: Integer;
  const APalette: TBytes; ABackground: Integer; const ADefaultPalette: TArray<Cardinal>): TBytes;
var
  LIndex: Integer;
  LPaletteIndex: Integer;
  LRed: Cardinal;
  LGreen: Cardinal;
  LBlue: Cardinal;
  LMatched: Byte;
begin
  CheckImage(AImage, AWidth, AHeight);
  if Length(APalette) < GAMEDATA_PALETTE_SIZE then
    raise EGameDataException.CreateFmt(SGameDataBadPalette, [GAMEDATA_PALETTE_SIZE, Length(APalette)]);
  SetLength(Result, AWidth * AHeight);
  for LIndex := 0 to AWidth * AHeight - 1 do
  begin
    LPaletteIndex := AImage[LIndex];
    if LPaletteIndex = ABackground then
    begin
      Result[LIndex] := FOptions.TransparentIndex;
      Continue;
    end;
    // the palette of the files is VGA: 6 bits per component
    LRed := Cardinal(APalette[3 * LPaletteIndex]) * 4;
    if LRed > 255 then
      LRed := 255;
    LGreen := Cardinal(APalette[3 * LPaletteIndex + 1]) * 4;
    if LGreen > 255 then
      LGreen := 255;
    LBlue := Cardinal(APalette[3 * LPaletteIndex + 2]) * 4;
    if LBlue > 255 then
      LBlue := 255;
    LMatched := Byte(FMatcher.FindApproximateIndex(ADefaultPalette, (LRed shl 16) + (LGreen shl 8) + LBlue,
      FOptions.PaletteLow, FOptions.PaletteHigh));
    if (ABackground >= 0) and (LMatched = FOptions.TransparentIndex) then
      LMatched := Byte(FOptions.TransparentIndex - 2);
    Result[LIndex] := LMatched;
  end;
end;

function TGamePatchBuilder.FromPalettedRows(const AImage: TBytes; AWidth, AHeight: Integer;
  const APalette: TBytes; ASolid: Boolean; const ADefaultPalette: TArray<Cardinal>): TBytes;
begin
  Result := FromRows(Recolor(AImage, AWidth, AHeight, APalette, -1, ADefaultPalette),
    AWidth, AHeight, ASolid);
end;

function TGamePatchBuilder.FromPalettedRowsWithBackground(const AImage: TBytes;
  AWidth, AHeight: Integer; const APalette: TBytes; ABackground: Integer;
  const ADefaultPalette: TArray<Cardinal>): TBytes;
begin
  Result := FromRows(Recolor(AImage, AWidth, AHeight, APalette, ABackground, ADefaultPalette),
    AWidth, AHeight, False);
end;

function TGamePatchBuilder.SkyFromColumns(const AImage: TBytes; AWidth, AHeight: Integer): TBytes;
begin
  Result := Build(AImage, AWidth, AHeight, AHeight, 1, True, GAMEDATA_PATCH_DEFAULT_OFFSET,
    GAMEDATA_PATCH_DEFAULT_OFFSET);
end;

end.
