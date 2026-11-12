{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - the fades of the palette, a step for each call   }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): VI_FillPalette, VI_FadeOut  }
{  and VI_FadeIn of d_video.pas and the approx_zero of I_SetPalette             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.PaletteFader;

// the bytes of the palette and the counters of VI_FadeIn (shortint in the original) wrap around on purpose
{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types;

const
  /// <summary>256 colors of 3 bytes (red, green, blue), in the units the caller uses</summary>
  GREED_FADE_PALETTE_BYTES = 768;

type
  TGreedFadeKind = (gfkNone, gfkOut, gfkIn);

  /// <summary>
  ///   VI_FadeOut and VI_FadeIn without the wait and without the screen: Start* takes the palette that is shown
  ///   (I_GetPalette), each Step gives the palette that the original sets after one Wait(1), and the last Step
  ///   gives the palette of the end (the flat color of VI_FillPalette or the target of the fade in). The caller
  ///   shows Current after each step and waits a tic. The arithmetic is the one of the original: the bytes wrap,
  ///   and the fade in keeps its steps and remainders in 8 bits with sign.
  ///   VI_ColorBorder (the overscan color of the VGA, for hurtborder) is not in xGreed: nothing is ported
  /// </summary>
  TGreedPaletteFader = class
  strict private
    FKind: TGreedFadeKind;
    FBase: array[0..GREED_FADE_PALETTE_BYTES - 1] of Byte;
    FWork: array[0..GREED_FADE_PALETTE_BYTES - 1] of Byte;
    FTarget: array[0..GREED_FADE_PALETTE_BYTES - 1] of Byte;
    FStep: array[0..GREED_FADE_PALETTE_BYTES - 1] of SmallInt;
    FRemainder: array[0..GREED_FADE_PALETTE_BYTES - 1] of SmallInt;
    FError: array[0..GREED_FADE_PALETTE_BYTES - 1] of SmallInt;
    FFirst: Integer;
    FLast: Integer;
    FSteps: Integer;
    FDone: Integer;
    FCurrent: TBytes;
    procedure Publish(const ASource: array of Byte);
    class procedure CheckPalette(const APalette: TBytes); static;
  public
    constructor Create;
    /// <summary>VI_FillPalette: every color is (red, green, blue)</summary>
    class function FillPalette(ARed, AGreen, ABlue: Integer): TBytes; static;
    /// <summary>
    ///   approx_zero of I_SetPalette: the color from 1 to 255 that is nearest to the color 0 of the palette (the
    ///   first of the nearest ones; the search stops at a color equal to the color 0)
    /// </summary>
    class function ApproximateZero(const APalette: TBytes): Byte; static;
    /// <summary>
    ///   VI_FadeOut(start, stop, red, green, blue, steps) from the palette that is shown: the colors from AStart to
    ///   AStop - 1 go to (red, green, blue) in ASteps steps; then one more step makes every color that one
    /// </summary>
    procedure StartFadeOut(const AShown: TBytes; AStart, AStop, ARed, AGreen, ABlue, ASteps: Integer);
    /// <summary>
    ///   VI_FadeIn(start, stop, palette, steps) from the palette that is shown: the work palette starts black (the
    ///   original adds the difference between the two palettes to zero, not to the palette shown) and the last
    ///   step is the target itself
    /// </summary>
    procedure StartFadeIn(const AShown, ATarget: TBytes; AStart, AStop, ASteps: Integer);
    /// <summary>One step; False when the fade was already over (Current does not change)</summary>
    function Step: Boolean;
    /// <summary>True while Step has something to do</summary>
    function Active: Boolean;
    /// <summary>The palette to show now (768 bytes)</summary>
    property Current: TBytes read FCurrent;
  end;

implementation

{ TGreedPaletteFader }

constructor TGreedPaletteFader.Create;
begin
  inherited Create;
  SetLength(FCurrent, GREED_FADE_PALETTE_BYTES);
  FillChar(FCurrent[0], GREED_FADE_PALETTE_BYTES, 0);
end;

class procedure TGreedPaletteFader.CheckPalette(const APalette: TBytes);
begin
  if Length(APalette) < GREED_FADE_PALETTE_BYTES then
    raise EGreedDataException.CreateFmt(SGreedPaletteTooShort, [Length(APalette), GREED_FADE_PALETTE_BYTES]);
end;

class function TGreedPaletteFader.FillPalette(ARed, AGreen, ABlue: Integer): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, GREED_FADE_PALETTE_BYTES);
  for LIndex := 0 to 255 do
  begin
    Result[LIndex * 3] := Byte(ARed and $FF);
    Result[LIndex * 3 + 1] := Byte(AGreen and $FF);
    Result[LIndex * 3 + 2] := Byte(ABlue and $FF);
  end;
end;

class function TGreedPaletteFader.ApproximateZero(const APalette: TBytes): Byte;
var
  LIndex: Integer;
  LRed, LGreen, LBlue: Integer;
  LDistance: Integer;
  LBest: Integer;
begin
  CheckPalette(APalette);
  Result := 0;
  LBest := MaxInt;
  for LIndex := 1 to 255 do
  begin
    LRed := APalette[0] - APalette[LIndex * 3];
    LGreen := APalette[1] - APalette[LIndex * 3 + 1];
    LBlue := APalette[2] - APalette[LIndex * 3 + 2];
    LDistance := LRed * LRed + LGreen * LGreen + LBlue * LBlue;
    if LDistance < LBest then
    begin
      Result := LIndex;
      LBest := LDistance;
      if LDistance = 0 then
        Break;
    end;
  end;
end;

procedure TGreedPaletteFader.Publish(const ASource: array of Byte);
begin
  Move(ASource[0], FCurrent[0], GREED_FADE_PALETTE_BYTES);
end;

procedure TGreedPaletteFader.StartFadeOut(const AShown: TBytes; AStart, AStop, ARed, AGreen, ABlue,
  ASteps: Integer);
var
  LColor: Integer;
  LFill: TBytes;
begin
  CheckPalette(AShown);
  if (AStart < 0) or (AStop > 256) or (ASteps < 1) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [ASteps, 'fade', 1, 256]);
  Move(AShown[0], FBase[0], GREED_FADE_PALETTE_BYTES);
  FillChar(FError, SizeOf(FError), 0);
  FillChar(FStep, SizeOf(FStep), 0);
  FillChar(FRemainder, SizeOf(FRemainder), 0);
  for LColor := AStart to AStop - 1 do
  begin
    FRemainder[LColor * 3] := (FBase[LColor * 3] - ARed) mod ASteps;
    FStep[LColor * 3] := (FBase[LColor * 3] - ARed) div ASteps;
    FRemainder[LColor * 3 + 1] := (FBase[LColor * 3 + 1] - AGreen) mod ASteps;
    FStep[LColor * 3 + 1] := (FBase[LColor * 3 + 1] - AGreen) div ASteps;
    FRemainder[LColor * 3 + 2] := (FBase[LColor * 3 + 2] - ABlue) mod ASteps;
    FStep[LColor * 3 + 2] := (FBase[LColor * 3 + 2] - ABlue) div ASteps;
  end;
  LFill := FillPalette(ARed, AGreen, ABlue);
  Move(LFill[0], FTarget[0], GREED_FADE_PALETTE_BYTES);
  FFirst := AStart * 3;
  FLast := AStop * 3 - 1;
  FSteps := ASteps;
  FDone := 0;
  FKind := gfkOut;
  Publish(FBase);
