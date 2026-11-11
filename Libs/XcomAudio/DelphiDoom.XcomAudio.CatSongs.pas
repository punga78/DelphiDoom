{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the songs of ADLIB.CAT and AINTRO.CAT       }
{  (what Mod::loadExtraResources opens before it loads the musics)              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.CatSongs;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Intf, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomEngine.Resources.Intf,
  DelphiDoom.XcomAudio.Intf;

type
  /// <summary>IXcomAdlibSongs on two CAT containers (either can be missing)</summary>
  TXcomCatSongs = class(TInterfacedObject, IXcomAdlibSongs)
  strict private
    FAdlib: IXcomAdlibMusicSource;
    FIntro: IXcomAdlibMusicSource;
  public
    /// <param name="AAdlib">ADLIB.CAT; nil when the game has none</param>
    /// <param name="AIntro">AINTRO.CAT; nil when the game has none</param>
    constructor Create(const AAdlib, AIntro: IXcomAdlibMusicSource);
    /// <summary>Opens the containers in the SOUND folder of the data (SoundFile) and wraps them</summary>
    class function FromResources(const AResources: IXcomResources): IXcomAdlibSongs; static;
    function Count: Integer;
    function Song(AIndex: Integer): TBytes;
    function IntroCount: Integer;
    function IntroSong(AIndex: Integer): TBytes;
  end;

implementation

uses
  DelphiDoom.Xcom.CatArchive, DelphiDoom.XcomAdlib.Factory;

constructor TXcomCatSongs.Create(const AAdlib, AIntro: IXcomAdlibMusicSource);
begin
  inherited Create;
  FAdlib := AAdlib;
  FIntro := AIntro;
end;

class function TXcomCatSongs.FromResources(const AResources: IXcomResources): IXcomAdlibSongs;
var
  LAdlib: IXcomAdlibMusicSource;
  LIntro: IXcomAdlibMusicSource;
  LBytes: TBytes;
begin
  LAdlib := nil;
  LIntro := nil;
  LBytes := AResources.SoundFile('ADLIB.CAT');
  if Length(LBytes) >= 8 then
    LAdlib := TXcomAdlibFactory.CreateCatSource(TXcomCatArchive.Create(LBytes));
  LBytes := AResources.SoundFile('AINTRO.CAT');
  if Length(LBytes) >= 8 then
    LIntro := TXcomAdlibFactory.CreateCatSource(TXcomCatArchive.Create(LBytes));
  Result := TXcomCatSongs.Create(LAdlib, LIntro);
end;

function TXcomCatSongs.Count: Integer;
begin
  if FAdlib = nil then
    Result := 0
  else
    Result := FAdlib.TrackCount;
end;

function TXcomCatSongs.Song(AIndex: Integer): TBytes;
begin
  Result := FAdlib.LoadTrackWithName(AIndex);
end;

function TXcomCatSongs.IntroCount: Integer;
begin
  if FIntro = nil then
    Result := 0
  else
    Result := FIntro.TrackCount;
end;

function TXcomCatSongs.IntroSong(AIndex: Integer): TBytes;
begin
  Result := FIntro.LoadTrackWithName(AIndex);
end;

end.
