{******************************************************************************}
{                                                                              }
{  DelphiDoom: tracker - a voice that plays a sample                           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tracker.Voice;

interface

uses
  DelphiDoom.Tracker.Types;

type
  /// <summary>
  ///   Plays a sample at a speed, with a volume and a panning, with linear
  ///   interpolation and the loops (forward and ping-pong)
  /// </summary>
  TTrackerVoice = class
  private
    FSample: TTrackerSample;
    FPosition: Double;
    FIncrement: Double;
    FVolume: Double;
    FPanning: Double;
    FActive: Boolean;
    FBackward: Boolean;
    function ValueAt(const AIndex: Integer): Double;
    function NextIndex(const AIndex: Integer): Integer;
    procedure Advance;
  public
    constructor Create;

    /// <summary>Starts the sample from the AStart-th sample (zero for the beginning)</summary>
    procedure Start(const ASample: TTrackerSample; const AStart: Integer = 0);
    procedure Stop;

    /// <summary>Takes everything of AOther: the sound goes on from where it is</summary>
    procedure CopyFrom(const AOther: TTrackerVoice);

    /// <summary>
    ///   Adds ACount frames of the voice to the buffers, from AOffset; the
    ///   voice stops by itself at the end of a sample without a loop
    /// </summary>
    procedure Mix(const ALeft, ARight: TArray<Double>; const AOffset, ACount: Integer);

    property Sample: TTrackerSample read FSample;
    /// <summary>Position in the sample, in samples</summary>
    property Position: Double read FPosition write FPosition;
    /// <summary>Samples of the sample that go by in each output frame</summary>
    property Increment: Double read FIncrement write FIncrement;
    /// <summary>0..1</summary>
    property Volume: Double read FVolume write FVolume;
    /// <summary>0 (left) to 1 (right)</summary>
    property Panning: Double read FPanning write FPanning;
    property Active: Boolean read FActive;
  end;

implementation

{ TTrackerVoice }

constructor TTrackerVoice.Create;
begin
  inherited Create;
  FIncrement := 1;
  FVolume := 1;
  FPanning := 0.5;
end;

procedure TTrackerVoice.Start(const ASample: TTrackerSample; const AStart: Integer);
begin
  FSample := ASample;
  FPosition := AStart;
  FBackward := False;
  FActive := Assigned(ASample) and (ASample.Length > 0) and (AStart < ASample.Length);
end;

procedure TTrackerVoice.Stop;
begin
  FActive := False;
end;

procedure TTrackerVoice.CopyFrom(const AOther: TTrackerVoice);
begin
  FSample := AOther.FSample;
  FPosition := AOther.FPosition;
  FIncrement := AOther.FIncrement;
  FVolume := AOther.FVolume;
  FPanning := AOther.FPanning;
  FActive := AOther.FActive;
  FBackward := AOther.FBackward;
end;

function TTrackerVoice.ValueAt(const AIndex: Integer): Double;
begin
  if (AIndex < 0) or (AIndex >= FSample.Length) then
    Result := 0
  else
    Result := FSample.Data[AIndex];
end;

// The sample that follows AIndex, for the interpolation
function TTrackerVoice.NextIndex(const AIndex: Integer): Integer;
begin
  Result := AIndex + 1;
  case FSample.LoopType of
    tlForward:
      if Result >= FSample.LoopEnd then
        Result := FSample.LoopStart;
    tlPingPong:
      begin
        if FBackward then
          Result := AIndex - 1
        else if Result >= FSample.LoopEnd then
          Result := FSample.LoopEnd - 1;
        if Result < FSample.LoopStart then
          Result := FSample.LoopStart;
      end;
  end;
end;

procedure TTrackerVoice.Advance;
var
  LLoopLength: Integer;
begin
  case FSample.LoopType of
    tlNone:
      begin
        FPosition := FPosition + FIncrement;
        if FPosition >= FSample.Length then
          FActive := False;
      end;
    tlForward:
      begin
        FPosition := FPosition + FIncrement;
        LLoopLength := FSample.LoopEnd - FSample.LoopStart;
        if LLoopLength < 1 then
          LLoopLength := 1;
        while FPosition >= FSample.LoopEnd do
          FPosition := FPosition - LLoopLength;
      end;
    tlPingPong:
      begin
        if FBackward then
        begin
          FPosition := FPosition - FIncrement;
          if FPosition < FSample.LoopStart then
          begin
            FPosition := 2 * FSample.LoopStart - FPosition;
            FBackward := False;
          end;
        end
        else
        begin
          FPosition := FPosition + FIncrement;
          if FPosition >= FSample.LoopEnd then
          begin
            FPosition := 2 * (FSample.LoopEnd - 1) - FPosition;
            FBackward := True;
          end;
        end;
        if FPosition < FSample.LoopStart then
          FPosition := FSample.LoopStart;
      end;
  end;
end;

procedure TTrackerVoice.Mix(const ALeft, ARight: TArray<Double>; const AOffset, ACount: Integer);
var
  LFrame, LIndex: Integer;
  LFraction, LFirst, LSecond, LValue: Double;
begin
  for LFrame := AOffset to AOffset + ACount - 1 do
  begin
    if not FActive then
      Exit;

    LIndex := Trunc(FPosition);
    LFraction := FPosition - LIndex;
    LFirst := ValueAt(LIndex);
    if LFraction > 0 then
    begin
      LSecond := ValueAt(NextIndex(LIndex));
      LValue := LFirst + (LSecond - LFirst) * LFraction;
    end
    else
      LValue := LFirst;

    LValue := LValue * FVolume;
    ALeft[LFrame] := ALeft[LFrame] + LValue * (1 - FPanning);
    ARight[LFrame] := ARight[LFrame] + LValue * FPanning;

    Advance;
  end;
end;

end.
