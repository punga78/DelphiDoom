{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the MIDI formats of the music (MUSIC_GM:    }
{  the songs of GM.CAT, and MUSIC_MIDI: a .mid file of the SOUND folder)        }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.MidiMusicLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.Xcom.Intf, DelphiDoom.XcomAudio.Intf,
  DelphiDoom.XcomAudio.Types;

type
  /// <summary>
  ///   mfGm: the catPos-th entry of GM.CAT, converted to a MIDI file (GMCatFile::loadMIDI: an entry that is not valid
  ///   is a music that does not play, and it stops the search of formats as in the C++); mfMidi: name.mid
  /// </summary>
  TXcomMidiMusicLoader = class(TInterfacedObject, IXcomMusicFormatLoader)
  strict private
    FFormat: TXcomMusicFormat;
    FRate: Integer;
    FSynth: IXcomMidiSynth;
    FResources: IXcomResources;
    FCatalog: IXcomCatArchive;
  public
    /// <param name="AFormat">mfGm or mfMidi</param>
    /// <param name="ASynth">The synthesizer the tracks share; EArgumentNilException when nil</param>
    constructor Create(AFormat: TXcomMusicFormat; ARate: Integer; const ASynth: IXcomMidiSynth);
    function Format: TXcomMusicFormat;
    procedure Reload(const AResources: IXcomResources);
    function Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
  end;

implementation

uses
  DelphiDoom.Xcom.Types, DelphiDoom.Xcom.CatArchive,DelphiDoom.XcomAudio.GmConverter, DelphiDoom.XcomAudio.MidiTrack;

constructor TXcomMidiMusicLoader.Create(AFormat: TXcomMusicFormat; ARate: Integer; const ASynth: IXcomMidiSynth);
begin
  inherited Create;
  if not Assigned(ASynth) then
    raise EArgumentNilException.Create('ASynth');
  if not (AFormat in [mfGm, mfMidi]) then
    raise EArgumentException.Create('AFormat');
  FFormat := AFormat;
  FRate := ARate;
  FSynth := ASynth;
end;

function TXcomMidiMusicLoader.Format: TXcomMusicFormat;
begin
  Result := FFormat;
end;

procedure TXcomMidiMusicLoader.Reload(const AResources: IXcomResources);
var
  LBytes: TBytes;
begin
  FResources := AResources;
  FCatalog := nil;
  if FFormat = mfGm then
  begin
    LBytes := AResources.SoundFile('GM.CAT');
    if Length(LBytes) >= 8 then
      try
        FCatalog := TXcomCatArchive.Create(LBytes);
      except
        // a damaged GM.CAT is no music (the C++ would not read it either)
        on EXcomDataException do
          FCatalog := nil;
      end;
  end;
end;

function TXcomMidiMusicLoader.Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
var
  LBytes: TBytes;
begin
  Result := nil;
  if FResources = nil then
    Exit;
  if FFormat = mfGm then
  begin
    if (FCatalog = nil) or (ARule.CatPos < 0) or (ARule.CatPos >= FCatalog.Count) then
      Exit;
    try
      LBytes := TXcomGmConverter.Convert(FCatalog.Load(ARule.CatPos, False));
    except
      on EXcomDataException do
        LBytes := nil;
    end;
    Result := TXcomMidiTrack.Create(LBytes, FRate, FSynth);
  end
  else
  begin
    if ARule.Name = '' then
      Exit;
    LBytes := FResources.SoundFile(LowerCase(ARule.Name) + '.mid');
    if (Length(LBytes) = 0) or not TXcomMidiTrack.Accepts(LBytes) then
      Exit;
    Result := TXcomMidiTrack.Create(LBytes, FRate, FSynth);
  end;
end;

end.
