{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - ammo, misc values, strings, songs and sounds           }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.TableExport.Settings;

interface

uses
  DelphiDoom.CommandLine.Intf,
  DelphiDoom.TableExport.Intf;

type
  /// <summary>What a patch has besides things, states and weapons, from the globals of the game</summary>
  TEngineExportSettings = class(TInterfacedObject, IExportSettingsSource)
  strict private
    FCommandLine: ICommandLine;
  public
    /// <param name="ACommandLine">What CommandLine writes in the patch</param>
    constructor Create(const ACommandLine: ICommandLine);
    function CreatedWith: string;
    function CommandLine: string;
    function AmmoCount: Integer;
    function Ammo(AIndex, AValue: Integer): Integer;
    function Misc(AIndex: Integer): Integer;
    function Par(AEpisode, AMap: Integer): Integer;
    function CommercialPar(AMap: Integer): Integer;
    function StringCount: Integer;
    function StringName(AIndex: Integer): string;
    function StringValue(AIndex: Integer): string;
    function MusicCount: Integer;
    function MusicName(AIndex: Integer): string;
    function MusicMapName(AIndex: Integer): string;
    function SoundCount: Integer;
    function SoundName(AIndex: Integer): string;
  end;

implementation

uses
  SysUtils,
  d_delphi,
  d_main,
  deh_main,
  doomdef,
  {$IFNDEF HEXEN}
  d_player,
  {$ENDIF}
  g_game,
  {$IFDEF DOOM}
  p_pspr,
  st_stuff,
  {$ENDIF}
  p_inter,
  sounddata;

{ TEngineExportSettings }

constructor TEngineExportSettings.Create(const ACommandLine: ICommandLine);
begin
  inherited Create;
  if not Assigned(ACommandLine) then
    raise EArgumentNilException.Create('ACommandLine');
  FCommandLine := ACommandLine;
end;

function TEngineExportSettings.CreatedWith: string;
begin
  Result := Format('%s, %s', [D_Version, D_VersionBuilt]);
end;

function TEngineExportSettings.CommandLine: string;
var
  LIndex: Integer;
begin
  Result := fname(FCommandLine[0]);
  for LIndex := 1 to FCommandLine.Count - 1 do
    Result := Result + ' ' + FCommandLine[LIndex];
end;

function TEngineExportSettings.AmmoCount: Integer;
begin
  {$IFDEF HEXEN}
  Result := 0;
  {$ELSE}
  Result := Ord(NUMAMMO);
  {$ENDIF}
end;

function TEngineExportSettings.Ammo(AIndex, AValue: Integer): Integer;
begin
  {$IFDEF HEXEN}
  Result := 0;
  {$ELSE}
  if AValue = 0 then
    Result := maxammo[AIndex]
  {$IFDEF HERETIC}
  else
    Result := 0;
  {$ELSE}
  else
    Result := clipammo[AIndex];
  {$ENDIF}
  {$ENDIF}
end;

function TEngineExportSettings.Misc(AIndex: Integer): Integer;
begin
  {$IFDEF DOOM}
  case AIndex of
    0: Result := p_maxhealth;
    1: Result := p_soulspherehealth;
    2: Result := p_megaspherehealth;
    3: Result := p_medikithealth;
    4: Result := p_stimpackhealth;
    5: Result := p_bonushealth;
    6: Result := p_maxarmor;
    7: Result := p_greenarmorclass;
    8: Result := p_bluearmorclass;
    9: Result := p_initialbullets;
    10: Result := p_bfgcells;
    11: Result := p_idfaarmor;
    12: Result := p_idfaarmorclass;
    13: Result := p_idkfaarmor;
    14: Result := p_idkfaarmorclass;
    15: Result := p_maxsoulsphere;
  else
    Result := 0;
  end;
  {$ENDIF}
  {$IFDEF HERETIC}
  case AIndex of
    0: Result := p_maxhealth;
    1: Result := p_soulspherehealth;
    2: Result := p_megaspherehealth;
    3: Result := p_medikithealth;
    4: Result := p_stimpackhealth;
    5: Result := p_bonushealth;
    6: Result := p_maxarmor;
    7: Result := p_greenarmorclass;
    8: Result := p_bluearmorclass;
    9: Result := p_maxchickenhealth;
    10: Result := p_maxartifacts;
  else
    Result := 0;
  end;
  {$ENDIF}
  {$IFDEF HEXEN}
  case AIndex of
    0: Result := p_maxmorphhealth;
    1: Result := p_maxartifacts;
    2: Result := p_quartzflaskhealth;
    3: Result := p_mysticurnhealth;
    4: Result := MAX_MANA;
  else
    Result := 0;
  end;
  {$ENDIF}
  {$IFDEF STRIFE}
  case AIndex of
    0: Result := p_maxhealth;
    1: Result := p_soulspherehealth;
    2: Result := p_megaspherehealth;
    3: Result := p_medikithealth;
    4: Result := p_stimpackhealth;
    5: Result := p_bonushealth;
    6: Result := p_maxarmor;
    7: Result := p_greenarmorclass;
    8: Result := p_bluearmorclass;
  else
    Result := 0;
  end;
  {$ENDIF}
end;

function TEngineExportSettings.Par(AEpisode, AMap: Integer): Integer;
begin
  {$IFDEF HEXEN}
  Result := 0;
  {$ELSE}
  {$IFDEF STRIFE}
  Result := 0;
  {$ELSE}
  Result := pars[AEpisode, AMap];
  {$ENDIF}
  {$ENDIF}
end;

function TEngineExportSettings.CommercialPar(AMap: Integer): Integer;
begin
  {$IFDEF DOOM}
  Result := cpars[AMap];
  {$ELSE}
  Result := 0;
  {$ENDIF}
end;

function TEngineExportSettings.StringCount: Integer;
begin
  Result := deh_strings.numstrings;
end;

function TEngineExportSettings.StringName(AIndex: Integer): string;
begin
  Result := deh_strings._array[AIndex].name;
end;

function TEngineExportSettings.StringValue(AIndex: Integer): string;
begin
  Result := deh_strings._array[AIndex].pstr^;
end;

function TEngineExportSettings.MusicCount: Integer;
begin
  Result := nummusic;
end;

function TEngineExportSettings.MusicName(AIndex: Integer): string;
begin
  Result := S_music[AIndex].name;
end;

function TEngineExportSettings.MusicMapName(AIndex: Integer): string;
begin
  Result := S_music[AIndex].mapname;
end;

function TEngineExportSettings.SoundCount: Integer;
begin
  Result := numsfx;
end;

function TEngineExportSettings.SoundName(AIndex: Integer): string;
begin
  Result := S_sfx[AIndex].name;
end;

end.
