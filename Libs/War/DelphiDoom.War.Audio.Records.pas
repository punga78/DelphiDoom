{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the sounds and songs of DATA.WAR                  }
{                                                                              }
{  Port of wres_loadXmi, wres_loadWave and wres_loadVoc of war_resources.c,    }
{  war1 (acoto87/war1), (c) 2019 Alejandro Coto Gutierrez, zlib License (see   }
{  Libs\War\LICENSE-war1.txt). This is an altered version, not the original.   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Audio.Records;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Types, DelphiDoom.War.Intf,
  DelphiDoom.War.Audio.Types, DelphiDoom.War.Audio.Intf;

type
  /// <summary>
  ///   What a record is comes from the catalog (the table audioData of war_audio.c lists the same records: XMID is
  ///   MIDI, WAVE and VOC are sounds). A sound is decoded and resampled the first time it is asked for and kept;
  ///   the library is for the thread of the game, not for the audio thread
  /// </summary>
  TWarAudioLibrary = class(TInterfacedObject, IWarAudioLibrary)
  strict private
    FArchive: IWarArchive;
    FCatalog: IWarCatalog;
    FConverter: IWarMusicConverter;
    FSounds: TDictionary<Integer, TWarPcmBuffer>;
  public
    constructor Create(const AArchive: IWarArchive; const ACatalog: IWarCatalog; const AConverter: IWarMusicConverter);
    destructor Destroy; override;
    function KindOf(AIndex: Integer): TWarAudioKind;
    function GetSound(AIndex: Integer): TWarPcmBuffer;
    function GetMusic(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.War.Audio.VocDecoder, DelphiDoom.War.Audio.WavDecoder, DelphiDoom.War.Audio.Resampler;

{ TWarAudioLibrary }

constructor TWarAudioLibrary.Create(const AArchive: IWarArchive; const ACatalog: IWarCatalog;
  const AConverter: IWarMusicConverter);
begin
  inherited Create;
  if not (Assigned(AArchive) and Assigned(ACatalog) and Assigned(AConverter)) then
    raise EWarException.Create('The archive, the catalog and the converter of the audio library are needed');
  FArchive := AArchive;
  FCatalog := ACatalog;
  FConverter := AConverter;
  FSounds := TDictionary<Integer, TWarPcmBuffer>.Create;
end;

destructor TWarAudioLibrary.Destroy;
begin
  FSounds.Free;
  inherited;
end;

function TWarAudioLibrary.KindOf(AIndex: Integer): TWarAudioKind;
begin
  case FCatalog.RecordTypeOf(AIndex) of
    wrtXmid: Result := wakMidi;
    wrtWave, wrtVoc: Result := wakWave;
  else
    raise EWarException.CreateFmt(SWarAudioNotSound, [AIndex]);
  end;
end;

function TWarAudioLibrary.GetSound(AIndex: Integer): TWarPcmBuffer;
var
  LRaw: TBytes;
  LDecoded: TWarPcmBuffer;
  LDecodedOk: Boolean;
begin
  if FSounds.TryGetValue(AIndex, Result) then
    Exit;
  case FCatalog.RecordTypeOf(AIndex) of
    wrtVoc:
      begin
        LRaw := FArchive.ReadRecord(AIndex);
        LDecodedOk := TWarVocDecoder.TryDecode(LRaw, LDecoded);
      end;
    wrtWave:
      begin
        LRaw := FArchive.ReadRecord(AIndex);
        LDecodedOk := TWarWavDecoder.TryDecode(LRaw, LDecoded);
      end;
  else
    raise EWarException.CreateFmt(SWarAudioNotSound, [AIndex]);
  end;
  if not LDecodedOk then
    raise EWarException.CreateFmt(SWarAudioBadSound, [AIndex]);
  Result := TWarPcmResampler.Resample(LDecoded, WAR_PLAYBACK_RATE);
  FSounds.Add(AIndex, Result);
end;

function TWarAudioLibrary.GetMusic(AIndex: Integer): TBytes;
begin
  if FCatalog.RecordTypeOf(AIndex) <> wrtXmid then
    raise EWarException.CreateFmt(SWarAudioNotMusic, [AIndex]);
  if not FConverter.TryConvert(FArchive.ReadRecord(AIndex), Result) then
    raise EWarException.CreateFmt(SWarAudioBadMusic, [AIndex]);
end;

end.
