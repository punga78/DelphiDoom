{******************************************************************************}
{                                                                              }
{  DelphiDoom: radix library - TRadixCockpitPart                               }
{  Copyright (C) 2004-2024 by Jim Valavanis (original DelphiDoom, Rad-X)       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  Port of GenerateCockpitOverlay of radix_xlat_wad.pas                        }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Radix.CockpitPart;

interface

uses
  System.SysUtils,
  DelphiDoom.Radix.Context;

type
  /// <summary>
  ///   COCKPIT: the overlay of the cockpit, 320 x 200. The DAT stores four planes of 50 rows of
  ///   run length codes (0 n skips n pixels, 255 ends a plane) whose pixels are interleaved
  /// </summary>
  TRadixCockpitPart = class(TInterfacedObject, IRadixPart)
  public
    procedure Build(const AContext: TRadixTranslationContext);
  end;

implementation

uses
  DelphiDoom.Radix.Bitmap;

const
  Width = 320;
  Height = 200;
  PlaneRows = 50;

{ TRadixCockpitPart }

procedure TRadixCockpitPart.Build(const AContext: TRadixTranslationContext);
var
  LIndex: Integer;
  LLump: TBytes;
  LBitmap: TRadixBitmap;
  LSizes: array[0..3] of SmallInt;
  LPositions: array[0..3] of SmallInt;
  LPlane: Integer;
  LCount: Integer;
  LPosition: Integer;
  LImagePosition: Integer;
  LValue: Byte;
  LX: Integer;
  LY: Integer;

  function Next: Byte;
  begin
    // past the end of the lump the original read the bytes of the next lump: here they are zero
    if LPosition < Length(LLump) then
      Result := LLump[LPosition]
    else
      Result := 0;
    Inc(LPosition);
  end;

begin
  LIndex := AContext.Container.IndexOf('CockPitOverlay');
  if LIndex < 0 then
    Exit;
  LLump := AContext.Container.Read(LIndex);
  LBitmap := TRadixBitmap.Create;
  try
    LBitmap.Width := Width;
    LBitmap.Height := Height;
    LBitmap.Clear(254);
    LPosition := 0;
    for LPlane := 0 to 3 do
    begin
      LValue := Next;
      LSizes[LPlane] := SmallInt(LValue or (Next shl 8));
    end;
    LPositions[0] := 12;
    for LPlane := 1 to 3 do
      LPositions[LPlane] := LSizes[LPlane - 1] + LPositions[LPlane - 1];
    for LPlane := 0 to 3 do
    begin
      LImagePosition := Width * PlaneRows * LPlane;
      LPosition := LPositions[LPlane];
      for LCount := 0 to LSizes[LPlane] - 1 do
      begin
        LValue := Next;
        if LValue = 255 then
          Break;
        if LValue = 0 then
          Inc(LImagePosition, Next)
        else
        begin
          if LImagePosition < Width * Height then
          begin
            LX := LImagePosition mod Width;
            LY := LImagePosition div Width;
            LBitmap[(LX mod 80) * 4 + LY div PlaneRows, (LY mod PlaneRows) * 4 + LX div 80] := LValue;
          end;
          Inc(LImagePosition);
        end;
      end;
    end;
    AContext.Wad.AddLump('COCKPIT', AContext.Patches.FromColumns(LBitmap.Image, Width, Height, False, 0, 0));
  finally
    LBitmap.Free;
  end;
end;

end.
