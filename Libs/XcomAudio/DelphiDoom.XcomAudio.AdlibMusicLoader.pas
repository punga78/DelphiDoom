{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom audio library - the Adlib format of the music (ADLIB.CAT    }
{  and AINTRO.CAT: the MUSIC_ADLIB branch of Mod::loadMusic)                    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAudio.AdlibMusicLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomAdlib.Intf, DelphiDoom.XcomAudio.Intf,
  DelphiDoom.XcomAudio.Types;

type
  /// <summary>Makes the player of the Adlib (two chips) the Adlib tracks share</summary>
  TXcomAdlibPlayerFactory = reference to function: IXcomAdlibPlayer;

  /// <summary>The songs of the Adlib containers of the game data in use</summary>
  TXcomAdlibSongsFactory = reference to function(const AResources: IXcomResources): IXcomAdlibSongs;

  /// <summary>
  ///   The Adlib music: the song of the rule is the catPos-th of ADLIB.CAT, or of AINTRO.CAT after the last one. The
  ///   player of the two chips is made the first time it is needed and shared, as the two globals of the C++
  /// </summary>
  TXcomAdlibMusicLoader = class(TInterfacedObject, IXcomMusicFormatLoader)
  strict private
    FSettings: IXcomMusicSettings;
    FAdlibPlayerFactory: TXcomAdlibPlayerFactory;
    FSongsFactory: TXcomAdlibSongsFactory;
    FSongs: IXcomAdlibSongs;
    FAdlibPlayer: IXcomAdlibPlayer;
  public
    constructor Create(const ASettings: IXcomMusicSettings; const AAdlibPlayerFactory: TXcomAdlibPlayerFactory;
      const ASongsFactory: TXcomAdlibSongsFactory);
    function Format: TXcomMusicFormat;
    procedure Reload(const AResources: IXcomResources);
    function Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
  end;

implementation

uses
  DelphiDoom.XcomAudio.AdlibTrack;

constructor TXcomAdlibMusicLoader.Create(const ASettings: IXcomMusicSettings;
  const AAdlibPlayerFactory: TXcomAdlibPlayerFactory; const ASongsFactory: TXcomAdlibSongsFactory);
begin
  inherited Create;
  if not Assigned(ASettings) then
    raise EArgumentNilException.Create('ASettings');
  FSettings := ASettings;
  FAdlibPlayerFactory := AAdlibPlayerFactory;
  FSongsFactory := ASongsFactory;
end;

function TXcomAdlibMusicLoader.Format: TXcomMusicFormat;
begin
  Result := mfAdlib;
end;

procedure TXcomAdlibMusicLoader.Reload(const AResources: IXcomResources);
begin
  FSongs := nil;
  if Assigned(FSongsFactory) then
    FSongs := FSongsFactory(AResources);
end;

function TXcomAdlibMusicLoader.Load(const ARule: TXcomMusicRule): IXcomMusicTrack;
var
  LTrack: Integer;
  LSong: TBytes;
begin
  Result := nil;
  if (FSongs = nil) or (FSongs.Count = 0) or (ARule.CatPos < 0) then
    Exit;
  LTrack := ARule.CatPos;
  if LTrack < FSongs.Count then
    LSong := FSongs.Song(LTrack)
  else
  begin
    Dec(LTrack, FSongs.Count);
    if LTrack >= FSongs.IntroCount then
      Exit;
    LSong := FSongs.IntroSong(LTrack);
  end;
  if Length(LSong) = 0 then
    Exit;
  if FAdlibPlayer = nil then
    FAdlibPlayer := FAdlibPlayerFactory();
  Result := TXcomAdlibTrack.Create(FAdlibPlayer, FSettings, LSong, ARule.Normalization);
end;

end.
