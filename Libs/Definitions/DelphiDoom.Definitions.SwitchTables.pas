{******************************************************************************}
{                                                                              }
{  DelphiDoom: definitions library - the switch tables of the four games       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Definitions.SwitchTables;

interface

uses
  DelphiDoom.Definitions.Types;

type
  /// <summary>
  ///   The tables of switches that were compiled in p_switch.pas of each game (without the
  ///   terminator entry). They are the table of the game when the WAD has no SWITCHES lump
  ///   (Doom and Strife) or always (Heretic and Hexen). The sound of Hexen and Strife is
  ///   the name of the constant of the engine (SoundName): the engine knows its number
  /// </summary>
  TSwitchTables = class
  public
    class function ForGame(AGame: TDefGame): TArray<TDefSwitchPair>; static;
  end;

implementation

const
  /// <summary>Doom: episode 1 shareware, 2 registered, 3 Doom II</summary>
  DOOM_SWITCHES: array[0..39] of TDefSwitchPair = (
    (Name1: 'SW1BRCOM'; Name2: 'SW2BRCOM'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1BRN1'; Name2: 'SW2BRN1'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1BRN2'; Name2: 'SW2BRN2'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1BRNGN'; Name2: 'SW2BRNGN'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1BROWN'; Name2: 'SW2BROWN'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1COMM'; Name2: 'SW2COMM'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1COMP'; Name2: 'SW2COMP'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1DIRT'; Name2: 'SW2DIRT'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1EXIT'; Name2: 'SW2EXIT'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1GRAY'; Name2: 'SW2GRAY'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1GRAY1'; Name2: 'SW2GRAY1'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1METAL'; Name2: 'SW2METAL'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1PIPE'; Name2: 'SW2PIPE'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1SLAD'; Name2: 'SW2SLAD'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1STARG'; Name2: 'SW2STARG'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1STON1'; Name2: 'SW2STON1'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1STON2'; Name2: 'SW2STON2'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1STONE'; Name2: 'SW2STONE'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1STRTN'; Name2: 'SW2STRTN'; Episode: 1; Sound: 0; SoundName: ''),
    (Name1: 'SW1BLUE'; Name2: 'SW2BLUE'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1CMT'; Name2: 'SW2CMT'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1GARG'; Name2: 'SW2GARG'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1GSTON'; Name2: 'SW2GSTON'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1HOT'; Name2: 'SW2HOT'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1LION'; Name2: 'SW2LION'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1SATYR'; Name2: 'SW2SATYR'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1SKIN'; Name2: 'SW2SKIN'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1VINE'; Name2: 'SW2VINE'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1WOOD'; Name2: 'SW2WOOD'; Episode: 2; Sound: 0; SoundName: ''),
    (Name1: 'SW1PANEL'; Name2: 'SW2PANEL'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1ROCK'; Name2: 'SW2ROCK'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1MET2'; Name2: 'SW2MET2'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1WDMET'; Name2: 'SW2WDMET'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1BRIK'; Name2: 'SW2BRIK'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1MOD1'; Name2: 'SW2MOD1'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1ZIM'; Name2: 'SW2ZIM'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1STON6'; Name2: 'SW2STON6'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1TEK'; Name2: 'SW2TEK'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1MARB'; Name2: 'SW2MARB'; Episode: 3; Sound: 0; SoundName: ''),
    (Name1: 'SW1SKULL'; Name2: 'SW2SKULL'; Episode: 3; Sound: 0; SoundName: '')
  );

  /// <summary>Heretic: episode 0</summary>
  HERETIC_SWITCHES: array[0..1] of TDefSwitchPair = (
    (Name1: 'SW1OFF'; Name2: 'SW1ON'; Episode: 0; Sound: 0; SoundName: ''),
    (Name1: 'SW2OFF'; Name2: 'SW2ON'; Episode: 0; Sound: 0; SoundName: '')
  );

  /// <summary>Hexen: no episode, the sound is the SoundName</summary>
  HEXEN_SWITCHES: array[0..9] of TDefSwitchPair = (
    (Name1: 'SW_1_UP'; Name2: 'SW_1_DN'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH1'),
    (Name1: 'SW_2_UP'; Name2: 'SW_2_DN'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH1'),
    (Name1: 'VALVE1'; Name2: 'VALVE2'; Episode: 0; Sound: 0; SoundName: 'SFX_VALVE_TURN'),
    (Name1: 'SW51_OFF'; Name2: 'SW51_ON'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH2'),
    (Name1: 'SW52_OFF'; Name2: 'SW52_ON'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH2'),
    (Name1: 'SW53_UP'; Name2: 'SW53_DN'; Episode: 0; Sound: 0; SoundName: 'SFX_ROPE_PULL'),
    (Name1: 'PUZZLE5'; Name2: 'PUZZLE9'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH1'),
    (Name1: 'PUZZLE6'; Name2: 'PUZZLE10'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH1'),
    (Name1: 'PUZZLE7'; Name2: 'PUZZLE11'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH1'),
    (Name1: 'PUZZLE8'; Name2: 'PUZZLE12'; Episode: 0; Sound: 0; SoundName: 'SFX_SWITCH1')
  );

  /// <summary>Strife: episode 1 shareware, 2 registered</summary>
  STRIFE_SWITCHES: array[0..68] of TDefSwitchPair = (
    (Name1: 'GLASS01'; Name2: 'GLASS02'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS03'; Name2: 'GLASS04'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS05'; Name2: 'GLASS06'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS07'; Name2: 'GLASS08'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS17'; Name2: 'GLASS18'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS19'; Name2: 'GLASS20'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'SWKNOB01'; Name2: 'SWKNOB02'; Episode: 1; Sound: 0; SoundName: 'sfx_swknob'),
    (Name1: 'SWLITE01'; Name2: 'SWLITE02'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWCHN01'; Name2: 'SWCHN02'; Episode: 1; Sound: 0; SoundName: 'sfx_pulchn'),
    (Name1: 'COMP01'; Name2: 'COMP04B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP05'; Name2: 'COMP12B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP09'; Name2: 'COMP12B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP12'; Name2: 'COMP04B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP13'; Name2: 'COMP12B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP17'; Name2: 'COMP20B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP21'; Name2: 'COMP28B'; Episode: 1; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'WALTEK09'; Name2: 'WALTEKB1'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'WALTEK10'; Name2: 'WALTEKB1'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'WALTEK15'; Name2: 'WALTEKB1'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWFORC01'; Name2: 'SWFORC02'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWEXIT01'; Name2: 'SWEXIT02'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'DORSBK01'; Name2: 'DORSBK02'; Episode: 1; Sound: 0; SoundName: 'sfx_swston'),
    (Name1: 'SWSLD01'; Name2: 'SWSLD02'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'DORWS04'; Name2: 'DORWS05'; Episode: 1; Sound: 0; SoundName: 'sfx_swbolt'),
    (Name1: 'SWIRON01'; Name2: 'SWIRON02'; Episode: 1; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'GLASS09'; Name2: 'GLASS10'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS11'; Name2: 'GLASS12'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS13'; Name2: 'GLASS14'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GLASS15'; Name2: 'GLASS16'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'SWFORC03'; Name2: 'SWFORC04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWCIT01'; Name2: 'SWCIT02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWTRMG01'; Name2: 'SWTRMG04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWMETL01'; Name2: 'SWMETL02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWWOOD01'; Name2: 'SWWOOD02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWTKBL01'; Name2: 'SWTKBL02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'AZWAL21'; Name2: 'AZWAL22'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWINDT01'; Name2: 'SWINDT02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWRUST01'; Name2: 'SWRUST02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWCHAP01'; Name2: 'SWCHAP02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWALIN01'; Name2: 'SWALIN02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWWALG01'; Name2: 'SWWALG02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWWALG03'; Name2: 'SWWALG04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWTRAM01'; Name2: 'SWTRAM02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWTRAM03'; Name2: 'SWTRAM04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWORC01'; Name2: 'SWORC02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWBRIK01'; Name2: 'SWBRIK02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWIRON03'; Name2: 'SWIRON04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWIRON05'; Name2: 'SWIRON06'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWIRON07'; Name2: 'SWIRON08'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWCARD01'; Name2: 'SWCARD02'; Episode: 2; Sound: 0; SoundName: 'sfx_keycrd'),
    (Name1: 'SWSIGN01'; Name2: 'SWSIGN02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWLEV01'; Name2: 'SWLEV02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWLEV03'; Name2: 'SWLEV04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWLEV05'; Name2: 'SWLEV06'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWBRN01'; Name2: 'SWBRN02'; Episode: 2; Sound: 0; SoundName: 'sfx_keycrd'),
    (Name1: 'SWPIP01'; Name2: 'SWPIP02'; Episode: 2; Sound: 0; SoundName: 'sfx_valve'),
    (Name1: 'SWPALM01'; Name2: 'SWPALM02'; Episode: 2; Sound: 0; SoundName: 'sfx_swscan'),
    (Name1: 'SWKNOB03'; Name2: 'SWKNOB04'; Episode: 2; Sound: 0; SoundName: 'sfx_swknob'),
    (Name1: 'ALTSW01'; Name2: 'ALTSW02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'COMP25'; Name2: 'COMP28B'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP29'; Name2: 'COMP20B'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP33'; Name2: 'COMP50'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'COMP42'; Name2: 'COMP51'; Episode: 2; Sound: 0; SoundName: 'sfx_bglass'),
    (Name1: 'GODSCRN1'; Name2: 'GODSCRN2'; Episode: 2; Sound: 0; SoundName: 'sfx_difool'),
    (Name1: 'ALIEN04'; Name2: 'ALIEN05'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'CITADL04'; Name2: 'CITADL05'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWITE03'; Name2: 'SWITE04'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'SWTELP01'; Name2: 'SWTELP02'; Episode: 2; Sound: 0; SoundName: 'sfx_None'),
    (Name1: 'BRNSCN01'; Name2: 'BRNSCN05'; Episode: 2; Sound: 0; SoundName: 'sfx_firxpl')
  );

function CopyRows(const ARows: array of TDefSwitchPair): TArray<TDefSwitchPair>;
var
  LIndex: Integer;
begin
  SetLength(Result, Length(ARows));
  for LIndex := 0 to High(ARows) do
    Result[LIndex] := ARows[LIndex];
end;

{ TSwitchTables }

class function TSwitchTables.ForGame(AGame: TDefGame): TArray<TDefSwitchPair>;
begin
  case AGame of
    TDefGame.Doom: Result := CopyRows(DOOM_SWITCHES);
    TDefGame.Heretic: Result := CopyRows(HERETIC_SWITCHES);
    TDefGame.Hexen: Result := CopyRows(HEXEN_SWITCHES);
  else
    Result := CopyRows(STRIFE_SWITCHES);
  end;
end;

end.