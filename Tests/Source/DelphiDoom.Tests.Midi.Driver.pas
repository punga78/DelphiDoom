{******************************************************************************}
{                                                                              }
{  DelphiDoom: MIDI library tests - plays a song with the new classes the way    }
{  the old player did, to compare with the program that records the old one      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Midi.Driver;

interface

uses
  System.SysUtils,
  DelphiDoom.Tests.Midi.Scenarios;

type
  TMidiNewDriver = class
  public
    /// <summary>The blocks of a song under a protocol; Failed if it cannot be loaded</summary>
    class function RunProtocol(const ABytes: TBytes; AProtocol: TMidiProtocol): TMidiRunRecord; static;
    /// <summary>The pieces of the events of a MUS song, with the volume changing</summary>
    class function RunMus(const ABytes: TBytes): TMidiRunRecord; static;
  end;

implementation

uses
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.MusConverter,
  DelphiDoom.Midi.Types,
  DelphiDoom.Midi.Intf,
  DelphiDoom.Midi.Factory,
  DelphiDoom.Midi.Volume,
  DelphiDoom.Midi.EventFeeder;

{ TMidiNewDriver }

class function TMidiNewDriver.RunProtocol(const ABytes: TBytes;
  AProtocol: TMidiProtocol): TMidiRunRecord;
var
  LSequencer: IMidiStreamSequencer;
  LBytes: TBytes;
  LCode: TMidiConvertResult;
  LRound: Integer;
begin
  Result := Default(TMidiRunRecord);
  LSequencer := TMidiFactory.CreateSequencer(nil);
  if (Length(ABytes) = 0) or not LSequencer.Load(@ABytes[0], Length(ABytes)) then
  begin
    Result.Failed := True;
    Exit;
  end;

  // the setup: two blocks, the first with the reset, and the second only if the song goes on
  LCode := LSequencer.ConvertBlock(True, SCENARIO_BUFFER_LENGTH, LBytes);
  Result.AddBlock(Ord(LCode), LBytes);
  if LCode <> mcrDone then
  begin
    LCode := LSequencer.ConvertBlock(False, SCENARIO_BUFFER_LENGTH, LBytes);
    Result.AddBlock(Ord(LCode), LBytes);
  end;

  // Play
  case AProtocol of
    mpLooped:
      LSequencer.Looped := True;
    mpLoopedWithTempo:
      begin
        LSequencer.RequestTempoEvent;
        LSequencer.Looped := True;
      end;
    mpOnce:
      LSequencer.Looped := False;
  end;

  // the buffers that come back
  for LRound := 1 to SCENARIO_ROUNDS do
  begin
    LCode := LSequencer.ConvertBlock(False, SCENARIO_BUFFER_LENGTH, LBytes);
    Result.AddBlock(Ord(LCode), LBytes);
    if LCode = mcrDone then
      Break;
  end;
end;

class function TMidiNewDriver.RunMus(const ABytes: TBytes): TMidiRunRecord;
var
  LEvents: TArray<TMusMidiEvent>;
  LOriginal: TArray<TMusMidiEvent>;
  LNext, LStart, LCount, LVolume, LPiece: Integer;
  LPercent: Cardinal;
  LPieceBytes: TBytes;
begin
  Result := Default(TMidiRunRecord);
  try
    if (Length(ABytes) = 0) or not TMusConverter.TryConvert(@ABytes[0], Length(ABytes),
      SCENARIO_MUS_TEMPO, nil, LEvents) then
    begin
      Result.Failed := True;
      Exit;
    end;
  except
    on EMusConversionException do
    begin
      Result.Failed := True;
      Exit;
    end;
  end;
  LOriginal := Copy(LEvents);
  LNext := 0;
  for LVolume := 0 to High(SCENARIO_MUS_VOLUMES) do
  begin
    LPercent := Cardinal(TMidiVolume.PercentOfLevel(SCENARIO_MUS_VOLUMES[LVolume]));
    TMidiVolume.ApplyToEvents(PMidiStreamEvent(@LEvents[0]), PMidiStreamEvent(@LOriginal[0]),
      Length(LEvents), LPercent);
    for LPiece := 1 to SCENARIO_MUS_PIECES_PER_VOLUME do
    begin
      TMidiEventFeeder.NextPiece(Length(LEvents), SCENARIO_MUS_PIECE, LNext, LStart, LCount);
      SetLength(LPieceBytes, LCount * MIDI_STREAM_EVENT_SIZE);
      if LCount > 0 then
        Move(LEvents[LStart], LPieceBytes[0], Length(LPieceBytes));
      Result.AddBlock(LCount, LPieceBytes);
    end;
  end;
end;

end.
