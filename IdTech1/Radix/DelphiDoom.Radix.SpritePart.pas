{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixSpritePart                                }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateSprites of radix_xlat_wad.pas (GenerateExtraSprites is      }
{  never called by the old translator, so it is not ported)                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.SpritePart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Context, DelphiDoom.Radix.SpriteList;

type
  /// <summary>Fills the list of the sprites that the part makes</summary>
  TRadixSpriteFill = reference to procedure(const AList: TRadixSpriteList);

  /// <summary>
  ///   The sprites of the objects: S_START, the patches made from the bitmaps of ObjectBitmaps
  ///   (a bitmap that is not there is the empty sprite TNT1A0), S_END
  /// </summary>
  TRadixSpritePart = class(TInterfacedObject, IRadixPart)
  strict private
    FFill: TRadixSpriteFill;
    function ReadTable(const AContext: TRadixTranslationContext;
      out ATable: TArray<TRadixBitmapRecord>): Boolean;
    /// <summary>The names of the bitmaps; the original has some that are the same (the copies are renamed)</summary>
    procedure FixDuplicateNames(var ATable: TArray<TRadixBitmapRecord>;
      var ANames: TArray<string>);
    procedure FixSplashes(var ATable: TArray<TRadixBitmapRecord>; var ANames: TArray<string>;
      const APrefix: string; ACharacter: Integer);
    procedure Rename(var ATable: TArray<TRadixBitmapRecord>; var ANames: TArray<string>;
      AIndex, ACharacter: Integer; AValue: AnsiChar);
    function FindBitmap(const ANames: TArray<string>; const AName: string): Integer;
    /// <summary>The columns of the bitmap, stored by columns, 254 where there is no pixel</summary>
    function ReadBitmap(const AContext: TRadixTranslationContext;
      const ARecord: TRadixBitmapRecord): TBytes;
  public
    constructor Create(const AFill: TRadixSpriteFill);
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.Container, DelphiDoom.Radix.Bitmap, DelphiDoom.Radix.SpriteData,
  DelphiDoom.Radix.Things;

const
  ObjectBitmapsLump = 'ObjectBitmaps';
  Hole = 254;
  ColumnRecordSize = 4;

function ToBytes(const AData: array of Byte): TBytes;
begin
  SetLength(Result, Length(AData));
  Move(AData[0], Result[0], Length(AData));
end;

{ TRadixSpritePart }

constructor TRadixSpritePart.Create(const AFill: TRadixSpriteFill);
begin
  inherited Create;
  if not Assigned(AFill) then
    raise EArgumentNilException.Create('AFill');
  FFill := AFill;
end;

function TRadixSpritePart.ReadTable(const AContext: TRadixTranslationContext;
  out ATable: TArray<TRadixBitmapRecord>): Boolean;
var
  LIndex: Integer;
  LHead: TBytes;
  LCount: Integer;
  LStart: Integer;
  LBytes: TBytes;
begin
  LIndex := AContext.Container.IndexOf(ObjectBitmapsLump);
  Result := LIndex >= 0;
  if not Result then
    Exit;
  LHead := AContext.Container.ReadAt(AContext.Container.Infos[LIndex].Position, 6);
  LCount := LHead[0] or (LHead[1] shl 8);
  LStart := Integer(LHead[2]) or (Integer(LHead[3]) shl 8) or (Integer(LHead[4]) shl 16) or
    (Integer(LHead[5]) shl 24);
  LBytes := AContext.Container.ReadAt(LStart, LCount * SizeOf(TRadixBitmapRecord));
  SetLength(ATable, LCount);
  if LCount > 0 then
    Move(LBytes[0], ATable[0], LCount * SizeOf(TRadixBitmapRecord));
end;

procedure TRadixSpritePart.Rename(var ATable: TArray<TRadixBitmapRecord>;
  var ANames: TArray<string>; AIndex, ACharacter: Integer; AValue: AnsiChar);
begin
  ATable[AIndex].Name[ACharacter] := AValue;
  ANames[AIndex] := TRadixContainer.ReadName(ATable[AIndex].Name);
end;

procedure TRadixSpritePart.FixDuplicateNames(var ATable: TArray<TRadixBitmapRecord>;
  var ANames: TArray<string>);
