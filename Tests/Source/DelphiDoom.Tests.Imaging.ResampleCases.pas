{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the imaging library - the images to resample            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Imaging.ResampleCases;

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

uses
  System.SysUtils, System.Math;

type
  /// <summary>
  ///   Pictures made by a fixed generator: the harness that ran the old Lanczos of ENDEDIT (Graphics32) and the
  ///   tests use this same unit, so the inputs are the same. The pixels are $00RRGGBB, as a bitmap of the
  ///   clipboard has them
  /// </summary>
  TResampleCases = class
  public
    class function Count: Integer; static;
    class function Name(AIndex: Integer): string; static;
    /// <summary>The picture of a case; its width and height come out</summary>
    class function Build(AIndex: Integer; out AWidth, AHeight: Integer): TArray<Cardinal>; static;
  end;

implementation

type
  TCaseKind = (ckGradient, ckNoise, ckChecker, ckPlasma, ckShapes, ckSolid);

  TCaseSpec = record
    Name: string;
    Kind: TCaseKind;
    Width: Integer;
    Height: Integer;
  end;

const
  CASES: array[0..17] of TCaseSpec = (
    (Name: 'gradient-640x400'; Kind: ckGradient; Width: 640; Height: 400),
    (Name: 'noise-640x400'; Kind: ckNoise; Width: 640; Height: 400),
    (Name: 'checker-640x400'; Kind: ckChecker; Width: 640; Height: 400),
    (Name: 'plasma-640x400'; Kind: ckPlasma; Width: 640; Height: 400),
    (Name: 'shapes-640x480'; Kind: ckShapes; Width: 640; Height: 480),
    (Name: 'noise-320x200'; Kind: ckNoise; Width: 320; Height: 200),
    (Name: 'gradient-160x50'; Kind: ckGradient; Width: 160; Height: 50),
    (Name: 'noise-160x50'; Kind: ckNoise; Width: 160; Height: 50),
    (Name: 'noise-100x100'; Kind: ckNoise; Width: 100; Height: 100),
    (Name: 'noise-80x25'; Kind: ckNoise; Width: 80; Height: 25),
    (Name: 'solid-1x1'; Kind: ckSolid; Width: 1; Height: 1),
    (Name: 'noise-7x3'; Kind: ckNoise; Width: 7; Height: 3),
    (Name: 'noise-161x51'; Kind: ckNoise; Width: 161; Height: 51),
    (Name: 'plasma-1000x600'; Kind: ckPlasma; Width: 1000; Height: 600),
    (Name: 'noise-3x300'; Kind: ckNoise; Width: 3; Height: 300),
    (Name: 'shapes-1280x720'; Kind: ckShapes; Width: 1280; Height: 720),
    (Name: 'checker-160x50'; Kind: ckChecker; Width: 160; Height: 50),
    (Name: 'plasma-161x49'; Kind: ckPlasma; Width: 161; Height: 49));

{ TResampleCases }

class function TResampleCases.Count: Integer;
begin
  Result := Length(CASES);
end;

class function TResampleCases.Name(AIndex: Integer): string;
begin
  Result := CASES[AIndex].Name;
end;

class function TResampleCases.Build(AIndex: Integer; out AWidth, AHeight: Integer): TArray<Cardinal>;
var
  LSpec: TCaseSpec;
  LX: Integer;
  LY: Integer;
  LState: Cardinal;
  LRed: Integer;
  LGreen: Integer;
  LBlue: Integer;
  LShape: Integer;
  LCenterX: Integer;
  LCenterY: Integer;
  LRadius: Integer;
  LColor: Cardinal;
  LDistanceX: Integer;
  LDistanceY: Integer;
begin
  LSpec := CASES[AIndex];
  AWidth := LSpec.Width;
  AHeight := LSpec.Height;
  SetLength(Result, AWidth * AHeight);
  LState := 12345 + Cardinal(AIndex) * 977;
  case LSpec.Kind of
    ckGradient:
      for LY := 0 to AHeight - 1 do
        for LX := 0 to AWidth - 1 do
          Result[LY * AWidth + LX] := (Cardinal(LX * 255 div Max(1, AWidth - 1)) shl 16) or
            (Cardinal(LY * 255 div Max(1, AHeight - 1)) shl 8) or Cardinal((LX + LY) and $FF);
    ckNoise:
      for LY := 0 to AHeight - 1 do
        for LX := 0 to AWidth - 1 do
        begin
          LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
          Result[LY * AWidth + LX] := (LState shr 7) and $FFFFFF;
        end;
    ckChecker:
      for LY := 0 to AHeight - 1 do
        for LX := 0 to AWidth - 1 do
          if Odd(LX div 8 + LY div 8) then
            Result[LY * AWidth + LX] := $FFFFFF
          else
            Result[LY * AWidth + LX] := ((Cardinal(LX * 3) and $FF) shl 16) or (Cardinal(LY * 5) and $FF);
    ckPlasma:
      for LY := 0 to AHeight - 1 do
        for LX := 0 to AWidth - 1 do
        begin
          LRed := Round(127.5 + 127.5 * Sin(LX / 23.0 + LY / 41.0));
          LGreen := Round(127.5 + 127.5 * Sin(LX / 37.0 - LY / 19.0 + 1.0));
          LBlue := Round(127.5 + 127.5 * Sin((LX + LY) / 53.0 + 2.0));
          Result[LY * AWidth + LX] := (Cardinal(LRed) shl 16) or (Cardinal(LGreen) shl 8) or Cardinal(LBlue);
        end;
    ckShapes:
      begin
        for LX := 0 to High(Result) do
          Result[LX] := 0;
        for LShape := 0 to 11 do
        begin
          LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
          LCenterX := Integer((LState shr 8) mod Cardinal(AWidth));
          LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
          LCenterY := Integer((LState shr 8) mod Cardinal(AHeight));
          LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
          LRadius := 10 + Integer((LState shr 8) mod 90);
          LState := (LState * 1103515245 + 12345) and $7FFFFFFF;
          LColor := (LState shr 5) and $FFFFFF;
          for LY := Max(0, LCenterY - LRadius) to Min(AHeight - 1, LCenterY + LRadius) do
            for LX := Max(0, LCenterX - LRadius) to Min(AWidth - 1, LCenterX + LRadius) do
            begin
              LDistanceX := LX - LCenterX;
              LDistanceY := LY - LCenterY;
              if LDistanceX * LDistanceX + LDistanceY * LDistanceY <= LRadius * LRadius then
                Result[LY * AWidth + LX] := LColor;
            end;
        end;
      end;
    ckSolid:
      Result[0] := $336699;
  end;
end;

end.
