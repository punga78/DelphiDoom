{******************************************************************************}
{                                                                              }
{  DelphiDoom: heads-up display library - the frames per second                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Hud.FpsCounter;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Hud.Types;

type
  /// <summary>
  ///   Counts the frames per second from the times of the last frames (the old HU_DoFPSStuff and
  ///   HU_FPS): two rings, a short one of 128 times and a long one, the long one is used when the
  ///   short one says more than 128 frames per second
  /// </summary>
  /// <remarks>
  ///   The integer arithmetic wraps as in the old code (the settings of the unit turn the overflow
  ///   checks off on purpose): the times are in fixed point, a second is TicRate * 65536.
  /// </remarks>
  THudFpsCounter = class sealed
  strict private
    const
      SHORT_HISTORY = 128;
  strict private
    FTicRate: Integer;
    FLongSize: Integer;
    FShort: TArray<Integer>;
    FLong: TArray<Integer>;
    FShortHead: Integer;
    FLongHead: Integer;
    FTicker: Integer;
    FText: string;
  public
    /// <summary>A counter for the given tics per second and size of the long ring</summary>
    constructor Create(const ATicRate, ALongHistory: Integer);
    /// <summary>Records the time of a frame (HU_DoFPSStuff)</summary>
    procedure AddFrame(const ATime: Integer);
    /// <summary>Forgets the times (not the position in the rings, as the old HU_Init)</summary>
    procedure Clear;
    /// <summary>Frames per second now (HU_FPS)</summary>
    function FramesPerSecond: Integer;
    /// <summary>
    ///   A tic passed: every half second the text "n fps" is made again (the old fps_ticker)
    /// </summary>
    procedure Tick;
    /// <summary>The text to draw, for example "35 fps" (empty before the first tic)</summary>
    property Text: string read FText;
  end;

implementation

uses
  System.SysUtils;

resourcestring
  SBadHistory = 'The frame counter needs a long history of at least %d times, not %d';
  SBadTicRate = 'The frame counter needs a positive tic rate, not %d';

{ THudFpsCounter }

constructor THudFpsCounter.Create(const ATicRate, ALongHistory: Integer);
begin
  inherited Create;
  if ATicRate <= 0 then
    raise EHudException.CreateFmt(SBadTicRate, [ATicRate]);
  if ALongHistory < SHORT_HISTORY then
    raise EHudException.CreateFmt(SBadHistory, [SHORT_HISTORY, ALongHistory]);
  FTicRate := ATicRate;
  FLongSize := ALongHistory;
  SetLength(FShort, SHORT_HISTORY);
  SetLength(FLong, ALongHistory);
  FShortHead := -1;
  FLongHead := -1;
end;

procedure THudFpsCounter.AddFrame(const ATime: Integer);
begin
  FShortHead := (FShortHead + 1) mod SHORT_HISTORY;
  FShort[FShortHead] := ATime;
  FLongHead := (FLongHead + 1) mod FLongSize;
  FLong[FLongHead] := ATime;
end;

procedure THudFpsCounter.Clear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to SHORT_HISTORY - 1 do
    FShort[LIndex] := 0;
  for LIndex := 0 to FLongSize - 1 do
    FLong[LIndex] := 0;
end;

function THudFpsCounter.FramesPerSecond: Integer;
var
  LDifference: Integer;
begin
  // before the first frame the heads are -1: the old code read the array at -1, that is whatever
  // came before it in memory; here the counter says the tic rate until there is a frame
  if FShortHead < 0 then
    Exit(FTicRate);
  LDifference := FShort[FShortHead] - FShort[(FShortHead + 1) mod SHORT_HISTORY] + 1;
  if LDifference > 0 then
  begin
    Result := FTicRate * SHORT_HISTORY * HUD_FRACUNIT div LDifference;
    if Result > SHORT_HISTORY then
    begin
      LDifference := FLong[FLongHead] - FLong[(FLongHead + 1) mod FLongSize] + 1;
      if LDifference > 0 then
        Result := FTicRate * FLongSize * HUD_FRACUNIT div LDifference;
    end;
  end
  else
    Result := FTicRate;
end;

procedure THudFpsCounter.Tick;
begin
  Dec(FTicker);
  if FTicker <= 0 then
  begin
    FText := IntToStr(FramesPerSecond) + ' fps';
    FTicker := FTicRate div 2;
  end;
end;

end.
