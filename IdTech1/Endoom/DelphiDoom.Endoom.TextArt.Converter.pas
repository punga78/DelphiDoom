{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: the converter                         }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.Converter;

interface

uses
  System.SysUtils,
  DelphiDoom.Endoom.Intf,
  DelphiDoom.Endoom.TextArt.Intf,
  DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   BitmapToScreen of the old ee_textart without the bitmaps: the picture is resampled to 160x50
  ///   pixels (Lanczos in ENDEDIT; the resampler is given to the constructor) and each cell of the
  ///   screen takes the four pixels at its place
  /// </summary>
  TEndoomTextArtConverter = class(TInterfacedObject, IEndoomTextArtConverter)
  strict private
    FResampler: IImagingResampler;
  public
    constructor Create(const AResampler: IImagingResampler);
    procedure Convert(const AScreen: IEndoomScreen; const APixels: TArray<Cardinal>; AWidth, AHeight: Integer;
      const AMethod: IEndoomTextArtMethod);
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.TextArt.Types;

const
  /// <summary>Pixels of the shrunk picture for a cell, in each direction</summary>
  PIXELS_PER_CELL = 2;

{ TEndoomTextArtConverter }

constructor TEndoomTextArtConverter.Create(const AResampler: IImagingResampler);
begin
  inherited Create;
  if not Assigned(AResampler) then
    raise EArgumentNilException.Create('AResampler');
  FResampler := AResampler;
end;

procedure TEndoomTextArtConverter.Convert(const AScreen: IEndoomScreen; const APixels: TArray<Cardinal>;
  AWidth, AHeight: Integer; const AMethod: IEndoomTextArtMethod);
var
  LPixels: TArray<Cardinal>;
  LStride: Integer;
  LColumn: Integer;
  LRow: Integer;
  LOffset: Integer;
  LSamples: TEndoomTextArtSamples;
  LCell: TEndoomTextArtCell;
begin
  if not Assigned(AScreen) then
    raise EArgumentNilException.Create('AScreen');
  if not Assigned(AMethod) then
    raise EArgumentNilException.Create('AMethod');
  LStride := ENDOOM_COLUMNS * PIXELS_PER_CELL;
  LPixels := FResampler.Resample(APixels, AWidth, AHeight, LStride, ENDOOM_ROWS * PIXELS_PER_CELL);
  for LColumn := 0 to ENDOOM_COLUMNS - 1 do
    for LRow := 0 to ENDOOM_ROWS - 1 do
    begin
      LOffset := LRow * PIXELS_PER_CELL * LStride + LColumn * PIXELS_PER_CELL;
      LSamples.TopLeft := LPixels[LOffset] and $FFFFFF;
      LSamples.TopRight := LPixels[LOffset + 1] and $FFFFFF;
      LSamples.BottomLeft := LPixels[LOffset + LStride] and $FFFFFF;
      LSamples.BottomRight := LPixels[LOffset + LStride + 1] and $FFFFFF;
      LCell.Background := AScreen.GetBackground(LColumn, LRow);
      LCell.Foreground := AScreen.GetForeground(LColumn, LRow);
      LCell.Code := AScreen.GetCharacter(LColumn, LRow);
      AMethod.Convert(LSamples, LCell);
      AScreen.SetBackground(LColumn, LRow, LCell.Background);
      AScreen.SetForeground(LColumn, LRow, LCell.Foreground);
      AScreen.SetCharacter(LColumn, LRow, LCell.Code);
    end;
end;

end.
