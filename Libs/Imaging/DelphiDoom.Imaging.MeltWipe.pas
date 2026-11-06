{******************************************************************************}
{                                                                              }
{  DelphiDoom: Imaging library - the melt of the screen between two scenes     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Imaging.MeltWipe;

interface

uses
  System.SysUtils, DelphiDoom.Imaging.Types, DelphiDoom.Imaging.Intf;

type
  /// <summary>
  ///   The wipe of f_wipe.pas (wipe_initMelt, wipe_doMelt): each column of the old screen
  ///   waits a random time and then slides down, and what it leaves is the new screen. It works
  ///   on buffers that it receives, so it does not know the software renderer or OpenGL: the
  ///   pitch and the alpha of the destination are in the settings
  /// </summary>
  /// <remarks>
  ///   Kept as in the old code: the pixels are copied only in the last tic of each call of
  ///   Advance (the columns move in all of them), and a column that has not started is not
  ///   drawn
  /// </remarks>
  TImagingMeltWipe = class(TInterfacedObject, IImagingMeltWipe)
  private
    FRandom: IImagingRandom;
    FSettings: TImagingWipeSettings;
    FStartScreen: TImagingPixels;
    FEndScreen: TImagingPixels;
    FDestination: TImagingPixels;
    FPositions: TArray<Integer>;
    FVelocity: Integer;
    FStarted: Boolean;
    procedure DrawColumn(AColumn, APosition: Integer);
  public
    constructor Create(const ARandom: IImagingRandom);
    procedure Start(const ASettings: TImagingWipeSettings; const AStartScreen,
      AEndScreen: TImagingPixels; const ADestination: TImagingPixels);
    function Advance(ATicks: Integer): Boolean;
  end;

implementation

{ TImagingMeltWipe }

constructor TImagingMeltWipe.Create(const ARandom: IImagingRandom);
begin
  inherited Create;
  FRandom := ARandom;
end;

procedure TImagingMeltWipe.Start(const ASettings: TImagingWipeSettings; const AStartScreen,
  AEndScreen: TImagingPixels; const ADestination: TImagingPixels);
var
  LColumn: Integer;
  LRow: Integer;
  LHeights: TArray<Integer>;
  LRandoms: array[0..319] of Byte;
  LStep: Integer;
begin
  if (ASettings.Width <= 0) or (ASettings.Height <= 0) or
    (ASettings.DestinationPitch < ASettings.Width) then
    raise EImagingException.Create(SImagingBadWipeSettings);
  if (Length(AStartScreen) < ASettings.Width * ASettings.Height) or
    (Length(AEndScreen) < ASettings.Width * ASettings.Height) or
    (Length(ADestination) < ASettings.DestinationPitch * ASettings.Height) then
    raise EImagingException.Create(SImagingWipeBufferSize);

  FSettings := ASettings;
  FStartScreen := AStartScreen;
  FEndScreen := AEndScreen;
  FDestination := ADestination;

  SetLength(LHeights, FSettings.Width);
  for LColumn := 0 to FSettings.Width - 1 do
    LHeights[LColumn] := Trunc(LColumn * 320 / FSettings.Width);
  for LStep := 0 to 319 do
    LRandoms[LStep] := FRandom.NextByte;

  // the start screen goes to the destination
  for LRow := 0 to FSettings.Height - 1 do
    for LColumn := 0 to FSettings.Width - 1 do
      FDestination[LRow * FSettings.DestinationPitch + LColumn] :=
        FStartScreen[LRow * FSettings.Width + LColumn];

  // the initial positions of the columns (negative: they have not started to slide)
  SetLength(FPositions, FSettings.Width);
  FPositions[0] := -(LRandoms[0] mod 16);
  for LColumn := 1 to FSettings.Width - 1 do
  begin
    FPositions[LColumn] := FPositions[LColumn - 1] + (LRandoms[LHeights[LColumn]] mod 3) - 1;
    if FPositions[LColumn] > 0 then
      FPositions[LColumn] := 0
    else if FPositions[LColumn] = -16 then
      FPositions[LColumn] := -15;
  end;

  FVelocity := IMAGING_FRACUNIT * FSettings.Height div 200;
  for LColumn := 0 to FSettings.Width - 1 do
    FPositions[LColumn] := FPositions[LColumn] * FVelocity;

  // columns that read the same random value start together
  for LColumn := 1 to FSettings.Width - 1 do
    if LHeights[LColumn - 1] = LHeights[LColumn] then
      FPositions[LColumn] := FPositions[LColumn - 1];
  FStarted := True;
end;

procedure TImagingMeltWipe.DrawColumn(AColumn, APosition: Integer);
var
  LRow: Integer;
begin
  for LRow := 0 to APosition - 1 do
    FDestination[LRow * FSettings.DestinationPitch + AColumn] :=
      FEndScreen[LRow * FSettings.Width + AColumn] or FSettings.AlphaMask;
  // below the new screen slides the old one, from its first row
  for LRow := APosition to FSettings.Height - 1 do
    FDestination[LRow * FSettings.DestinationPitch + AColumn] :=
      FStartScreen[(LRow - APosition) * FSettings.Width + AColumn] or FSettings.AlphaMask;
end;

function TImagingMeltWipe.Advance(ATicks: Integer): Boolean;
var
  LColumn: Integer;
  LDelta: Integer;
  LLimit: Integer;
begin
  if not FStarted then
    raise EImagingException.Create(SImagingWipeNotStarted);

  Result := True;
  LLimit := FSettings.Height * IMAGING_FRACUNIT;
  while ATicks > 0 do
  begin
    for LColumn := 0 to FSettings.Width - 1 do
    begin
      if FPositions[LColumn] < 0 then
      begin
        FPositions[LColumn] := FPositions[LColumn] + FVelocity;
        Result := False;
      end
      else if FPositions[LColumn] < LLimit then
      begin
        if FPositions[LColumn] <= 15 * FVelocity then
          LDelta := FPositions[LColumn] + FVelocity
        else
          LDelta := 8 * FVelocity;
        if (FPositions[LColumn] + LDelta) >= LLimit then
          LDelta := LLimit - FPositions[LColumn];
        if ATicks = 1 then
          DrawColumn(LColumn, FPositions[LColumn] div IMAGING_FRACUNIT);
        FPositions[LColumn] := FPositions[LColumn] + LDelta;
        Result := False;
      end;
    end;
    Dec(ATicks);
  end;
end;

end.