begin
  // JVAL: 20200426 - the original ObjectBitmaps has three bitmaps with the same name
  if Length(ATable) > 2 then
    if (ANames[0] = 'SecondCoolant1') and (ANames[1] = 'SecondCoolant1') and
      (ANames[2] = 'SecondCoolant1') then
    begin
      Rename(ATable, ANames, 1, 13, '2');
      Rename(ATable, ANames, 2, 13, '3');
    end;
  if Length(ATable) > 8 then
    if (ANames[6] = 'CoolantGener1') and (ANames[7] = 'CoolantGener1') and
      (ANames[8] = 'CoolantGener1') then
    begin
      Rename(ATable, ANames, 7, 12, '2');
      Rename(ATable, ANames, 8, 12, '3');
    end;
end;

procedure TRadixSpritePart.FixSplashes(var ATable: TArray<TRadixBitmapRecord>;
  var ANames: TArray<string>; const APrefix: string; ACharacter: Integer);
var
  LNumber: Integer;
  LIndex: Integer;
  LFound: TArray<Integer>;
begin
  // JVAL: 20200501 - a splash that is twice: the first is the number 7, 8 or 9
  for LNumber := 1 to 3 do
  begin
    LFound := nil;
    for LIndex := 0 to High(ANames) do
      if ANames[LIndex] = APrefix + IntToStr(LNumber) then
        LFound := LFound + [LIndex];
    if Length(LFound) = 2 then
      Rename(ATable, ANames, LFound[0], ACharacter, AnsiChar(Chr(Ord('6') + LNumber)));
  end;
end;

function TRadixSpritePart.FindBitmap(const ANames: TArray<string>; const AName: string): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(ANames) do
    if ANames[LIndex] = AName then
      Exit(LIndex);
  Result := -1;
end;

function TRadixSpritePart.ReadBitmap(const AContext: TRadixTranslationContext;
  const ARecord: TRadixBitmapRecord): TBytes;
var
  LLast: TBytes;
  LOffset: Integer;
  LStart: Integer;
  LSize: Integer;
  LData: TBytes;
  LBitmap: TRadixBitmap;
  LColumn: Integer;
  LY: Integer;
  LIndex: Integer;
begin
  // the record of the last column says where the pixels end
  LLast := AContext.Container.ReadAt(ARecord.Position + (ARecord.Width - 1) * ColumnRecordSize,
    ColumnRecordSize);
  LData := AContext.Container.ReadAt(ARecord.Position,
    (LLast[0] or (LLast[1] shl 8)) + LLast[3]);
  LBitmap := TRadixBitmap.Create;
  try
    LBitmap.Width := ARecord.Width;
    LBitmap.Height := ARecord.Height;
    LBitmap.Clear(Hole);
    for LColumn := 0 to ARecord.Width - 1 do
    begin
      if (LColumn + 1) * ColumnRecordSize > Length(LData) then
        Break;
      LOffset := LData[LColumn * ColumnRecordSize] or (LData[LColumn * ColumnRecordSize + 1] shl 8);
      LStart := LData[LColumn * ColumnRecordSize + 2];
      LSize := LData[LColumn * ColumnRecordSize + 3];
      for LY := LStart to LStart + LSize - 1 do
      begin
        LIndex := LOffset - LStart + LY;
        // the old code read what was after the buffer; here it is a hole
        if (LIndex < 0) or (LIndex >= Length(LData)) then
          Continue;
        if LData[LIndex] < 255 then
          LBitmap[LColumn, LY] := LData[LIndex];
      end;
    end;
    Result := Copy(LBitmap.Image);
  finally
    LBitmap.Free;
  end;
end;

procedure TRadixSpritePart.Build(const AContext: TRadixTranslationContext);
var
  LTable: TArray<TRadixBitmapRecord>;
  LNames: TArray<string>;
  LList: TRadixSpriteList;
  LInfo: TRadixSpriteInfo;
  LBitmapIndex: Integer;
  LIndex: Integer;
  LBitmap: TRadixBitmap;
  LPixels: TBytes;
  LWidth: Integer;
  LHeight: Integer;
  LX: Integer;
  LName: string;
  LPatch: TBytes;
