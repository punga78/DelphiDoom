{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: dithering                             }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.Dither;

interface

uses
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Endoom.TextArt.Intf;

type
  /// <summary>
  ///   ta_dither: the cell is one of the 600 mixes of the DOS font (a background with 8 colors, a
  ///   different foreground with 16, and the blank, the three shades or the full block), whose
  ///   color is the blend of the two by the weight of the character; the average of the four pixels
  ///   goes to the mix with the nearest color, a blank one if two are as near
  /// </summary>
  TEndoomTextArtDither = class(TInterfacedObject, IEndoomTextArtMethod)
  strict private
    type
      TMix = record
        Color: Cardinal;
        Background: Integer;
        Foreground: Integer;
        Code: Byte;
      end;
  strict private
    FMixes: TArray<TMix>;
  public
    constructor Create;
    function GetKind: TEndoomTextArtKind;
    procedure Convert(const ASamples: TEndoomTextArtSamples; var ACell: TEndoomTextArtCell);
  end;

implementation

uses
  System.SysUtils, System.Math,
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.ColorQuantizer;

const
  MIX_CHARACTERS = 5;
  /// <summary>The blank, the three shades and the full block</summary>
  MIX_CODES: array[0..MIX_CHARACTERS - 1] of Byte = (Ord(' '), $B0, $B1, $B2, $DB);
  /// <summary>The share of the background in each of them</summary>
  MIX_WEIGHTS: array[0..MIX_CHARACTERS - 1] of Double = (1.0, 0.75, 0.5, 0.25, 0.0);

{ TEndoomTextArtDither }

constructor TEndoomTextArtDither.Create;
var
  LBackground: Integer;
  LForeground: Integer;
  LCharacter: Integer;
  LCount: Integer;
  LBackgroundColor: Cardinal;
  LForegroundColor: Cardinal;
  LWeight: Double;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;

  function Blend(AShift: Integer): Integer;
  begin
    Result := EnsureRange(Round(Integer((LBackgroundColor shr AShift) and $FF) * LWeight +
      Integer((LForegroundColor shr AShift) and $FF) * (1.0 - LWeight)), 0, 255);
  end;

begin
  inherited Create;
  SetLength(FMixes, ENDOOM_BACKGROUND_COLOR_COUNT * (ENDOOM_COLOR_COUNT - 1) * MIX_CHARACTERS);
  LCount := 0;
  for LBackground := 0 to ENDOOM_BACKGROUND_COLOR_COUNT - 1 do
  begin
    LBackgroundColor := ENDOOM_COLORS[LBackground];
    for LForeground := 0 to ENDOOM_COLOR_COUNT - 1 do
      if LBackground <> LForeground then
      begin
        LForegroundColor := ENDOOM_COLORS[LForeground];
        for LCharacter := 0 to MIX_CHARACTERS - 1 do
        begin
          LWeight := MIX_WEIGHTS[LCharacter];
          LRed := Blend(16);
          LGreen := Blend(8);
          LBlue := Blend(0);
          FMixes[LCount].Color := (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or Cardinal(LBlue);
          FMixes[LCount].Background := LBackground;
          FMixes[LCount].Foreground := LForeground;
          FMixes[LCount].Code := MIX_CODES[LCharacter];
          Inc(LCount);
        end;
      end;
  end;
  SetLength(FMixes, LCount);
end;

function TEndoomTextArtDither.GetKind: TEndoomTextArtKind;
begin
  Result := eakDither;
end;

procedure TEndoomTextArtDither.Convert(const ASamples: TEndoomTextArtSamples;
  var ACell: TEndoomTextArtCell);
var
  LAverage: Cardinal;
  LIndex: Integer;
  LBest: Integer;
  LBestDistance: Integer;
  LDistance: Integer;
begin
  LAverage := ASamples.Average;
  LBest := 0;
  LBestDistance := MaxInt;
  for LIndex := 0 to High(FMixes) do
  begin
    LDistance := TEndoomColorQuantizer.Distance(LAverage, FMixes[LIndex].Color);
    if LDistance < LBestDistance then
    begin
      LBestDistance := LDistance;
      LBest := LIndex;
    end
    else if (LDistance = LBestDistance) and (FMixes[LIndex].Code = Ord(' ')) then
      // a blank mix is preferred when two are as near
      LBest := LIndex;
  end;
  ACell.Background := FMixes[LBest].Background;
  ACell.Foreground := FMixes[LBest].Foreground;
  ACell.Code := FMixes[LBest].Code;
end;

end.