end;

procedure TGreedPaletteFader.StartFadeIn(const AShown, ATarget: TBytes; AStart, AStop, ASteps: Integer);
var
  LIndex: Integer;
begin
  CheckPalette(AShown);
  CheckPalette(ATarget);
  if (AStart < 0) or (AStop > 256) or (ASteps < 1) then
    raise EGreedException.CreateFmt(SGreedArgumentRange, [ASteps, 'fade', 1, 256]);
  Move(AShown[0], FBase[0], GREED_FADE_PALETTE_BYTES);
  Move(ATarget[0], FTarget[0], GREED_FADE_PALETTE_BYTES);
  FillChar(FError, SizeOf(FError), 0);
  FillChar(FWork, SizeOf(FWork), 0);
  FillChar(FStep, SizeOf(FStep), 0);
  FillChar(FRemainder, SizeOf(FRemainder), 0);
  FFirst := AStart * 3;
  FLast := AStop * 3 - 1;
  // px and pdx are shortint in the original: the quotient and the remainder are cut to 8 bits with sign
  for LIndex := FFirst to FLast do
  begin
    FRemainder[LIndex] := ShortInt((FTarget[LIndex] - FBase[LIndex]) mod ASteps);
    FStep[LIndex] := ShortInt((FTarget[LIndex] - FBase[LIndex]) div ASteps);
  end;
  FSteps := ASteps;
  FDone := 0;
  FKind := gfkIn;
  Publish(FWork);
end;

function TGreedPaletteFader.Active: Boolean;
begin
  Result := (FKind <> gfkNone) and (FDone <= FSteps);
end;

function TGreedPaletteFader.Step: Boolean;
var
  LIndex: Integer;
begin
  Result := Active;
  if not Result then
    Exit;
  if FDone = FSteps then
  begin
    // VI_FillPalette(red, green, blue) or I_SetPalette(apal) after the loop
    Publish(FTarget);
    Inc(FDone);
    FKind := gfkNone;
    Exit;
  end;
  if FKind = gfkOut then
  begin
    for LIndex := FFirst to FLast do
    begin
      FBase[LIndex] := Byte(FBase[LIndex] - FStep[LIndex]);
      FError[LIndex] := SmallInt(FError[LIndex] + FRemainder[LIndex]);
      if FError[LIndex] >= FSteps then
      begin
        FError[LIndex] := SmallInt(FError[LIndex] - FSteps);
        Dec(FBase[LIndex]);
      end
      else if FError[LIndex] <= -FSteps then
      begin
        FError[LIndex] := SmallInt(FError[LIndex] + FSteps);
        Inc(FBase[LIndex]);
      end;
    end;
    Publish(FBase);
  end
  else
  begin
    for LIndex := FFirst to FLast do
    begin
      FWork[LIndex] := Byte(FWork[LIndex] + FStep[LIndex]);
      FError[LIndex] := ShortInt(FError[LIndex] + FRemainder[LIndex]);
      if FError[LIndex] >= FSteps then
      begin
        FError[LIndex] := ShortInt(FError[LIndex] - FSteps);
        Inc(FWork[LIndex]);
      end
      else if FError[LIndex] <= -FSteps then
      begin
        FError[LIndex] := ShortInt(FError[LIndex] + FSteps);
        Dec(FWork[LIndex]);
      end;
    end;
    Publish(FWork);
  end;
  Inc(FDone);
end;

end.
