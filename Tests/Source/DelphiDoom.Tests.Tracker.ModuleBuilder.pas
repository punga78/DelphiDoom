{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the tracker - modules made in memory                   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Tracker.ModuleBuilder;

interface

uses
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Builds the small modules that the tests of the player use. It is not a
  ///   fixture
  /// </summary>
  TTestModuleBuilder = class
  public
    /// <summary>
    ///   A module of one channel with APatternCount patterns of 4 rows, played
    ///   in order, and one instrument with a square wave of 16 samples (eight
    ///   at 16384 and eight at -16384) looped from 0 to 16, whose center
    ///   frequency is 8363 Hz. The speed is 6 and the tempo 125
    /// </summary>
    class function SquareWave(const AFormat: TTrackerFormat;
      const APatternCount: Integer): TTrackerModule; static;

    /// <summary>Sets a cell of a pattern; AVolume -1 means none</summary>
    class procedure SetCell(const AModule: TTrackerModule; const APattern, ARow: Integer;
      const ANote, AInstrument, AEffect, AParam: Byte; const AVolume: Integer = -1); static;
  end;

implementation

{ TTestModuleBuilder }

class function TTestModuleBuilder.SquareWave(const AFormat: TTrackerFormat;
  const APatternCount: Integer): TTrackerModule;
var
  LSample: TTrackerSample;
  LInstrument: TTrackerInstrument;
  LIndex: Integer;
begin
  Result := TTrackerModule.Create;
  Result.Format := AFormat;
  Result.Channels := 1;
  SetLength(Result.ChannelPanning, 1);
  Result.ChannelPanning[0] := TRACKER_NO_PANNING;

  LSample := TTrackerSample.Create;
  SetLength(LSample.Data, 16);
  for LIndex := 0 to 15 do
  begin
    if LIndex < 8 then
      LSample.Data[LIndex] := 16384
    else
      LSample.Data[LIndex] := -16384;
  end;
  LSample.LoopType := tlForward;
  LSample.LoopStart := 0;
  LSample.LoopEnd := 16;
  Result.Samples.Add(LSample);

  LInstrument := TTrackerInstrument.Create;
  LInstrument.Samples.Add(LSample);
  Result.Instruments.Add(LInstrument);

  SetLength(Result.Orders, APatternCount);
  for LIndex := 0 to APatternCount - 1 do
  begin
    Result.Patterns.Add(TTrackerPattern.Create(4, 1));
    Result.Orders[LIndex] := LIndex;
  end;
end;

class procedure TTestModuleBuilder.SetCell(const AModule: TTrackerModule; const APattern,
  ARow: Integer; const ANote, AInstrument, AEffect, AParam: Byte; const AVolume: Integer);
var
  LCell: TTrackerCell;
begin
  LCell.Note := ANote;
  LCell.Instrument := AInstrument;
  LCell.Effect := AEffect;
  LCell.Param := AParam;
  LCell.Volume := AVolume;
  AModule.Patterns[APattern].Cells[ARow, 0] := LCell;
end;

end.