begin
  if not ReadTable(AContext, LTable) then
    Exit;
  SetLength(LNames, Length(LTable));
  for LIndex := 0 to High(LTable) do
    LNames[LIndex] := TRadixContainer.ReadName(LTable[LIndex].Name);
  FixDuplicateNames(LTable, LNames);
  FixSplashes(LTable, LNames, 'WaterSplash', 11);
  FixSplashes(LTable, LNames, 'MudSplash', 9);
  FixSplashes(LTable, LNames, 'LavaSplash', 10);

  AContext.Wad.AddMarker('S_START');
  AContext.Wad.AddLump('GEAR1A0', ToBytes(RADIX_PATCH_GEAR1A0));

  LList := TRadixSpriteList.Create;
  LBitmap := TRadixBitmap.Create;
  try
    FFill(LList);
    for LIndex := 0 to LList.Count - 1 do
    begin
      LInfo := LList[LIndex];
      // the sprite of the player rotated by 90 degrees is made by hand in the WAD of the game
      if LInfo.LumpName = 'XR63A7' then
        Continue;
      LBitmapIndex := FindBitmap(LNames, LInfo.BitmapName);
      if LBitmapIndex < 0 then
      begin
        LInfo.BitmapName := StringReplace(LInfo.BitmapName, '_', '', [rfReplaceAll]);
        LBitmapIndex := FindBitmap(LNames, LInfo.BitmapName);
      end;
      if (LBitmapIndex < 0) or (LTable[LBitmapIndex].Width <= 0) or
        (LTable[LBitmapIndex].Height <= 0) then
      begin
        AContext.Wad.AddLump(LInfo.LumpName, ToBytes(RADIX_PATCH_TNT1A0));
        Continue;
      end;

      LPixels := ReadBitmap(AContext, LTable[LBitmapIndex]);
      LBitmap.AttachImage(LPixels, LTable[LBitmapIndex].Width, LTable[LBitmapIndex].Height);
      // the changes of the size stay in the table, as the old code made them on the record
      if LInfo.LumpName = 'XR30K0' then
      begin
        LBitmap.Crop(63, 62);
        LTable[LBitmapIndex].Width := 63;
        LTable[LBitmapIndex].Height := 62;
      end
      else if (LInfo.LumpName = 'XR38B1') or (LInfo.LumpName = 'XR38B2') or
        (LInfo.LumpName = 'XR38B8') then
      begin
        for LX := 0 to LBitmap.Width - 1 do
          if LBitmap[LX, 0] = 0 then
            LBitmap[LX, 0] := Hole;
      end
      else if (LInfo.LumpName = 'XR38A5') or (LInfo.LumpName = 'XR38A6') or
        (LInfo.LumpName = 'XR38C4') or (LInfo.LumpName = 'XR38C5') then
      begin
        for LX := 0 to LBitmap.Width - 1 do
          if LBitmap[LX, LBitmap.Height - 1] = 0 then
            LBitmap[LX, LBitmap.Height - 1] := Hole;
      end
      else if LInfo.LumpName = 'XR63A3' then
      begin
        LInfo.LumpName := 'XR63A3A7';
        LInfo.OffsetY := 77;
      end
      else if (LInfo.LumpName = 'XR64A4') or (LInfo.LumpName = 'XR64A6') then
      begin
        LTable[LBitmapIndex].Height := 96;
        LBitmap.Crop(LBitmap.Width, 96);
      end;

      LWidth := LTable[LBitmapIndex].Width;
      LHeight := LTable[LBitmapIndex].Height;
      if LInfo.DefaultOffsets then
        LPatch := AContext.Patches.FromColumns(LBitmap.Image, LWidth, LHeight, False)
      else if LInfo.CenterOffsets then
        LPatch := AContext.Patches.FromColumns(LBitmap.Image, LWidth, LHeight, False,
          LWidth div 2, LHeight div 2)
      else
        LPatch := AContext.Patches.FromColumns(LBitmap.Image, LWidth, LHeight, False,
          LInfo.OffsetX, LInfo.OffsetY);
      LName := LInfo.LumpName;
      AContext.Wad.AddLump(LName, LPatch);
      AContext.AddAlias(LName, LInfo.BitmapName);
    end;
  finally
    LBitmap.Free;
    LList.Free;
  end;
  AContext.AddAlias('XR' + IntToStr(MTRX_EGG) + 'A0', 'EG1');
  AContext.Wad.AddMarker('S_END');
end;

end.
