{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the picture of the canvas as colors of a display  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.FrameConverter;

interface

type
  /// <summary>
  ///   The canvas of the game is RGBA, one byte per channel (R first); the display of Framework\GameHost wants one
  ///   $FFRRGGBB value per pixel (blue in the low byte). The picture of the game is always opaque
  /// </summary>
  TWarFrameConverter = class
  public
    /// <summary>
    ///   Converts APixelCount pixels of ASource (4 bytes each) into ATarget, which is resized if it is not that long.
    ///   EArgumentException if ASource is too short
    /// </summary>
    class procedure ToTrueColor(const ASource: TArray<Byte>; APixelCount: Integer; var ATarget: TArray<Cardinal>);
      static;
    /// <summary>The same picture as blue, green, red, alpha bytes (what the PNG encoder wants); alpha is made opaque</summary>
    class function ToBgra(const ASource: TArray<Byte>; APixelCount: Integer): TArray<Byte>; static;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SWarFrameTooShort = 'The picture has %d bytes and %d pixels need %d';

{ TWarFrameConverter }

class procedure TWarFrameConverter.ToTrueColor(const ASource: TArray<Byte>; APixelCount: Integer;
  var ATarget: TArray<Cardinal>);
var
  LIndex: Integer;
  LOffset: Integer;
begin
  if Length(ASource) < APixelCount * 4 then
    raise EArgumentException.CreateFmt(SWarFrameTooShort, [Length(ASource), APixelCount, APixelCount * 4]);
  if Length(ATarget) <> APixelCount then
    SetLength(ATarget, APixelCount);
  LOffset := 0;
  for LIndex := 0 to APixelCount - 1 do
  begin
    ATarget[LIndex] := $FF000000 or (Cardinal(ASource[LOffset]) shl 16) or (Cardinal(ASource[LOffset + 1]) shl 8) or
      Cardinal(ASource[LOffset + 2]);
    Inc(LOffset, 4);
  end;
end;

class function TWarFrameConverter.ToBgra(const ASource: TArray<Byte>; APixelCount: Integer): TArray<Byte>;
var
  LIndex: Integer;
  LOffset: Integer;
begin
  if Length(ASource) < APixelCount * 4 then
    raise EArgumentException.CreateFmt(SWarFrameTooShort, [Length(ASource), APixelCount, APixelCount * 4]);
  SetLength(Result, APixelCount * 4);
  LOffset := 0;
  for LIndex := 0 to APixelCount - 1 do
  begin
    Result[LOffset] := ASource[LOffset + 2];
    Result[LOffset + 1] := ASource[LOffset + 1];
    Result[LOffset + 2] := ASource[LOffset];
    Result[LOffset + 3] := $FF;
    Inc(LOffset, 4);
  end;
end;

end.
