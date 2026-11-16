{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the settings of the game                          }
{                                                                              }
{  Port of war1 (acoto87/war1), the fields of WarContext that the cheats and   }
{  wg_setGlobalScale, wg_setGlobalSpeed, wg_setMusicVolume, wg_setSoundVolume  }
{  of war_game.c change, (c) 2019 Alejandro Coto Gutierrez, zlib License (see  }
{  Games\War\LICENSE-war1.txt). This is an altered version, not the original.  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.GameSettings;

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Intf;

type
  /// <summary>
  ///   The settings: the cheats on (wg_initGame turns them on), the audio, the scale of the window and the speed of the
  ///   game. A scale or a speed below 1 is 1; a volume is between 0 and 1
  /// </summary>
  TWarGameSettings = class(TInterfacedObject, IWarGameSettings)
  strict private
    FCheatsEnabled: Boolean;
    FMusicEnabled: Boolean;
    FSoundEnabled: Boolean;
    FAudioEnabled: Boolean;
    FGlobalScale: Single;
    FGlobalSpeed: Single;
    FMusicVolume: Single;
    FSoundVolume: Single;
  public
    constructor Create;
    function GetCheatsEnabled: Boolean;
    procedure SetCheatsEnabled(AValue: Boolean);
    function GetMusicEnabled: Boolean;
    procedure SetMusicEnabled(AValue: Boolean);
    function GetSoundEnabled: Boolean;
    procedure SetSoundEnabled(AValue: Boolean);
    function GetAudioEnabled: Boolean;
    procedure SetAudioEnabled(AValue: Boolean);
    function GetGlobalScale: Single;
    function GetGlobalSpeed: Single;
    function GetMusicVolume: Single;
    function GetSoundVolume: Single;
    procedure SetGlobalScale(AScale: Single);
    procedure SetGlobalSpeed(ASpeed: Single);
    procedure SetMusicVolume(AVolume: Single);
    procedure SetSoundVolume(AVolume: Single);
  end;

implementation

{ TWarGameSettings }

constructor TWarGameSettings.Create;
begin
  inherited Create;
  FCheatsEnabled := True;
  FMusicEnabled := True;
  FSoundEnabled := True;
  // wg_initGame: the window starts at three times the size of the game
  FGlobalScale := 3;
  FGlobalSpeed := 1;
  FMusicVolume := 1;
  FSoundVolume := 1;
end;

function TWarGameSettings.GetCheatsEnabled: Boolean;
begin
  Result := FCheatsEnabled;
end;

procedure TWarGameSettings.SetCheatsEnabled(AValue: Boolean);
begin
  FCheatsEnabled := AValue;
end;

function TWarGameSettings.GetMusicEnabled: Boolean;
begin
  Result := FMusicEnabled;
end;

procedure TWarGameSettings.SetMusicEnabled(AValue: Boolean);
begin
  FMusicEnabled := AValue;
end;

function TWarGameSettings.GetSoundEnabled: Boolean;
begin
  Result := FSoundEnabled;
end;

procedure TWarGameSettings.SetSoundEnabled(AValue: Boolean);
begin
  FSoundEnabled := AValue;
end;

function TWarGameSettings.GetAudioEnabled: Boolean;
begin
  Result := FAudioEnabled;
end;

procedure TWarGameSettings.SetAudioEnabled(AValue: Boolean);
begin
  FAudioEnabled := AValue;
end;

function TWarGameSettings.GetGlobalScale: Single;
begin
  Result := FGlobalScale;
end;

function TWarGameSettings.GetGlobalSpeed: Single;
begin
  Result := FGlobalSpeed;
end;

function TWarGameSettings.GetMusicVolume: Single;
begin
  Result := FMusicVolume;
end;

function TWarGameSettings.GetSoundVolume: Single;
begin
  Result := FSoundVolume;
end;

procedure TWarGameSettings.SetGlobalScale(AScale: Single);
begin
  if AScale > 1 then
    FGlobalScale := AScale
  else
    FGlobalScale := 1;
end;

procedure TWarGameSettings.SetGlobalSpeed(ASpeed: Single);
begin
  if ASpeed > 1 then
    FGlobalSpeed := ASpeed
  else
    FGlobalSpeed := 1;
end;

procedure TWarGameSettings.SetMusicVolume(AVolume: Single);
begin
  if AVolume < 0 then
    FMusicVolume := 0
  else if AVolume > 1 then
    FMusicVolume := 1
  else
    FMusicVolume := AVolume;
end;

procedure TWarGameSettings.SetSoundVolume(AVolume: Single);
begin
  if AVolume < 0 then
    FSoundVolume := 0
  else if AVolume > 1 then
    FSoundVolume := 1
  else
    FSoundVolume := AVolume;
end;

end.
