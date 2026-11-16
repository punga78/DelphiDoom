{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the samples of the sound effects                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Audio.SfxSampleSource;

interface

uses
  d_delphi,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Audio.Types,
  DelphiDoom.Audio.Intf,
  DelphiDoom.Audio.SoundParameters;

type
  /// <summary>
  ///   The cache of the samples of the sound effects (I_CacheSFX of the old i_sound): with
  ///   useexternalwav a file out of the WAD (OGG, FLAC, VOC, AU converted to WAV, or a WAV with
  ///   the name of the sound, with or without "ds"), else the lump of the WAD (DMX, a WAV, or a
  ///   compressed sound converted to WAV). The samples stay in the zone memory (PU_SOUND) on the
  ///   data of S_sfx; the format of every sound is kept here. The headers are read by
  ///   TSfxWaveParser of the audio library
  /// </summary>
  TEngineSfxSampleSource = class(TInterfacedObject, ISfxSampleSource)
  strict private
    FLog: ILog;
    FParameters: TArray<TSfxSoundParameters>;
    function ParametersOf(ASoundId: Integer): Integer;
    function OpenExternalFile(const AName: string; out AStream: TDStream): Boolean;
    procedure Cache(ASoundId: Integer);
  public
    /// <summary>The problems of the headers go to ALog; EArgumentNilException if it is nil</summary>
    constructor Create(const ALog: ILog);
    function Load(ASoundId: Integer): TSfxSample;
    procedure DiscardExternal(ASoundId: Integer);
    procedure StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
    function NameOf(ASoundId: Integer): string;
  end;

implementation

uses
  System.SysUtils,
{$IFNDEF DLL}
  DelphiDoom.Audio.SoundLibrary, // JVAL: 20210117 - Search for various sound formats
{$ENDIF}
  DelphiDoom.Audio.WaveParser,
  doomdef,
  i_system,
  s_sound,
  sounddata,
  w_folders,
  w_pak,
  w_wad,
  z_zone;

const
  SLogIsNil = 'TEngineSfxSampleSource.Create(): ALog is nil';

{$IFNDEF DLL}
  // the compressed sounds of a lump that become a WAV
  CS_fLac = 1130450022; // fLac
  CS_OggS = 1399285583; // OggS
  CS_CVoc = 1634038339; // Crea
{$ENDIF}

{ TEngineSfxSampleSource }

constructor TEngineSfxSampleSource.Create(const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALog) then
    raise EArgumentNilException.Create(SLogIsNil);
  FLog := ALog;
end;

function TEngineSfxSampleSource.ParametersOf(ASoundId: Integer): Integer;
begin
  // a new sound starts with NoWave and zeros (the old array grew with realloc)
  if ASoundId >= Length(FParameters) then
    SetLength(FParameters, ASoundId + 1);
  Result := ASoundId;
end;

function TEngineSfxSampleSource.OpenExternalFile(const AName: string; out AStream: TDStream): Boolean;
var
  LNames: array[0..1] of string;
  LIndex: Integer;
  LStream: TPakStream;
begin
  // JVAL: 20210117 - Search for various sound formats
{$IFNDEF DLL}
  if Audiolib_SearchSoundPAK(AName, AStream, 0) then
    Exit(True);
{$ENDIF}
  AStream := nil;
  LNames[0] := 'ds' + AName + '.wav';
  LNames[1] := AName + '.wav';
  for LIndex := 0 to High(LNames) do
  begin
    if preferewavnamesingamedirectory then
      LStream := TPakStream.Create(LNames[LIndex], pm_prefered, gamedirectories)
    else
      LStream := TPakStream.Create(LNames[LIndex], pm_short, '', FOLDER_SOUNDS);
    LStream.OnBeginBusy := I_BeginDiskBusy;
    if LStream.IOResult = 0 then
    begin
      AStream := LStream;
      Exit(True);
    end;
    LStream.Free;
  end;
  Result := False;
end;

function ReadAll(AStream: TDStream): TBytes;
begin
  SetLength(Result, AStream.Size);
  AStream.Seek(0, sFromBeginning);
  if Length(Result) > 0 then
    AStream.Read(Result[0], Length(Result));
end;

procedure TEngineSfxSampleSource.Cache(ASoundId: Integer);
var
  LSfx: Psfxinfo_t;
  LIndex: Integer;
  LStream: TDStream;
  LBytes: TBytes;
  LFound: Boolean;
  LChunks: TSfxWaveChunks;
  LName: string;
  LLump: Integer;
  LLength: Integer;
begin
  LSfx := @S_sfx[ASoundId];
  if LSfx.data <> nil then
    Exit;

  LIndex := ParametersOf(ASoundId);
  FillChar(LChunks, SizeOf(LChunks), 0);
  LFound := False;

  if useexternalwav and (FParameters[LIndex].Status <> TSfxWaveStatus.WaveFailed) then
    if OpenExternalFile(LSfx.name, LStream) then
    begin
      try
        LBytes := ReadAll(LStream);
      finally
        LStream.Free;
      end;
      LFound := TSfxWaveParser.ParseFile(LBytes, LSfx.name, FLog, LChunks);
      if LChunks.DataFound then
      begin
        LSfx.data := Z_Malloc(LChunks.DataLength, PU_SOUND, @LSfx.data);
        if LChunks.DataLength > 0 then
          Move(LBytes[LChunks.DataOffset], LSfx.data^, LChunks.DataLength);
      end;
      FParameters[LIndex].ApplyFile(LChunks, LFound);
      // a file that is not good gives the lump: the old code left its samples in the zone
      if not LFound and (LSfx.data <> nil) then
      begin
        Z_Free(LSfx.data);
        LSfx.data := nil;
      end;
    end;

  if LFound then
    Exit;

  if LSfx.lumpnum = -1 then
  begin
    // Get the sound data from the WAD, allocate lump
    //  in zone memory.
    // Now, there is a severe problem with the sound handling, in it is not (yet/anymore)
    //  gamemode aware. That means, sounds from DOOM II will be requested even with DOOM
    //  shareware. Instead, we will use a default sound for replacement.
    LName := 'ds' + LSfx.name;
    LLump := -1;
    if Length(LName) <= 8 then
      LLump := W_CheckNumForName(LName);

    if LLump = -1 then // JVAL Search without the DS prefix
      LLump := W_CheckNumForName(LSfx.name);

    if LLump = -1 then
      LSfx.lumpnum := W_GetNumForName('dspistol')
    else
      LSfx.lumpnum := LLump;
  end;

  LSfx.data := W_CacheLumpNum(LSfx.lumpnum, PU_SOUND);
  LLength := W_LumpLength(LSfx.lumpnum);
{$IFNDEF DLL}
  if (LLength >= SizeOf(Cardinal)) and ((PCardinal(LSfx.data)^ = CS_fLac) or
    (PCardinal(LSfx.data)^ = CS_OggS) or (PCardinal(LSfx.data)^ = CS_CVoc)) then
    Audiolib_DecodeSoundWAD(LSfx.data, LLength, @LSfx.data, LLength, 1);
{$ENDIF}
  LFound := TSfxWaveParser.ParseLump(LSfx.data, LLength, LSfx.name, FLog, LChunks);
  FParameters[LIndex].ApplyLump(LChunks, LFound);
end;

function TEngineSfxSampleSource.Load(ASoundId: Integer): TSfxSample;
begin
  Cache(ASoundId);
  Result := FParameters[ParametersOf(ASoundId)].ToSample(System.PByte(S_sfx[ASoundId].data));
end;

procedure TEngineSfxSampleSource.DiscardExternal(ASoundId: Integer);
begin
  FParameters[ParametersOf(ASoundId)].Status := TSfxWaveStatus.WaveFailed;
  Z_Free(S_sfx[ASoundId].data);
  S_sfx[ASoundId].data := nil;
end;

procedure TEngineSfxSampleSource.StoreAverageBytes(ASoundId: Integer; AAverageBytes: Cardinal);
begin
  FParameters[ParametersOf(ASoundId)].Format.AverageBytesPerSecond := AAverageBytes;
end;

function TEngineSfxSampleSource.NameOf(ASoundId: Integer): string;
begin
  Result := S_sfx[ASoundId].name;
end;

end.
