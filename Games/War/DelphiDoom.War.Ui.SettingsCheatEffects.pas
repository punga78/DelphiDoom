{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the cheats that change the settings               }
{                                                                              }
{  Port of war1 (acoto87/war1), war_cheats.c (wcheat_applyEnableCheat,         }
{  wcheat_applyMusicCheat, wcheat_applySoundCheat, wcheat_applyMusicVolCheat,  }
{  wcheat_applySoundVolCheat, wcheat_applyGlobalScaleCheat,                    }
{  wcheat_applyGlobalSpeedCheat), (c) 2019 Alejandro Coto Gutierrez, zlib      }
{  License (see Games\War\LICENSE-war1.txt). This is an altered version, not   }
{  the original.                                                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.SettingsCheatEffects;

interface

uses
  System.SysUtils, DelphiDoom.War.Ui.Intf, DelphiDoom.War.Ui.Strings;

type
  /// <summary>
  ///   The cheats that work without a map: cheats on or off, music and sound on, off and volume, the scale and the speed.
  ///   The others (gold, spells, upgrades, the end, god mode, win, loss, fog, skip, hurry up, edit, add unit, rain of fire,
  ///   poison cloud, raise dead) return silently when there is no map, and so they do here: the map is not part of this
  ///   class. "Debug render" (the flags of the debug drawing of the map) is not ported either. Without the cheats on
  ///   nothing but "Corwin of Amber" does anything. The feedback is returned, not shown
  /// </summary>
  TWarSettingsCheatEffects = class(TInterfacedObject, IWarCheatEffects)
  strict private
    FSettings: IWarGameSettings;
    FAudio: IWarSceneAudio;
    FIsDemo: Boolean;
    function ApplyMusic(const AArgument: AnsiString): AnsiString;
    function ApplySound(const AArgument: AnsiString): AnsiString;
    function ApplyMusicVolume(const AArgument: AnsiString): AnsiString;
    function ApplySoundVolume(const AArgument: AnsiString): AnsiString;
    function RoundedVolume(AValue: Integer): Integer;
  public
    /// <summary>The audio may be nil</summary>
    constructor Create(const ASettings: IWarGameSettings; const AAudio: IWarSceneAudio; AIsDemo: Boolean);
    function Apply(const AName: string; const AArgument: AnsiString): AnsiString;
  end;

implementation

{ TWarSettingsCheatEffects }

constructor TWarSettingsCheatEffects.Create(const ASettings: IWarGameSettings; const AAudio: IWarSceneAudio;
  AIsDemo: Boolean);
begin
  inherited Create;
  FSettings := ASettings;
  FAudio := AAudio;
  FIsDemo := AIsDemo;
end;

function TWarSettingsCheatEffects.Apply(const AName: string; const AArgument: AnsiString): AnsiString;
var
  LValue: Integer;
begin
  Result := '';
  if AName = 'Corwin of Amber' then
  begin
    if not FSettings.CheatsEnabled then
    begin
      FSettings.CheatsEnabled := True;
      Result := 'cheats enabled';
    end
    else
    begin
      FSettings.CheatsEnabled := False;
      Result := 'cheats disabled';
    end;
    Exit;
  end;
  if not FSettings.CheatsEnabled then
    Exit;
  if AName = 'Music' then
    Result := ApplyMusic(AArgument)
  else if AName = 'Sound' then
    Result := ApplySound(AArgument)
  else if AName = 'Music vol' then
    Result := ApplyMusicVolume(AArgument)
  else if AName = 'Sound vol' then
    Result := ApplySoundVolume(AArgument)
  else if AName = 'Scale' then
  begin
    if TWarStrings.TryParseS32(AArgument, LValue) then
    begin
      if LValue < 1 then
        LValue := 1;
      if LValue > 5 then
        LValue := 5;
      FSettings.SetGlobalScale(LValue);
      Result := AnsiString(Format('Global scale set to %d', [LValue]));
    end;
  end
  else if AName = 'Speed' then
  begin
    if TWarStrings.TryParseS32(AArgument, LValue) then
    begin
      if LValue < 1 then
        LValue := 1;
      if LValue > 5 then
        LValue := 5;
      FSettings.SetGlobalSpeed(LValue);
      Result := AnsiString(Format('Global speed set to %d', [LValue]));
    end;
  end;
end;

function TWarSettingsCheatEffects.ApplyMusic(const AArgument: AnsiString): AnsiString;
var
  LMusicId: Integer;
begin
  Result := '';
  if TWarStrings.EqualsIgnoreCase(AArgument, 'on') then
  begin
    FSettings.MusicEnabled := True;
    Result := 'Music on';
  end
  else if TWarStrings.EqualsIgnoreCase(AArgument, 'off') then
  begin
    FSettings.MusicEnabled := False;
    Result := 'Music off';
  end
  else if not FIsDemo then
  begin
    if TWarStrings.TryParseS32(AArgument, LMusicId) then
    begin
      // the argument is 1 to 45, the music ids 0 to 44
      Dec(LMusicId);
      if (LMusicId >= 0) and (LMusicId <= 44) then
      begin
        if Assigned(FAudio) then
        begin
          FAudio.StopMusic;
          FAudio.Play(LMusicId, True);
        end;
        Result := AnsiString(Format('Music %d set', [LMusicId + 1]));
      end;
    end;
  end;
end;

function TWarSettingsCheatEffects.ApplySound(const AArgument: AnsiString): AnsiString;
begin
  Result := '';
  if TWarStrings.EqualsIgnoreCase(AArgument, 'on') then
  begin
    FSettings.SoundEnabled := True;
    Result := 'Sounds on';
  end
  else if TWarStrings.EqualsIgnoreCase(AArgument, 'off') then
  begin
    FSettings.SoundEnabled := False;
    Result := 'Sounds off';
  end;
end;

function TWarSettingsCheatEffects.RoundedVolume(AValue: Integer): Integer;
begin
  // clamped to 0..100 and rounded to a multiple of 5
  if AValue < 0 then
    AValue := 0;
  if AValue > 100 then
    AValue := 100;
  case AValue mod 5 of
    1: Dec(AValue, 1);
    2: Dec(AValue, 2);
    3: Inc(AValue, 2);
    4: Inc(AValue, 1);
  end;
  Result := AValue;
end;

function TWarSettingsCheatEffects.ApplyMusicVolume(const AArgument: AnsiString): AnsiString;
var
  LRatio: Single;
  LVolume: Integer;
  LValue: Integer;
begin
  Result := '';
  if TWarStrings.TryParseS32(AArgument, LValue) then
  begin
    LVolume := RoundedVolume(LValue);
    FSettings.AudioEnabled := True;
    FSettings.MusicEnabled := True;
    LRatio := LVolume;
    LRatio := LRatio / 100;
    FSettings.SetMusicVolume(LRatio);
    Result := AnsiString(Format('Music volume set to %d', [LVolume]));
  end;
end;

function TWarSettingsCheatEffects.ApplySoundVolume(const AArgument: AnsiString): AnsiString;
var
  LRatio: Single;
  LVolume: Integer;
  LValue: Integer;
begin
  Result := '';
  if TWarStrings.TryParseS32(AArgument, LValue) then
  begin
    LVolume := RoundedVolume(LValue);
    FSettings.AudioEnabled := True;
    FSettings.SoundEnabled := True;
    LRatio := LVolume;
    LRatio := LRatio / 100;
    FSettings.SetSoundVolume(LRatio);
    Result := AnsiString(Format('Sounds volume set to %d', [LVolume]));
  end;
end;

end.
