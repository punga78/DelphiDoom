{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - the sequencer (func_*, decode_op...)        }
{                                                                              }
{  Port of adlplayer.cpp (X-COM Adlib Player by Volutar, OpenXcom,              }
{  GPL v3 or later): see Libs\Opl\README.md for the license                     }
{                                                                              }
{  The globals of the C are fields. The pointers into the song are offsets      }
{  into a copy of its bytes (-1 is the null pointer); a read outside the song   }
{  or an index outside a table, which the C does without noticing, raises       }
{  EXcomAdlibException (the music stops: Mute is called before it is raised)    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.Sequencer;

interface

uses
  System.SysUtils, DelphiDoom.XcomAdlib.Types, DelphiDoom.XcomAdlib.Intf;

type
  TXcomAdlibSequencer = class(TInterfacedObject, IXcomAdlibSequencer)
  strict private
    FWriter: IXcomAdlibRegisterWriter;
    FData: TBytes;
    FChannels: array[0..XCOM_ADLIB_CHANNELS - 1] of TXcomAdlibChannel;
    FInstruments: TXcomAdlibInstruments;
    FSavedInstruments: array[0..1] of TXcomAdlibInstruments;
    FSubtracks: array[0..XCOM_ADLIB_MAX_SUBTRACKS - 1] of Integer;
    FChorusInstruments: array[0..XCOM_ADLIB_INSTRUMENTS - 1] of Byte;
    FMasterMusicVolume: Integer;
    FTmpMusicVolume: Integer;
    FWantFade: Boolean;
    FMusicPlaying: Boolean;
    FTempo: Integer;
    FTempoRun: Integer;
    FTempoInc: Integer;
    FSamplesAddress: Integer;
    FInstrumentsCount: Integer;
    FSubtracksCount: Integer;
    FPolyphonyLevel: Integer;
    FFormat: Integer;
    /// <summary>Changes with every song that is not the one already set up: the addresses of a state belong to it</summary>
    FSongGeneration: Integer;
    /// <summary>The song generation each saved state was taken in (0: never saved, all addresses null)</summary>
    FSavedGeneration: array[0..1] of Integer;
    class function Sar(AValue: Integer; ACount: Integer): Integer; static; inline;
    function ReadByte(var APosition: Integer): Integer;
    function PeekWord(APosition: Integer): Integer;
    function GetNumSeq(var APosition: Integer): Integer;
    procedure AdlibReg(ARegister, AValue: Integer);
    procedure AdlibInit;
    procedure AdlibSetAmplitude(AChannel, AValue: Integer);
    procedure ClearChannels;
    procedure AdlibResetChannels;
    function GetPitchedFreqInstr(ANote, AInstrument: Integer): Integer;
    procedure AdlibSetInstrumentPitch(AInstrument, APitch: Integer);
    function AdlibGetUnusedChannel(ASampleId: Integer; out ASameSample: Boolean): Integer;
    procedure AdlibPlayNote(ANote, AVolume, AInstrument: Integer);
    procedure FadeVolumeIfNeed;
    function FreeChannelAvailable: Boolean;
    function ChorusOf(AInstrument: Integer): Integer;
    function DecodeOp(AInstrument: Integer; var AAnotherLoop: Boolean): Integer;
    procedure InitMusicData(ALength: Integer);
    procedure InitMusic;
    procedure Fail(const AMessage: string);
  public
    constructor Create(const AWriter: IXcomAdlibRegisterWriter);
    procedure Setup(const ASong: TBytes; ALength: Integer);
    procedure Tick;
    procedure Mute;
    procedure Fade;
    function IsPlaying: Boolean;
    procedure SetTempo(AValue: Integer);
    procedure SetVolume(AValue: Integer);
    function Polyphony: Integer;
    procedure SaveState(AIndex: Integer);
    procedure LoadState(AIndex: Integer);
  end;

implementation

{$Q-}
{$R-}

const
  /// <summary>The C converts the products with these doubles to int (truncating)</summary>
  TEMPO_CONTROLLER_SCALE: Double = 0.8;
  TEMPO_SETUP_SCALE: Double = 0.4;
  SNoteOutsideTable = 'The note %d is outside the frequency table';

{ TXcomAdlibSequencer }

constructor TXcomAdlibSequencer.Create(const AWriter: IXcomAdlibRegisterWriter);
var
  LIndex: Integer;
begin
  inherited Create;
  if not Assigned(AWriter) then
    raise EXcomAdlibException.Create('The register writer is missing');
  FWriter := AWriter;
  // the initial values of the globals
  FMasterMusicVolume := 127;
  FTmpMusicVolume := 127;
  FTempo := 120;
  FTempoRun := 60;
  FTempoInc := 70;
  FSamplesAddress := -1;
  for LIndex := 0 to XCOM_ADLIB_INSTRUMENTS - 1 do
  begin
    FInstruments[LIndex].CurAddress := -1;
    FInstruments[LIndex].StartAddress := -1;
    FInstruments[LIndex].ReturnAddress := -1;
    FSavedInstruments[0][LIndex] := FInstruments[LIndex];
    FSavedInstruments[1][LIndex] := FInstruments[LIndex];
  end;
end;

class function TXcomAdlibSequencer.Sar(AValue: Integer; ACount: Integer): Integer;
begin
  if AValue >= 0 then
    Result := AValue shr ACount
  else
    Result := not ((not AValue) shr ACount);
end;

procedure TXcomAdlibSequencer.Fail(const AMessage: string);
begin
  // the C goes on with whatever it finds: here the music stops
  FMusicPlaying := False;
  raise EXcomAdlibException.Create(AMessage);
end;

function TXcomAdlibSequencer.ReadByte(var APosition: Integer): Integer;
begin
  if (APosition < 0) or (APosition >= Length(FData)) then
    Fail(Format('The song is read outside its %d bytes (position %d)', [Length(FData), APosition]));
  Result := FData[APosition];
  Inc(APosition);
end;

function TXcomAdlibSequencer.PeekWord(APosition: Integer): Integer;
begin
  if (APosition < 0) or (APosition + 1 >= Length(FData)) then
    Fail(Format('The song is read outside its %d bytes (position %d)', [Length(FData), APosition]));
  Result := FData[APosition] or (FData[APosition + 1] shl 8);
end;

function TXcomAdlibSequencer.GetNumSeq(var APosition: Integer): Integer;
var
  LByte: Integer;
begin
  // get_numseq: reads a running-length value from the data stream
  Result := 0;
  repeat
    LByte := ReadByte(APosition);
    Result := (Result shl 7) + (LByte and $7F);
  until (LByte and $80) = 0;
end;

procedure TXcomAdlibSequencer.AdlibReg(ARegister, AValue: Integer);
begin
  FWriter.WriteRegister(ARegister, AValue);
end;

procedure TXcomAdlibSequencer.AdlibInit;
var
  LIndex: Integer;
begin
  // adlib_init: initialises adlib parameters
  for LIndex := 1 to $F4 do
    AdlibReg(LIndex, 0);
  AdlibReg($04, $60); // set both timers
  AdlibReg($04, $80); // reset timers
  AdlibReg($01, $20); // bit5 defines any wave form
  AdlibReg($A8, $01); // last channel freq -??
  AdlibReg($08, $40); // note mode
  AdlibReg($BD, $C0); // vibrato/AM depth
end;

procedure TXcomAdlibSequencer.AdlibSetAmplitude(AChannel, AValue: Integer);
begin
  // adlib_set_amplitude: sets voice amplitude for particular adlib channel
  AdlibReg($43 + XCOM_ADLIB_OPERATORS[AChannel], (not Sar(AValue, 1)) and $3F);
end;

procedure TXcomAdlibSequencer.ClearChannels;
var
  LIndex: Integer;
begin
  // clear_channels: clear channel notes and samples
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
  begin
    FChannels[LIndex].CurSample := $FF;
    FChannels[LIndex].CurNote := 0;
  end;
end;

procedure TXcomAdlibSequencer.AdlibResetChannels;
var
  LIndex: Integer;
begin
  // adlib_reset_channels: resets (clears) adlib channels
  ClearChannels;
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
  begin
    AdlibReg($B0 + LIndex, 0);
    AdlibSetAmplitude(LIndex, 0);
  end;
end;

function TXcomAdlibSequencer.GetPitchedFreqInstr(ANote, AInstrument: Integer): Integer;
var
  LPitch: Integer;
begin
  // get_pitched_freq_instr: returns note frequency with pitch wheel value applied
  LPitch := FInstruments[AInstrument].CurPitchBend;
  if (ANote < 0) or (ANote >= XCOM_ADLIB_NOTES) then
    Fail(Format(SNoteOutsideTable, [ANote]));
  if LPitch = 0 then
    Result := XCOM_ADLIB_FREQUENCIES[ANote]
  else if LPitch > 0 then
    Result := XCOM_ADLIB_FREQUENCIES[ANote] + XCOM_ADLIB_DETUNES[ANote] * LPitch
  else
  begin
    if ANote < 1 then
      Fail(Format(SNoteOutsideTable, [ANote - 1]));
    Result := XCOM_ADLIB_FREQUENCIES[ANote] + XCOM_ADLIB_DETUNES[ANote - 1] * LPitch;
  end;
end;

procedure TXcomAdlibSequencer.AdlibSetInstrumentPitch(AInstrument, APitch: Integer);
var
  LIndex: Integer;
  LNote: Integer;
  LFreq: Integer;
  LHiFreq: Integer;
begin
  // adlib_set_instrument_pitch: sets pitch for particular instrument, for the adlib channels with the same instrument
  FInstruments[AInstrument].CurPitchBend := SmallInt(APitch);
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do // search through active adlib channels
  begin
    LNote := FChannels[LIndex].CurNote;
    if (LNote <> 0) and (FChannels[LIndex].CurInstrument = AInstrument) then
    begin
      LFreq := GetPitchedFreqInstr(LNote, AInstrument);
      FChannels[LIndex].CurFreq := Byte(LFreq);
      AdlibReg($A0 + LIndex, LFreq and $FF);
      LHiFreq := ((LFreq shr 8) and $03) or (XCOM_ADLIB_OCTAVES[LNote] shl 2);
      FChannels[LIndex].HiFreq := Byte(LHiFreq);
      AdlibReg($B0 + LIndex, LHiFreq or $20);
    end;
  end;
end;

function TXcomAdlibSequencer.AdlibGetUnusedChannel(ASampleId: Integer; out ASameSample: Boolean): Integer;
var
  LMaxDuration: Integer;
  LIndex: Integer;
begin
  // adlib_get_unused_channel: gets unused adlib channel and checks if old sample is the same
  Result := 0;
  LMaxDuration := 0;
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
    Inc(FChannels[LIndex].Duration);
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do // 12/9
  begin
    if FChannels[LIndex].Duration > LMaxDuration then
    begin
      LMaxDuration := FChannels[LIndex].Duration;
      Result := LIndex;
    end;
    if FChannels[LIndex].CurNote = 0 then // empty channel
    begin
      Result := LIndex;
      Break;
    end;
  end;
  if FChannels[Result].CurSample = ASampleId then
    ASameSample := True
  else
    FChannels[Result].CurSample := Byte(ASampleId);
  FChannels[Result].Duration := 0;
end;

procedure TXcomAdlibSequencer.AdlibPlayNote(ANote, AVolume, AInstrument: Integer);
var
  LSampleId: Integer;
  LSample: Integer;
  LChannel: Integer;
  LAmplitude: Integer;
  LOperator: Integer;
  LSameSample: Boolean;
  LFreq: Integer;
  LHiFreq: Integer;
  LIndex: Integer;
  LVolume: Integer;

  function SampleByte(AOffset: Integer): Integer;
  var
    LPosition: Integer;
  begin
    LPosition := LSample + AOffset;
    Result := ReadByte(LPosition);
  end;

begin
  // adlib_play_note: starts playing note of particular instrument
  LVolume := AVolume;
  LSameSample := False;
  LSampleId := FInstruments[AInstrument].SampleId;
  LSample := FSamplesAddress + LSampleId * XCOM_ADLIB_SAMPLE_BYTES;
  Dec(ANote);
  if LVolume = 0 then // stop note
  begin
    for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
      if (FChannels[LIndex].CurNote = ANote) and (FChannels[LIndex].CurInstrument = AInstrument) then
      begin
        FChannels[LIndex].CurNote := 0; // clear channel
        AdlibReg($B0 + LIndex, FChannels[LIndex].HiFreq); // mute note
      end;
    Exit;
  end;
  if LVolume > 127 then
    LVolume := 127;
  LChannel := AdlibGetUnusedChannel(LSampleId, LSameSample);
  FChannels[LChannel].CurVolume := Byte(LVolume);
  FChannels[LChannel].CurNote := Byte(ANote);
  FChannels[LChannel].CurInstrument := Byte(AInstrument);
  LOperator := XCOM_ADLIB_OPERATORS[LChannel];
  if not LSameSample then
  begin
    AdlibReg($20 + LOperator, SampleByte(0)); // amp mod / vibrato / eg type
    AdlibReg($23 + LOperator, SampleByte(1)); // key scaling / multiple
    LAmplitude := SampleByte(2);
    AdlibReg($40 + LOperator, ((not LAmplitude) and $3F) or (LAmplitude and $C0)); // amplitude op1
  end;

  AdlibReg($B0 + LChannel, FChannels[LChannel].HiFreq); // reinit note
  AdlibReg($43 + LOperator, (not Sar(FTmpMusicVolume * LVolume, 8)) and $3F); // amplitude op2

  if not LSameSample then
  begin
    AdlibReg($60 + LOperator, SampleByte(4)); // attack rate/decay rate
    AdlibReg($63 + LOperator, SampleByte(5));
    AdlibReg($80 + LOperator, SampleByte(6)); // sustain level / release rate
    AdlibReg($83 + LOperator, SampleByte(7));
    AdlibReg($E0 + LOperator, SampleByte(8)); // wave select
    AdlibReg($E3 + LOperator, SampleByte(9));
    AdlibReg($C0 + LChannel, SampleByte(10) xor $01); // feedback strength / connection type
  end;

  LFreq := GetPitchedFreqInstr(ANote, AInstrument);
  FChannels[LChannel].CurFreq := Byte(LFreq);
  AdlibReg($A0 + LChannel, LFreq and $FF);
  LHiFreq := (LFreq shr 8) or (XCOM_ADLIB_OCTAVES[ANote] shl 2);
  FChannels[LChannel].HiFreq := Byte(LHiFreq);
  AdlibReg($B0 + LChannel, LHiFreq or $20); // reinit note
end;

procedure TXcomAdlibSequencer.Mute;
begin
  // func_mute: instantly stops music
  FPolyphonyLevel := 0;
  FMusicPlaying := False;
  AdlibResetChannels;
end;

procedure TXcomAdlibSequencer.FadeVolumeIfNeed;
var
  LIndex: Integer;
begin
  // fade_volume_if_need: decrease volume until 0 with each call, and then stops music
  if not FWantFade then
    Exit;
  Dec(FTmpMusicVolume);
  if FTmpMusicVolume = 0 then
  begin
    Mute;
    FWantFade := False;
    FTmpMusicVolume := FMasterMusicVolume;
    Exit;
  end;
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
    AdlibSetAmplitude(LIndex, Sar(FChannels[LIndex].CurVolume * FTmpMusicVolume, 7));
end;

function TXcomAdlibSequencer.FreeChannelAvailable: Boolean;
var
  LIndex: Integer;
begin
  // free_channel_available: checks if there are unused adlib channels
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
    if FChannels[LIndex].CurNote = 0 then
      Exit(True);
  Result := False;
end;

function TXcomAdlibSequencer.ChorusOf(AInstrument: Integer): Integer;
begin
  Result := FChorusInstruments[AInstrument];
  if Result >= XCOM_ADLIB_INSTRUMENTS then
    Fail(Format('The chorus instrument %d does not exist', [Result]));
end;

function TXcomAdlibSequencer.DecodeOp(AInstrument: Integer; var AAnotherLoop: Boolean): Integer;
var
  LMusicPtr: Integer;
  LOpcode: Integer;
  LArg1: Integer;
  LArg2: Integer;
  LVolume: Integer;
  LChorus: Integer;
begin
  // decode_op: main decode function - reads data from stream and decodes it accordingly
  LMusicPtr := FInstruments[AInstrument].CurAddress;
  repeat
    LOpcode := ReadByte(LMusicPtr);
    if LOpcode = $FE then // call for subtrack
    begin
      LArg1 := ReadByte(LMusicPtr);
      FInstruments[AInstrument].ReturnAddress := LMusicPtr;
      if LArg1 >= FSubtracksCount then
        Fail(Format('The subtrack %d does not exist (the song has %d)', [LArg1, FSubtracksCount]));
      LMusicPtr := FSubtracks[LArg1];
    end
    else if LOpcode = $FD then // return from subtrack
    begin
      if FInstruments[AInstrument].ReturnAddress <> -1 then
      begin
        LMusicPtr := FInstruments[AInstrument].ReturnAddress;
        FInstruments[AInstrument].ReturnAddress := -1;
      end;
      // else: DOUBLE RETURN - ERROR, the C ignores it
    end
    else if LOpcode = $FF then // finishing track
    begin
      FMusicPlaying := False;
      Result := 0;
      Break;
    end
    else if LOpcode >= $80 then // opcode
    begin
      FInstruments[AInstrument].PrevCmd := Byte(LOpcode);
      LOpcode := ReadByte(LMusicPtr); // read "repeated" opcode which goes to arg
    end;

    if LOpcode < $80 then // can be not a opcode, just the repeated command
    begin
      LArg1 := LOpcode;
      LOpcode := FInstruments[AInstrument].PrevCmd;
      case LOpcode and $F0 of
        $80: // note off
          begin
            ReadByte(LMusicPtr);
            AdlibPlayNote(LArg1, 0, AInstrument);
            Dec(FPolyphonyLevel);
            if FChorusInstruments[AInstrument] <> 0 then
            begin
              AdlibPlayNote(LArg1, 0, ChorusOf(AInstrument));
              Dec(FPolyphonyLevel);
            end;
          end;
        $90: // note on
          begin
            LArg2 := ReadByte(LMusicPtr);
            if LArg2 = 0 then // volume==0 - note off
            begin
              AdlibPlayNote(LArg1, 0, AInstrument);
              Dec(FPolyphonyLevel);
              if FChorusInstruments[AInstrument] <> 0 then
              begin
                AdlibPlayNote(LArg1, 0, ChorusOf(AInstrument));
                Dec(FPolyphonyLevel);
              end;
            end
            else
            begin
              LVolume := Sar(LArg2 * FInstruments[AInstrument].Volume, 7);
              if FChorusInstruments[AInstrument] <> 0 then
              begin
                if FreeChannelAvailable then
                begin
                  LChorus := ChorusOf(AInstrument);
                  FInstruments[LChorus].SampleId := FInstruments[AInstrument].SampleId;
                  FInstruments[LChorus].CurPitchBend := SmallInt(FInstruments[AInstrument].CurPitchBend - 1);
                  AdlibPlayNote(LArg1, LVolume, LChorus);
                end;
                Inc(FPolyphonyLevel); // increase it nevertheless, because it SHOULD play
              end;
              AdlibPlayNote(LArg1, LVolume, AInstrument);
              Inc(FPolyphonyLevel);
            end;
          end;
        $B0: // set controller
          begin
            LArg2 := ReadByte(LMusicPtr);
            if (LArg1 = 0) and (LArg2 <> 0) then // tempo change
              FTempo := Trunc(Double(LArg2) * TEMPO_CONTROLLER_SCALE)
            else if LArg1 = 7 then // channel volume change
              FInstruments[AInstrument].Volume := Byte(LArg2)
            else if LArg1 = $7E then // setting up chorus (slave) instrument
              FChorusInstruments[AInstrument] := Byte(LArg2 - 1)
            else if LArg1 = $7F then // clearing chorus (slave) instrument
              FChorusInstruments[AInstrument] := 0;
          end;
        $C0: // set sample
          if LArg1 = $7E then
            AAnotherLoop := True
          else
            FInstruments[AInstrument].SampleId := Byte(LArg1);
        $E0: // pitch bend
          begin
            FInstruments[AInstrument].CurPitchBend := SmallInt(LArg1 - 16); // no need???
            AdlibSetInstrumentPitch(AInstrument, LArg1 - 16);
            if FChorusInstruments[AInstrument] <> 0 then
              AdlibSetInstrumentPitch(ChorusOf(AInstrument), LArg1 - 17);
          end;
      end;
    end;
    Result := GetNumSeq(LMusicPtr);
  until Result <> 0;
  FInstruments[AInstrument].CurAddress := LMusicPtr;
end;

procedure TXcomAdlibSequencer.InitMusicData(ALength: Integer);
var
  LPtr: Integer;
  LIndex: Integer;
  LToAdd: Integer;
  LInstrument: Integer;
  LFirst: Integer;
begin
  // init_music_data: music initialization function, sets up subblock array, tempo, instrument addresses and samples
  for LIndex := 0 to XCOM_ADLIB_INSTRUMENTS - 1 do
    FInstruments[LIndex].StartAddress := -1;
  FSubtracksCount := 0;

  LPtr := 0;
  LFirst := ReadByte(LPtr);
  LPtr := 0;
  if LFirst > 56 then
    FFormat := 0 // switch to old
  else
    FFormat := 1;
  if FFormat = 1 then
    Inc(LPtr, LFirst + 1); // skip name
  FTempo := ReadByte(LPtr);
  FSamplesAddress := LPtr + 1; // samples
  LIndex := LPtr;
  Inc(LPtr, ReadByte(LIndex) * XCOM_ADLIB_SAMPLE_BYTES + 1); // moving to next section - subtracks
  FSubtracksCount := ReadByte(LPtr);
  if FSubtracksCount > XCOM_ADLIB_MAX_SUBTRACKS then
    Fail(Format('The song has %d subtracks (at most %d)', [FSubtracksCount, XCOM_ADLIB_MAX_SUBTRACKS]));
  for LIndex := 0 to FSubtracksCount - 1 do
  begin
    LToAdd := PeekWord(LPtr); // reading 16bit length
    FSubtracks[LIndex] := LPtr + 4; // store subtrack pointers
    Inc(LPtr, LToAdd);
  end;
  FInstrumentsCount := ReadByte(LPtr);
  for LIndex := 0 to FInstrumentsCount - 1 do
  begin
    LToAdd := PeekWord(LPtr); // reading 16bit length
    if FFormat = 1 then
    begin
      if LPtr + 4 >= Length(FData) then
        Fail('The song ends inside a track header');
      LInstrument := FData[LPtr + 4];
      if LInstrument > 15 then
        LInstrument := 15;
      FInstruments[LInstrument].StartAddress := LPtr + 5;
    end
    else
    begin
      LInstrument := LIndex;
      if LInstrument >= XCOM_ADLIB_INSTRUMENTS then
        Fail(Format('The old format song has %d tracks (at most %d)', [FInstrumentsCount, XCOM_ADLIB_INSTRUMENTS]));
      FInstruments[LInstrument].StartAddress := LPtr + 4; // old format, without title
    end;
    Inc(LPtr, LToAdd);
    if LPtr >= ALength then
      Break; // DATA ERROR: the track goes past the end
  end;
end;

procedure TXcomAdlibSequencer.InitMusic;
var
  LIndex: Integer;
  LAddress: Integer;
begin
  // init_music: initialize music tracks, prepare for playing
  for LIndex := 0 to XCOM_ADLIB_INSTRUMENTS - 1 do
  begin
    FInstruments[LIndex].CurPitchBend := 0;
    FChorusInstruments[LIndex] := 0;
    if FInstruments[LIndex].StartAddress <> -1 then
    begin
      LAddress := FInstruments[LIndex].StartAddress;
      FInstruments[LIndex].CurAddress := LAddress;
      FInstruments[LIndex].CurDelay := GetNumSeq(LAddress);
      FInstruments[LIndex].CurAddress := LAddress;
    end
    else
    begin
      FInstruments[LIndex].CurAddress := -1;
      FInstruments[LIndex].CurDelay := 0;
    end;
  end;
end;

procedure TXcomAdlibSequencer.SaveState(AIndex: Integer);
begin
  // func_save_music_state
  if (AIndex < 0) or (AIndex > 1) then
    raise EXcomAdlibException.CreateFmt('The music state %d does not exist (0 and 1 do)', [AIndex]);
  FSavedInstruments[AIndex] := FInstruments;
  FSavedGeneration[AIndex] := FSongGeneration;
end;

procedure TXcomAdlibSequencer.LoadState(AIndex: Integer);
begin
  // func_load_music_state
  if (AIndex < 0) or (AIndex > 1) then
    raise EXcomAdlibException.CreateFmt('The music state %d does not exist (0 and 1 do)', [AIndex]);
  // the addresses of a state point into the song it was taken in; the C goes on reading the memory of that song
  // (and crashes if it is gone), here the state of another song is refused
  if (FSavedGeneration[AIndex] <> 0) and (FSavedGeneration[AIndex] <> FSongGeneration) then
    raise EXcomAdlibException.CreateFmt('The music state %d was saved with another song', [AIndex]);
  AdlibResetChannels;
  FInstruments := FSavedInstruments[AIndex];
end;

procedure TXcomAdlibSequencer.Tick;
var
  LAnotherLoop: Boolean;
  LIndex: Integer;
  LInstrument: Integer;
begin
  // func_play_tick: runs 1 tick of music according tempo
  if not FMusicPlaying then
    Exit;
  FadeVolumeIfNeed;
  Dec(FTempoRun, FTempo);
  if FTempoRun > 0 then
    Exit;
  Inc(FTempoRun, FTempoInc);

  repeat
    LAnotherLoop := False;
    for LIndex := 0 to XCOM_ADLIB_INSTRUMENTS - 1 do
    begin
      LInstrument := XCOM_ADLIB_INSTRUMENT_ORDER[LIndex];
      if FInstruments[LInstrument].CurAddress = -1 then
        Continue;
      if FInstruments[LInstrument].CurDelay = 0 then
      begin
        FInstruments[LInstrument].CurDelay := DecodeOp(LInstrument, LAnotherLoop);
        if not FMusicPlaying then
          Break;
      end;
      Dec(FInstruments[LInstrument].CurDelay);
    end;
    if (not LAnotherLoop) and FMusicPlaying then
      Break;
    InitMusic;
    ClearChannels;
  until not LAnotherLoop;
end;

procedure TXcomAdlibSequencer.Setup(const ASong: TBytes; ALength: Integer);
begin
  // func_setup_music: setup music for playing
  if Length(ASong) = 0 then
    raise EXcomAdlibException.Create('The song is empty');
  if (Length(FData) <> Length(ASong)) or not CompareMem(FData, ASong, Length(ASong)) then
    Inc(FSongGeneration);
  FData := Copy(ASong);
  FMusicPlaying := False;
  Mute;
  FPolyphonyLevel := 0;
  FWantFade := False;
  FTmpMusicVolume := FMasterMusicVolume;
  InitMusicData(ALength);
  InitMusic;
  AdlibInit;
  AdlibResetChannels;
  FTempo := Trunc(Double(FTempo) * TEMPO_SETUP_SCALE);
  FTempoRun := FTempo;
  FMusicPlaying := True;
end;

procedure TXcomAdlibSequencer.Fade;
begin
  // func_fade: initialize fade procedure
  if FTmpMusicVolume = 0 then
    Mute
  else
    FWantFade := True;
end;

function TXcomAdlibSequencer.IsPlaying: Boolean;
begin
  Result := FMusicPlaying;
end;

procedure TXcomAdlibSequencer.SetTempo(AValue: Integer);
begin
  FTempoInc := AValue;
end;

procedure TXcomAdlibSequencer.SetVolume(AValue: Integer);
var
  LIndex: Integer;
begin
  // func_set_music_volume
  FMasterMusicVolume := AValue;
  FTmpMusicVolume := FMasterMusicVolume;
  for LIndex := 0 to XCOM_ADLIB_CHANNELS - 1 do
    AdlibSetAmplitude(LIndex, Sar(FChannels[LIndex].CurVolume * FTmpMusicVolume, 7));
end;

function TXcomAdlibSequencer.Polyphony: Integer;
begin
  Result := FPolyphonyLevel;
end;

end.
