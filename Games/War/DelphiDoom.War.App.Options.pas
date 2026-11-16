{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the options of the program Warcraft32             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.App.Options;

interface

uses
  DelphiDoom.War.Level.Types;

type
  /// <summary>
  ///   What the command line of Warcraft32 asks for. The record has no behavior: TWarAppOptionsParser fills it, the
  ///   composition root of the program reads it
  /// </summary>
  TWarAppOptions = record
    /// <summary>-data: the folder with DATA.WAR (or with its folder DATA); empty is the folder of the program</summary>
    DataFolder: string;
    /// <summary>-fonts: the folder with war1_font_1.png and war1_font_2.png; empty is the data folder and what is near it</summary>
    FontFolder: string;
    /// <summary>-headless: no window, no sound device, no clock: a frame is always 1/60 of a second</summary>
    Headless: Boolean;
    /// <summary>-nosound: the window has no sound device (a headless run has none anyway)</summary>
    NoSound: Boolean;
    /// <summary>
    ///   -nointro: the logo goes on to the menu. Without it a game in a window that starts from the title (no -play, no
    ///   -load, no -script, not headless) plays the introduction after the logo (the animations are the port's own)
    /// </summary>
    NoIntroduction: Boolean;
    /// <summary>-script: a file of the commands of Tools\Verifica\197 (scene, campaign, move, key, run ...)</summary>
    ScriptPath: string;
    /// <summary>-shot: the last picture is saved as a PNG when the program ends</summary>
    ShotPath: string;
    /// <summary>-load: a saved game that is loaded before the first frame</summary>
    LoadPath: string;
    /// <summary>-save: the game is saved in this file when the program ends</summary>
    SavePath: string;
    /// <summary>-play human|orc N: the program goes at once to the mission N of the campaign (0 = from the title)</summary>
    PlayRace: TWarRace;
    PlayMission: Integer;
    /// <summary>-seed: where the generator of random numbers of the game starts</summary>
    Seed: Cardinal;
    /// <summary>-quitafter: the program ends after that number of frames (0 = when the player quits)</summary>
    QuitAfterFrames: Integer;
    /// <summary>-audiostats: at the end it writes what the sound did</summary>
    AudioStatistics: Boolean;
    /// <summary>-scale: the window is that many times the picture of 320 x 200 (1..8)</summary>
    Scale: Integer;
    /// <summary>-help or -?: the usage is written and the program ends</summary>
    ShowHelp: Boolean;
    /// <summary>The options of a program started with no arguments</summary>
    class function Standard: TWarAppOptions; static;
  end;

const
  /// <summary>The seed of the generator when -seed is not given</summary>
  WAR_APP_DEFAULT_SEED = 1;
  /// <summary>The window is this many times the picture when -scale is not given</summary>
  WAR_APP_DEFAULT_SCALE = 3;
  /// <summary>The largest -scale</summary>
  WAR_APP_MAX_SCALE = 8;

implementation

{ TWarAppOptions }

class function TWarAppOptions.Standard: TWarAppOptions;
begin
  Result := Default(TWarAppOptions);
  Result.PlayRace := wraNeutral;
  Result.Seed := WAR_APP_DEFAULT_SEED;
  Result.Scale := WAR_APP_DEFAULT_SCALE;
end;

end.
