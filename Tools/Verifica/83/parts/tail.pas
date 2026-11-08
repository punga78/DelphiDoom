
//==============================================================================
//
// OldMidiRun
// Loads a song (the setup converts the first buffers), plays it as Play does and asks for the
// buffers that the stream gives back, as OnMidiOutDone did
//
//==============================================================================
function OldMidiRun(const AData: TBytes; AMode: TOldMode; ARounds: Integer): TOldRun;
var
  midi: TMidi;
  nChkErr: integer;
  round: integer;
  buffer: integer;
  block: TOldBlock;
begin
  Result.Failed := False;
  Result.Blocks := nil;
  GFixTempoPointer := AMode <> omTempoLegacy;
  midi := TMidi.Create;
  try
    try
      if (Length(AData) = 0) or not midi.LoadData(@AData[0], Length(AData)) then
      begin
        Result.Failed := True;
        Exit;
      end;
      Result.Blocks := Copy(GSetupBlocks);

      // Play(True) inserts a tempo event first because the song did not loop yet; the other two
      // protocols do not
      case AMode of
        omLooped:
          midi.m_bLooped := True;
        omTempo, omTempoLegacy:
          begin
            midi.m_bInsertTempo := True;
            midi.m_bLooped := True;
          end;
        omOnce:
          midi.m_bLooped := False;
      end;

      for round := 1 to ARounds do
      begin
        buffer := midi.m_nCurrentBuffer;
        midi.m_StreamBuffers[buffer].dwStartOffset := 0;
        midi.m_StreamBuffers[buffer].dwMaxLength := OUT_BUFFER_SIZE;
        midi.m_StreamBuffers[buffer].tkStart := 0;
        midi.m_StreamBuffers[buffer].dwBytesRecorded := 0;
        midi.m_StreamBuffers[buffer].bTimesUp := False;
        nChkErr := midi.ConvertToBuffer(0, @midi.m_StreamBuffers[buffer]);
        if nChkErr = CONVERTERR_DONE then
          block.Code := 1
        else if nChkErr = CONVERTERR_NOERROR then
          block.Code := 0
        else
          block.Code := 9;
        SetLength(block.Bytes, midi.m_StreamBuffers[buffer].dwBytesRecorded);
        if Length(block.Bytes) > 0 then
          Move(midi.m_StreamBuffers[buffer].mhBuffer.lpData^, block.Bytes[0], Length(block.Bytes));
        SetLength(Result.Blocks, Length(Result.Blocks) + 1);
        Result.Blocks[High(Result.Blocks)] := block;
        if nChkErr <> CONVERTERR_NOERROR then
          Break;
        midi.m_nCurrentBuffer := (midi.m_nCurrentBuffer + 1) mod NUM_STREAM_BUFFERS;
      end;
    except
      on EOldMidiError do
      begin
        Result.Failed := True;
        Result.Blocks := nil;
      end;
    end;
  finally
    // nothing was ever given to a device: the destructor must not stop one
    midi.m_uCallbackStatus := STATUS_CALLBACKDEAD;
    midi.Free;
  end;
end;

end.
