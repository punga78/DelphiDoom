
//==============================================================================
//
// TMidi.TrackError
//
//==============================================================================
procedure TMidi.TrackError(ptsTrack: LPTRACK; const lpszErr: string);
begin
  DebugOutput('Track buffer offset %d', [DWORD(ptsTrack^.pTrackCurrent) - DWORD(ptsTrack^.pTrackStart)]);
  DebugOutput('Track total length %d', [ptsTrack^.dwTrackLength]);
  DebugOutput('%s', [lpszErr]);
end;

//==============================================================================
//
// TMidi.DebugOutput
//
//==============================================================================
procedure TMidi.DebugOutput(const fmt: string; const A: array of const);
begin
  if devparm then
    if debugfile <> nil then
      fprintf(debugfile, fmt, A);
end;

//==============================================================================
//
// TMidi.SetGlobalVolume
//
//==============================================================================
procedure TMidi.SetGlobalVolume(const v: integer);
begin
  m_volume := GetIntegerInRange(v, 0, VOLUME_INIT);
  SetVolume(VOLUME_INIT);
end;
