//==============================================================================
// TMidi.StreamBufferSetup
//
// The old function without the device: it converts the first buffers with the same calls (the
// first with CONVERTF_RESET, and no more once the end is found) and writes down what the
// conversion gave. The buffers are four times as long as the old ones, so that the tempo event
// of the legacy pointer has room to write
//
//==============================================================================
function TMidi.StreamBufferSetup: BOOL;
var
  nChkErr: integer;
  bFoundEnd: BOOL;
  dwConvertFlag: DWORD;
  block: TOldBlock;
begin
  bFoundEnd := False;
  GSetupBlocks := nil;

  SetLength(m_StreamBuffers, NUM_STREAM_BUFFERS);

  m_nEmptyBuffers := 0;
  dwConvertFlag := CONVERTF_RESET;

  m_nCurrentBuffer := 0;
  while m_nCurrentBuffer < NUM_STREAM_BUFFERS do
  begin
    m_StreamBuffers[m_nCurrentBuffer].mhBuffer.dwBufferLength := OUT_BUFFER_SIZE;
    GetMem(m_StreamBuffers[m_nCurrentBuffer].mhBuffer.lpData, OUT_BUFFER_SIZE * 4);
    FillChar(m_StreamBuffers[m_nCurrentBuffer].mhBuffer.lpData^, OUT_BUFFER_SIZE * 4, 0);

    m_StreamBuffers[m_nCurrentBuffer].dwStartOffset := 0;
    m_StreamBuffers[m_nCurrentBuffer].dwMaxLength := OUT_BUFFER_SIZE;
    m_StreamBuffers[m_nCurrentBuffer].tkStart := 0;
    m_StreamBuffers[m_nCurrentBuffer].bTimesUp := False;

    nChkErr := ConvertToBuffer(dwConvertFlag, @m_StreamBuffers[m_nCurrentBuffer]);
    if nChkErr <> CONVERTERR_NOERROR then
    begin
      if nChkErr = CONVERTERR_DONE then
      begin
        bFoundEnd := True;
      end
      else
      begin
        Result := False;
        Exit;
      end;
    end;
    m_StreamBuffers[m_nCurrentBuffer].mhBuffer.dwBytesRecorded := m_StreamBuffers[m_nCurrentBuffer].dwBytesRecorded;

    if nChkErr = CONVERTERR_DONE then
      block.Code := 1
    else
      block.Code := 0;
    SetLength(block.Bytes, m_StreamBuffers[m_nCurrentBuffer].dwBytesRecorded);
    if Length(block.Bytes) > 0 then
      Move(m_StreamBuffers[m_nCurrentBuffer].mhBuffer.lpData^, block.Bytes[0], Length(block.Bytes));
    SetLength(GSetupBlocks, Length(GSetupBlocks) + 1);
    GSetupBlocks[High(GSetupBlocks)] := block;

    dwConvertFlag := 0;

    if bFoundEnd then
      break;
    Inc(m_nCurrentBuffer);
  end;

  m_nCurrentBuffer := 0;
  Result := True;
end;

