{******************************************************************************}
{                                                                              }
{  DelphiDoom: font library - draws a text as a row of characters               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original DD_FONT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Font.TextComposer;

interface

uses
  System.SysUtils,
  DelphiDoom.Font.Types,
  DelphiDoom.Font.Settings,
  DelphiDoom.Font.Intf;

type
  /// <summary>
  ///   DrawStringToBitmap of TFontEngine without GDI: asks the rasterizer for each character, cuts it on the
  ///   right (TFontGlyphCropper) unless the pitch is fixed, and puts the characters one after the other. What
  ///   does not fit in AMaxWidth is cut
  /// </summary>
  TFontTextComposer = class(TInterfacedObject, IFontTextComposer)
  strict private
    FRasterizer: IFontRasterizer;
  public
    constructor Create(const ARasterizer: IFontRasterizer);
    function Compose(const ASettings: TFontSettings; const AText: string; AFixedPitch: Boolean;
      AMaxWidth: Integer): TFontImage;
  end;

implementation

uses
  System.Math,
  DelphiDoom.Font.GlyphCropper;

{ TFontTextComposer }

constructor TFontTextComposer.Create(const ARasterizer: IFontRasterizer);
begin
  inherited Create;
  if not Assigned(ARasterizer) then
    raise EArgumentNilException.Create('ARasterizer');
  FRasterizer := ARasterizer;
end;

function TFontTextComposer.Compose(const ASettings: TFontSettings; const AText: string; AFixedPitch: Boolean;
  AMaxWidth: Integer): TFontImage;
var
  LLetters: TArray<TFontImage>;
  LWidths: TArray<Integer>;
  LBackground: Cardinal;
  LHeight: Integer;
  LIndex: Integer;
  LTotal: Integer;
  LX: Integer;
  LRow: Integer;
  LCopy: Integer;
begin
  if AMaxWidth < 0 then
    raise EArgumentOutOfRangeException.Create('AMaxWidth');
  LHeight := Max(0, ASettings.DrawHeight);
  LBackground := TFontSettings.ToRgb(ASettings.BackColor);
  SetLength(LLetters, Length(AText));
  SetLength(LWidths, Length(AText));
  LTotal := 0;
  for LIndex := 0 to Length(AText) - 1 do
  begin
    LLetters[LIndex] := FRasterizer.RenderCharacter(ASettings, AText[LIndex + 1]);
    if (not LLetters[LIndex].IsValid) or (LLetters[LIndex].Height <> LHeight) then
      raise EFontException.CreateFmt(SFontBadRasterizer, [LLetters[LIndex].Width, LLetters[LIndex].Height,
        ASettings.DrawWidth, ASettings.DrawHeight]);
    if AFixedPitch then
      LWidths[LIndex] := LLetters[LIndex].Width
    else
      LWidths[LIndex] := TFontGlyphCropper.CroppedWidth(LLetters[LIndex], LBackground, ASettings.FontSize);
    Inc(LTotal, LWidths[LIndex]);
  end;

  Result := TFontImage.Create(Min(LTotal, AMaxWidth), LHeight);
  LX := 0;
  for LIndex := 0 to Length(AText) - 1 do
  begin
    LCopy := Min(LWidths[LIndex], Result.Width - LX);
    if LCopy <= 0 then
      Break;
    for LRow := 0 to LHeight - 1 do
      Move(LLetters[LIndex].Pixels[LRow * LLetters[LIndex].Width], Result.Pixels[LRow * Result.Width + LX],
        LCopy * SizeOf(Cardinal));
    Inc(LX, LCopy);
  end;
end;

end.
