{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the picture of an editable screen               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.ScreenImage;

interface

uses
  System.SysUtils,
  DelphiDoom.Endoom.Types,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The GetBitmap of the old TEndScreen: the renderer of the library draws the cells with the
  ///   indices 0..15 and the 16 colors of ENDOOM_COLORS become the pixels $FFRRGGBB
  /// </summary>
  TEndoomScreenImage = class(TInterfacedObject, IEndoomScreenImage)
  strict private
    FRenderer: IEndoomRenderer;
    FColorIndices: array[0..ENDOOM_COLOR_COUNT - 1] of Byte;
    FPalette: array[0..ENDOOM_PALETTE_SIZE - 1] of Cardinal;
    FIndexed: TBytes;
  public
    constructor Create(const ARenderer: IEndoomRenderer);
    procedure Render(const AScreen: IEndoomScreen; const AFont: TBytes; ABlinkVisible: Boolean;
      var APixels: TArray<Cardinal>);
  end;

implementation

{ TEndoomScreenImage }

constructor TEndoomScreenImage.Create(const ARenderer: IEndoomRenderer);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(ARenderer) then
    raise EArgumentNilException.Create('ARenderer');
  FRenderer := ARenderer;
  FillChar(FPalette, SizeOf(FPalette), 0);
  for LIndex := 0 to ENDOOM_COLOR_COUNT - 1 do
  begin
    FColorIndices[LIndex] := LIndex;
    FPalette[LIndex] := ENDOOM_COLORS[LIndex];
  end;
end;

procedure TEndoomScreenImage.Render(const AScreen: IEndoomScreen; const AFont: TBytes;
  ABlinkVisible: Boolean; var APixels: TArray<Cardinal>);
begin
  if not Assigned(AScreen) then
    raise EArgumentNilException.Create('AScreen');
  FRenderer.RenderIndexed(AScreen.ToBytes, AFont, FColorIndices, ABlinkVisible, FIndexed);
  FRenderer.ConvertToRgb32(FIndexed, FPalette, ENDOOM_WIDTH, APixels);
end;

end.
