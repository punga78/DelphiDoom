{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the nearest color of the text mode              }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.ColorQuantizer;

interface

type
  /// <summary>
  ///   Finds the color of the text mode (ENDOOM_COLORS) that looks most like any color. It is
  ///   the getcoloridx of the old ENDEDIT: an exact color wins, otherwise the smallest squared
  ///   distance in RGB, and the first of the colors that tie. The colors are $00RRGGBB (the old
  ///   tool had them in the order of a Windows TColor: the distance is the same)
  /// </summary>
  TEndoomColorQuantizer = class
  public
    /// <summary>The index of the nearest color among the first ARange of ENDOOM_COLORS</summary>
    class function NearestIndex(AColor: Cardinal; ARange: Integer): Integer; static;
    /// <summary>The nearest of the 16 colors of a foreground</summary>
    class function NearestForeground(AColor: Cardinal): Integer; static;
    /// <summary>The nearest of the 8 colors of a background</summary>
    class function NearestBackground(AColor: Cardinal): Integer; static;
    /// <summary>The squared distance in RGB between two colors</summary>
    class function Distance(AColor1, AColor2: Cardinal): Integer; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Endoom.Types;

{ TEndoomColorQuantizer }

class function TEndoomColorQuantizer.Distance(AColor1, AColor2: Cardinal): Integer;
var
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
begin
  LRed := Integer((AColor1 shr 16) and $FF) - Integer((AColor2 shr 16) and $FF);
  LGreen := Integer((AColor1 shr 8) and $FF) - Integer((AColor2 shr 8) and $FF);
  LBlue := Integer(AColor1 and $FF) - Integer(AColor2 and $FF);
  Result := LRed * LRed + LGreen * LGreen + LBlue * LBlue;
end;

class function TEndoomColorQuantizer.NearestIndex(AColor: Cardinal; ARange: Integer): Integer;
var
  LIndex: Integer;
  LDistance: Integer;
  LBestDistance: Integer;
begin
  if (ARange < 1) or (ARange > ENDOOM_COLOR_COUNT) then
    raise EEndoomException.CreateFmt(SEndoomBadColorIndex, [ARange]);
  AColor := AColor and $FFFFFF;
  Result := 0;
  LBestDistance := MaxInt;
  for LIndex := 0 to ARange - 1 do
  begin
    LDistance := Distance(AColor, ENDOOM_COLORS[LIndex]);
    if LDistance < LBestDistance then
    begin
      LBestDistance := LDistance;
      Result := LIndex;
    end;
  end;
end;

class function TEndoomColorQuantizer.NearestForeground(AColor: Cardinal): Integer;
begin
  Result := NearestIndex(AColor, ENDOOM_COLOR_COUNT);
end;

class function TEndoomColorQuantizer.NearestBackground(AColor: Cardinal): Integer;
begin
  Result := NearestIndex(AColor, ENDOOM_BACKGROUND_COLOR_COUNT);
end;

end.
