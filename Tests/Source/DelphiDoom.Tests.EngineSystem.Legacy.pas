{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the engine system library - the old code               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.EngineSystem.Legacy;

// The code of i_net, i_io, i_mikplay, i_midi, i_midi_legacy, i_crashlog and i_system as it was at
// cb5a45e3 (git show cb5a45e3:Base\<unit>.pas), kept here to prove that the classes of the library do
// what the old procedures did. The bodies are the old ones. What changed is only what touched the
// engine or Windows: myargv is an array of the object, printf and the log are lines in a list, the
// calls of mciSendCommand go to a fake sequencer, the window is a number, the globals are fields.
// Delete this unit with the facades, when nobody needs the proof any more.

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.EngineSystem.Types, DelphiDoom.EngineSystem.Intf,
  DelphiDoom.Net.Types, DelphiDoom.Platform.Intf, d_delphi;

type
  /// <summary>I_InitNetwork and CheckIfDrone of i_net.pas</summary>
  TLegacyNet = class
  public
    myargc: Integer;
    myargv: array[0..127] of string;
    net_consoleplayer: integer;
    net_numnodes: integer;
    net_ticdup: integer;
    net_extratics: integer;
    net_port: integer;
    net_peers: TArray<TNetNodeAddress>;
    netgame: boolean;
    drone: TNetDroneView;
    Output: string;
    Asked: TStringList;
    constructor Create(const AArguments: array of string);
    destructor Destroy; override;
    function M_CheckParm(const check: string): integer;
    procedure CheckIfDrone;
    procedure I_InitNetwork;
  end;

  /// <summary>I_IOprintf, the names of I_InitializeIO and the shutdown of i_io.pas</summary>
  TLegacyIo = class
  public
    stdoutbuffer: TDStringList;
    io_lastNL: boolean;
    constructor Create;
    destructor Destroy; override;
    procedure I_IOprintf(const s: string);
    class function Names(const basename: string; opengl, debugfile: boolean; consoleplayer: integer;
      cdrom: boolean; const cdworkdir: string): TLogFileSet; static;
  end;

  /// <summary>i_mikplay.pas, with the warnings in a list and the window as a number</summary>
  TLegacyMik = class
  public
    mik_init: boolean;
    Warnings: TStringList;
    hMainWnd: NativeUInt;
    constructor Create;
    destructor Destroy; override;
    procedure I_Warning(const warning: string; const Args: array of const);
    procedure I_InitMik;
    procedure I_ShutDownMik;
    procedure I_PlayMik(const data: pointer; const size: integer);
    procedure I_PauseMik;
    procedure I_ResumeMik;
    procedure I_StopMik;
    procedure I_SetMusicVolumeMik(volume: integer);
    procedure I_ProcessMik;
  end;

  /// <summary>i_midi_legacy.pas: the MCI and the window are the ones of the fake, the notification is a call</summary>
  TLegacyMidi = class
  public
    wDeviceID: Cardinal;
    MidiFileNames: TDStringList;
    MidiID: integer;
    Window: NativeUInt;
    fIsMidiPlaying: boolean;
    currentmidi: string;
    Mci: IMciSequencer;
    Printed: string;
    NextWindow: NativeUInt;
    constructor Create(const AMci: IMciSequencer; AFirstWindow: NativeUInt);
    destructor Destroy; override;
    function playMIDIFile(hWndNotify: NativeUInt; lpszMIDIFileName: string; doCheckMidiMapper: boolean = false): Cardinal;
    function restartMIDIFile(hWndNotify: NativeUInt): Cardinal;
    procedure StopPlayingMidi;
    procedure WindowProcNotify(successful: boolean);
    procedure AddMidiFileToPlayList_Legacy(const MidiFile: string);
    procedure ClearMidiFilePlayList_Legacy;
    procedure I_PlayMidi_Legacy(index: integer);
    procedure I_StopMidi_Legacy;
    procedure I_ResumeMidi_Legacy;
    procedure I_PauseMidi_Legacy;
    procedure I_InitMidi_Legacy;
    procedure I_ShutDownMidi_Legacy;
  end;

  /// <summary>I_InitMidi and I_SelectDefaultMidiDevice of i_midi.pas</summary>
  TLegacyMidiSelection = class
  public
    myargc: Integer;
    myargv: array[0..127] of string;
    snd_uselegacymidiplayer: integer;
    uselegacymidiplayer: boolean;
    constructor Create(const AArguments: array of string);
    function M_CheckParm(const check: string): integer;
    procedure I_InitMidi;
    function I_SelectDefaultMidiDevice: LongWord;
  end;

  /// <summary>I_DetectCPU of i_system.pas</summary>
  TLegacyCpu = class
  public
    mmxMachine: Integer;
    AMD3DNowMachine: Integer;
    usemultithread: boolean;
    numcpus: Integer;
    Output: string;
    procedure I_DetectCPU(const cpu: ICpuInfo; confignotfound: boolean);
  end;

implementation

uses
  Winapi.Windows, DelphiDoom.Mikmod.Intf, DelphiDoom.Mikmod.Provider,
  DelphiDoom.Net.NodeListParser;

// The old code wrote Ord(myargv[i + 1][1]): with an empty argument that reads the nil string (an access
// violation: a defect of the old code, "-net" as last argument or "-dup ''"). The copy gives 0 as the class does
function FirstCharOf(const AText: string): Integer;
begin
  if AText = '' then
    Result := 0
  else
    Result := Ord(AText[1]);
end;

{ TLegacyNet }

constructor TLegacyNet.Create(const AArguments: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  myargc := Length(AArguments);
  for LIndex := 0 to High(AArguments) do
    myargv[LIndex] := UpperCase(AArguments[LIndex]);
  net_ticdup := 1;
  net_numnodes := 1;
  net_port := 5000 + $1d;
  Asked := TStringList.Create;
end;

destructor TLegacyNet.Destroy;
begin
  Asked.Free;
  inherited Destroy;
end;

function TLegacyNet.M_CheckParm(const check: string): integer;
var
  LName: string;
begin
  Asked.Add(check);
  LName := UpperCase(check);
  for Result := 1 to myargc - 1 do
    if myargv[Result] = LName then
      Exit;
  Result := 0;
end;

procedure TLegacyNet.CheckIfDrone;
begin
  if M_CheckParm('-left') > 0 then
    drone := ndvLeft
  else if M_CheckParm('-right') > 0 then
    drone := ndvRight
  else if M_CheckParm('-back') > 0 then
    drone := ndvBack;
end;

procedure TLegacyNet.I_InitNetwork;
var
  i: integer;
  p: integer;
  arguments: TArray<string>;
  nodeno: integer;
begin
  // set up for network
  net_ticdup := 1;
  i := M_CheckParm('-dup');
  if (i > 0) and (i < myargc - 1) then
  begin
    net_ticdup := FirstCharOf(myargv[i + 1]) - Ord('0');
    if net_ticdup < 1 then
      net_ticdup := 1
    else if net_ticdup > 9 then
      net_ticdup := 9;
  end;

  if M_CheckParm('-extratic') > 0 then
    net_extratics := 1
  else
    net_extratics := 0;

  p := M_CheckParm('-port');
  if (p > 0) and (p < myargc - 1) then
  begin
    net_port := atoi(myargv[p + 1]);
    Output := Output + Format('Using Port %d'#13#10, [net_port]);
  end;

  CheckIfDrone;

  // parse network game options,
  //  -net <consoleplayer> <host> <host> ...
  i := M_CheckParm('-net');
  if i = 0 then
  begin
    // single player game
    netgame := false;
    net_numnodes := 1;
    net_consoleplayer := 0;
    net_peers := nil;
    exit;
  end;

  netgame := true;

  // parse player number and host list
  net_consoleplayer := FirstCharOf(myargv[i + 1]) - Ord('1');
  Output := Output + Format('console player number: %d'#13#10, [net_consoleplayer]);

  SetLength(arguments, myargc);
  for nodeno := 0 to myargc - 1 do
    arguments[nodeno] := myargv[nodeno];
  net_peers := TNetNodeListParser.Parse(arguments, i + 2, net_port);
  net_numnodes := 1 + Length(net_peers);

  for nodeno := 0 to Length(net_peers) - 1 do
    if net_peers[nodeno].IsLiteral then
      Output := Output + Format('Node number %d address %s'#13#10, [nodeno + 1, net_peers[nodeno].Host])
    else
      Output := Output + Format('Node number %d hostname %s'#13#10, [nodeno + 1, net_peers[nodeno].Host]);
  Output := Output + Format('Total number of players : %d'#13#10, [net_numnodes]);
end;

{ TLegacyIo }

constructor TLegacyIo.Create;
begin
  inherited Create;
  stdoutbuffer := TDStringList.Create;
  io_lastNL := true;
end;

destructor TLegacyIo.Destroy;
begin
  stdoutbuffer.Free;
  inherited Destroy;
end;

procedure TLegacyIo.I_IOprintf(const s: string);
var
  i: integer;
  l: TDStringList;
  len: integer;
begin
  len := Length(s);
  if len = 0 then
    exit;

  l := TDStringList.Create;
  l.Text := s;

  if (len = 1) and (s[1] = #13) then
  begin
    stdoutbuffer.Add('');
    io_lastNL := true;
  end
  else
  begin
    if io_lastNL or (stdoutbuffer.Count = 0) then
      stdoutbuffer.AddStrings(l)
    else
    begin
      stdoutbuffer.Strings[stdoutbuffer.Count - 1] :=
        stdoutbuffer.Strings[stdoutbuffer.Count - 1] + l.Strings[0];
      for i := 1 to l.Count - 1 do
        stdoutbuffer.Add(l.Strings[i]);
    end;
    io_lastNL := s[len] = #13;
  end;

  l.Free;
end;

class function TLegacyIo.Names(const basename: string; opengl, debugfile: boolean;
  consoleplayer: integer; cdrom: boolean; const cdworkdir: string): TLogFileSet;
var
  dfilename: string;
  efilename: string;
  sfilename: string;
begin
  if debugfile then
    if opengl then
      sprintf(dfilename, 'DATA\LOGS\GL%s32_debug%d.txt', [basename, consoleplayer])
    else
      sprintf(dfilename, 'DATA\LOGS\%s32_debug%d.txt', [basename, consoleplayer])
  else
    if opengl then
      sprintf(dfilename, 'DATA\LOGS\GL%s32_debug.txt', [basename])
    else
      sprintf(dfilename, 'DATA\LOGS\%s32_debug.txt', [basename]);
  if opengl then
  begin
    sprintf(efilename, 'DATA\LOGS\GL%s32_stderr.txt', [basename]);
    sprintf(sfilename, 'DATA\LOGS\GL%s32_stdout.txt', [basename]);
  end
  else
  begin
    sprintf(efilename, 'DATA\LOGS\%s32_stderr.txt', [basename]);
    sprintf(sfilename, 'DATA\LOGS\%s32_stdout.txt', [basename]);
  end;

  if cdrom then
  begin
    dfilename := cdworkdir + dfilename;
    efilename := cdworkdir + efilename;
    sfilename := cdworkdir + sfilename;
  end;
  Result.DebugFile := dfilename;
  Result.ErrorFile := efilename;
  Result.StdoutFile := sfilename;
end;

{ TLegacyMik }

constructor TLegacyMik.Create;
begin
  inherited Create;
  Warnings := TStringList.Create;
  hMainWnd := 7;
end;

destructor TLegacyMik.Destroy;
begin
  Warnings.Free;
  inherited Destroy;
end;

procedure TLegacyMik.I_Warning(const warning: string; const Args: array of const);
var
  msg: string;
begin
  sprintf(msg, warning, Args);
  Warnings.Add(msg);
end;

const
  MIK_FREQ = 44100;
  MIK_VOLUME_CONTROL: array[0..15] of word = (
      0,     9,     17,    26,
     34,    43,     51,    60,
     68,    77,     85,    94,
    102,   111,    119,   127
  );

procedure TLegacyMik.I_InitMik;
begin
  try
    TMikModProvider.Client.Initialize(MIK_FREQ, True, True, True,
      NativeUInt(hMainWnd), 0);
    mik_init := True;
  except
    on E: EMikModException do
    begin
      mik_init := False;
      I_Warning('I_InitMik(): %s'#13#10, [E.Message]);
    end;
  end;
end;

procedure TLegacyMik.I_ShutDownMik;
begin
  mik_init := False;
  TMikModProvider.Release;
end;

procedure TLegacyMik.I_PlayMik(const data: pointer; const size: integer);
begin
  if not mik_init then
    Exit;

  // The tracker reads the module from memory: no temporary file
  try
    TMikModProvider.Client.LoadFromMemory(data, size);
    TMikModProvider.Client.Play(True);
  except
    on E: EMikModException do
      I_Warning('I_PlayMik(): %s'#13#10, [E.Message]);
  end;
end;

procedure TLegacyMik.I_PauseMik;
begin
  if not mik_init then
    Exit;

  try
    if not TMikModProvider.Client.IsPaused then
      TMikModProvider.Client.Pause;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to pause
  end;
end;

procedure TLegacyMik.I_ResumeMik;
begin
  if not mik_init then
    Exit;

  try
    if TMikModProvider.Client.IsPaused then
      TMikModProvider.Client.Resume;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to resume
  end;
end;

procedure TLegacyMik.I_StopMik;
begin
  if not mik_init then
    Exit;

  try
    TMikModProvider.Client.Stop;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to stop
  end;
end;

procedure TLegacyMik.I_SetMusicVolumeMik(volume: integer);
begin
  if not mik_init then
    Exit;

  try
    TMikModProvider.Client.SetVolume(MIK_VOLUME_CONTROL[ibetween(volume, 1, 15)]);
  except
    on EMikModException do
      ; // Nothing is loaded yet: the volume is set when the music starts
  end;
end;

procedure TLegacyMik.I_ProcessMik;
begin
  if not mik_init then
    Exit;

  try
    TMikModProvider.Client.Update;
  except
    on EMikModException do
      ; // Nothing is loaded: there is nothing to mix
  end;
end;

{ TLegacyMidi }

constructor TLegacyMidi.Create(const AMci: IMciSequencer; AFirstWindow: NativeUInt);
begin
  inherited Create;
  Mci := AMci;
  NextWindow := AFirstWindow;
end;

destructor TLegacyMidi.Destroy;
begin
  MidiFileNames.Free;
  inherited Destroy;
end;

function TLegacyMidi.playMIDIFile(hWndNotify: NativeUInt; lpszMIDIFileName: string;
  doCheckMidiMapper: boolean): Cardinal;
var
  mapper: boolean;
  newdevice: Cardinal;
begin
  // Open the device by specifying the device and filename.
  // MCI will attempt to choose the MIDI mapper as the output port.
  result := Mci.Open(lpszMIDIFileName, newdevice);
  // Failed to open device. Don't close it; just return error.
  if result <> 0 then
    exit;

  // The device opened successfully; get the device ID.
  wDeviceID := newdevice;

  if doCheckMidiMapper then
  begin
    // Check if the output port is the MIDI mapper.
    result := Mci.QueryMapperPort(wDeviceID, mapper);
    if result <> 0 then
    begin
      Mci.Close(wDeviceID);
      exit;
    end
    else if not mapper then
    // The output port is not the MIDI mapper.
    begin
      Printed := Printed + 'MIDI mapper unavailable';
      exit;
    end;
  end;

  // Begin playback. The window procedure function for the parent
  // window will be notified with an MM_MCINOTIFY message when
  // playback is complete. At this time, the window procedure closes
  // the device.
  result := Mci.Play(wDeviceID, hWndNotify);
  if result > 0 then
  begin
    Mci.Close(wDeviceID);
    exit;
  end;

  currentmidi := strupper(lpszMIDIFileName);
end;

function TLegacyMidi.restartMIDIFile(hWndNotify: NativeUInt): Cardinal;
begin
  result := Mci.SeekToStart(wDeviceID, hWndNotify);
  if result > 0 then
  begin
    Mci.Close(wDeviceID);
    exit;
  end;

  result := Mci.Play(wDeviceID, hWndNotify);
  if result > 0 then
    Mci.Close(wDeviceID);
end;

procedure TLegacyMidi.StopPlayingMidi;
begin
  Mci.Stop(wDeviceID);
  Mci.Close(wDeviceID);
  currentmidi := '';
end;

// WindowProc, case MM_MCINOTIFY
procedure TLegacyMidi.WindowProcNotify(successful: boolean);
var
  newmidi: string;
begin
  if successful then
  begin
    if MidiID >= MidiFileNames.Count - 1 then
      MidiID := 0
    else
      inc(MidiID);
    newmidi := strupper(MidiFileNames[MidiID]);
    if newmidi = currentmidi then
      restartMIDIFile(Window)
    else
    begin
      StopPlayingMidi;
      playMIDIFile(Window, newmidi);
    end;
  end;
end;

procedure TLegacyMidi.AddMidiFileToPlayList_Legacy(const MidiFile: string);
begin
  if MidiFileNames = nil then
    MidiFileNames := TDStringList.Create;
  MidiFileNames.Add(MidiFile);
end;

procedure TLegacyMidi.ClearMidiFilePlayList_Legacy;
begin
  if MidiFileNames <> nil then
    MidiFileNames.Clear;
end;

procedure TLegacyMidi.I_PlayMidi_Legacy(index: integer);
begin
  I_StopMidi_Legacy;
  if Window = 0 then
  begin
    // the window is a number: CreateWindowEx
    Window := NextWindow;
  end;

  if (index < MidiFileNames.Count) and (index > -1) then
  begin
    MidiID := index;
    playMIDIFile(Window, MidiFileNames[MidiID], true);
    fIsMidiPlaying := true;
  end
  else
    Printed := Printed + 'MIDI mapper unavailable';
end;

procedure TLegacyMidi.I_StopMidi_Legacy;
begin
  if Window <> 0 then
  begin
    StopPlayingMidi;
    // SendMessage(Window, WM_CLOSE, 0, 0): DestroyWindow
    Window := 0;
    fIsMidiPlaying := false;
  end;
end;

procedure TLegacyMidi.I_ResumeMidi_Legacy;
begin
  Mci.Resume(wDeviceID);
end;

procedure TLegacyMidi.I_PauseMidi_Legacy;
begin
  Mci.Pause(wDeviceID);
end;

procedure TLegacyMidi.I_InitMidi_Legacy;
begin
  Window := 0;
  MidiFileNames := TDStringList.Create;
  MidiID := 0;
  fIsMidiPlaying := false;
end;

procedure TLegacyMidi.I_ShutDownMidi_Legacy;
begin
  StopPlayingMidi;
  MidiFileNames.Free;
  MidiFileNames := nil;
end;

{ TLegacyMidiSelection }

constructor TLegacyMidiSelection.Create(const AArguments: array of string);
var
  LIndex: Integer;
begin
  inherited Create;
  myargc := Length(AArguments);
  for LIndex := 0 to High(AArguments) do
    myargv[LIndex] := UpperCase(AArguments[LIndex]);
  snd_uselegacymidiplayer := 2;
end;

function TLegacyMidiSelection.M_CheckParm(const check: string): integer;
var
  LName: string;
begin
  LName := UpperCase(check);
  for Result := 1 to myargc - 1 do
    if myargv[Result] = LName then
      Exit;
  Result := 0;
end;

procedure TLegacyMidiSelection.I_InitMidi;
begin
  if M_CheckParm('-uselegacymidiplayer') > 0 then
    snd_uselegacymidiplayer := 1;
  if M_CheckParm('-nouselegacymidiplayer') > 0 then
    snd_uselegacymidiplayer := 0;
  if M_CheckParm('-internalmidiplayer') > 0 then
    snd_uselegacymidiplayer := 2;
  uselegacymidiplayer := snd_uselegacymidiplayer = 1;
end;

function TLegacyMidiSelection.I_SelectDefaultMidiDevice: LongWord;
var
  p: integer;
begin
  result := $FFFFFFFF; // MIDI_MAPPER
  p := M_CheckParm('-mididevice');
  if (p > 0) and (p < myargc) then
    result := atoui(myargv[p + 1], $FFFFFFFF);
end;

{ TLegacyCpu }

procedure TLegacyCpu.I_DetectCPU(const cpu: ICpuInfo; confignotfound: boolean);
begin
  if cpu.HasMmx then
    mmxMachine := 1
  else
    mmxMachine := 0;
  if cpu.Has3DNow then
    AMD3DNowMachine := 1
  else
    AMD3DNowMachine := 0;

  if mmxMachine <> 0 then
    Output := Output + ' MMX extentions detected'#13#10;
  if AMD3DNowMachine <> 0 then
    Output := Output + ' AMD 3D Now! extentions detected'#13#10;

  numcpus := cpu.ProcessorCount;

  if numcpus > 1 then
    Output := Output + Format(' Multi-core system detected (%d CPUs)'#13#10, [numcpus]);

  if confignotfound then
    usemultithread := numcpus > 1;

  if usemultithread then
    Output := Output + ' Multithreading mode ON'#13#10
  else
  begin
    if numcpus > 1 then
      Output := Output + ' Multithreading mode OFF (will not use all cores)'#13#10
    else
      Output := Output + ' Multithreading mode OFF'#13#10;
  end;
end;

end.
