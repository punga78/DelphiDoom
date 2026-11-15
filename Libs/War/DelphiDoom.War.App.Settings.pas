{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the settings that the program keeps               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.Settings;

interface

uses
  System.SysUtils, DelphiDoom.Configuration.Intf, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   What the player changes in the menus and expects to find again: the volumes of the music and of the effects (0 to
  ///   100) and whether each one is on. The file Warcraft32.ini is next to the program, in the format of the other
  ///   programs of the repository (Libs\Configuration)
  /// </summary>
  TWarAppSettings = record
    MusicVolume: Integer;
    SoundVolume: Integer;
    MusicEnabled: Boolean;
    SoundEnabled: Boolean;
    /// <summary>The settings of a program that has no file: the original's (full volume, everything on)</summary>
    class function Standard: TWarAppSettings; static;
    /// <summary>Takes what the game has now (the volumes are rounded to whole percents)</summary>
    class function FromGame(const AGame: IWarGameSettings): TWarAppSettings; static;
    /// <summary>Gives these settings to the game</summary>
    procedure ApplyTo(const AGame: IWarGameSettings);
    /// <summary>
    ///   The lines of the file. The header is the one of the other .ini files of the repository; the format is the
    ///   one of Libs\Configuration
    /// </summary>
    function ToLines(const AFormat: IConfigurationFormat): TArray<string>;
    /// <summary>
    ///   The settings in the lines of a file. What is missing or is not a number keeps its standard value, and a value
    ///   out of range is brought into it: an .ini that someone edited must not stop the game. False if the header is
    ///   not the one of this program (the standard settings are returned)
    /// </summary>
    class function TryFromLines(const AFormat: IConfigurationFormat; const ALines: TArray<string>;
      out ASettings: TWarAppSettings): Boolean; static;
  end;

const
  /// <summary>The name of the settings file, next to the program</summary>
  WAR_SETTINGS_FILE_NAME = 'Warcraft32.ini';
  WAR_SETTINGS_TITLE = 'Warcraft32';
  // the versions that Libs\Configuration accepts start at 1.10 (CONFIGURATION_OLDEST_VERSION)
  WAR_SETTINGS_VERSION = 110;

implementation

uses
  System.Math;

const
  KEY_MUSIC_VOLUME = 'musicvolume';
  KEY_SOUND_VOLUME = 'soundvolume';
  KEY_MUSIC_ENABLED = 'music';
  KEY_SOUND_ENABLED = 'sound';

{ TWarAppSettings }

class function TWarAppSettings.Standard: TWarAppSettings;
begin
  Result.MusicVolume := 100;
  Result.SoundVolume := 100;
  Result.MusicEnabled := True;
  Result.SoundEnabled := True;
end;

class function TWarAppSettings.FromGame(const AGame: IWarGameSettings): TWarAppSettings;
begin
  Result.MusicVolume := EnsureRange(Round(AGame.MusicVolume * 100), 0, 100);
  Result.SoundVolume := EnsureRange(Round(AGame.SoundVolume * 100), 0, 100);
  Result.MusicEnabled := AGame.MusicEnabled;
  Result.SoundEnabled := AGame.SoundEnabled;
end;

procedure TWarAppSettings.ApplyTo(const AGame: IWarGameSettings);
begin
  AGame.SetMusicVolume(MusicVolume / 100);
  AGame.SetSoundVolume(SoundVolume / 100);
  AGame.MusicEnabled := MusicEnabled;
  AGame.SoundEnabled := SoundEnabled;
end;

function TWarAppSettings.ToLines(const AFormat: IConfigurationFormat): TArray<string>;
var
  LWriter: IConfigurationWriter;
begin
  LWriter := AFormat.CreateWriter(AFormat.FormatHeader(WAR_SETTINGS_TITLE, WAR_SETTINGS_VERSION));
  LWriter.AddValue(KEY_MUSIC_VOLUME, AFormat.FormatInteger(MusicVolume));
  LWriter.AddValue(KEY_SOUND_VOLUME, AFormat.FormatInteger(SoundVolume));
  LWriter.AddValue(KEY_MUSIC_ENABLED, AFormat.FormatBoolean(MusicEnabled));
  LWriter.AddValue(KEY_SOUND_ENABLED, AFormat.FormatBoolean(SoundEnabled));
  Result := LWriter.Lines;
end;

class function TWarAppSettings.TryFromLines(const AFormat: IConfigurationFormat; const ALines: TArray<string>;
  out ASettings: TWarAppSettings): Boolean;
var
  LDocument: IConfigurationDocument;
  LText: string;
begin
  ASettings := Standard;
  // the format checks the version of the header, not whose file it is
  Result := (Length(ALines) > 0) and ALines[0].StartsWith('[' + WAR_SETTINGS_TITLE + ' ') and
    AFormat.AcceptsHeader(ALines[0], WAR_SETTINGS_VERSION);
  if not Result then
    Exit;
  LDocument := AFormat.Parse(ALines);
  LText := LDocument.ValueOf(KEY_MUSIC_VOLUME);
  if LText <> '' then
    ASettings.MusicVolume := EnsureRange(AFormat.ParseInteger(LText), 0, 100);
  LText := LDocument.ValueOf(KEY_SOUND_VOLUME);
  if LText <> '' then
    ASettings.SoundVolume := EnsureRange(AFormat.ParseInteger(LText), 0, 100);
  LText := LDocument.ValueOf(KEY_MUSIC_ENABLED);
  if LText <> '' then
    ASettings.MusicEnabled := AFormat.ParseBoolean(LText);
  LText := LDocument.ValueOf(KEY_SOUND_ENABLED);
  if LText <> '' then
    ASettings.SoundEnabled := AFormat.ParseBoolean(LText);
end;

end.
