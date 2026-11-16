{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the constants of the game, for scripts                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Constants.Game;

interface

uses
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>
  ///   The skills, cards or keys, classes, weapons, ammo or mana, powers, artifacts and quests of the game, as
  ///   constants of the scripts (they were in PS_ScriptOnUses). The types differ from game to game: the
  ///   {$IFDEF} are here because the enumerations exist only in the build of their game
  /// </summary>
  TEngineScriptGameConstants = class(TInterfacedObject, IScriptConstantProvider)
  public
    procedure Describe(const ATable: IScriptConstantTable);
  end;

implementation

uses
  d_delphi,
  deh_main,
  doomdef,
{$IFDEF DOOM_OR_STRIFE}
  d_items,
{$ENDIF}
  info_h,
  info_common,
  p_gender,
  p_local,
  r_renderstyle,
  sc_states,
  tables,
  m_fixed,
  p_mobj_h,
  psi_game,
  TypInfo;

{ TEngineScriptGameConstants }

procedure TEngineScriptGameConstants.Describe(const ATable: IScriptConstantTable);
var
  M: Integer;
begin
  // consts doomdef
  ATable.AddInteger('MAXPLAYERS', MAXPLAYERS);

  for M := 0 to Ord(sk_nightmare) do
    ATable.AddInteger(GetENumName(TypeInfo(skill_t), M), M);

{$IFDEF DOOM_OR_STRIFE}
  for M := 0 to Ord(NUMCARDS) do
    ATable.AddInteger(GetENumName(TypeInfo(card_t), M), M);
{$ELSE}
  for M := 0 to Ord(NUMKEYCARDS) do
    ATable.AddInteger(GetENumName(TypeInfo(keytype_t), M), M);
{$ENDIF}

{$IFDEF HEXEN}
  for M := 0 to Ord(NUMCLASSES) do
    ATable.AddInteger(GetENumName(TypeInfo(pclass_t), M), M);
{$ENDIF}

  for M := 0 to Ord(NUMWEAPONS) do
    ATable.AddInteger(GetENumName(TypeInfo(weapontype_t), M), M);

  for M := 0 to Ord(NUMMOBJRENDERSTYLES) do
    ATable.AddInteger(GetENumName(TypeInfo(mobjrenderstyle_t), M), M);

  for M := 0 to Ord(NUMGENDERS) do
    ATable.AddInteger(GetENumName(TypeInfo(gender_t), M), M);

{$IFDEF HEXEN}
  for M := 0 to Ord(NUMMANA) do
    ATable.AddInteger(GetENumName(TypeInfo(manatype_t), M), M);
  ATable.AddInteger('MAX_MANA', MAX_MANA);
{$ELSE}
  for M := 0 to Ord(NUMAMMO) do
    ATable.AddInteger(GetENumName(TypeInfo(ammotype_t), M), M);
{$ENDIF}

  for M := 0 to Ord(NUMPOWERS) do
    ATable.AddInteger(GetENumName(TypeInfo(powertype_t), M), M);

{$IFDEF HERETIC_OR_HEXEN}
  for M := 0 to Ord(NUMARTIFACTS) do
    ATable.AddInteger(GetENumName(TypeInfo(artitype_t), M), M);
{$ENDIF}

{$IFDEF HEXEN}
  ATable.AddInteger('arti_firstpuzzitem', arti_firstpuzzitem);
{$ENDIF}

{$IFDEF STRIFE}
  for M := 0 to Ord(tk_numquests) do
    ATable.AddInteger(GetENumName(TypeInfo(questtype_t), M), M);

  ATable.AddLongWord('QF_QUEST1', QF_QUEST1);
  ATable.AddLongWord('QF_QUEST2', QF_QUEST2);
  ATable.AddLongWord('QF_QUEST3', QF_QUEST3);
  ATable.AddLongWord('QF_QUEST4', QF_QUEST4);
  ATable.AddLongWord('QF_QUEST5', QF_QUEST5);
  ATable.AddLongWord('QF_QUEST6', QF_QUEST6);
  ATable.AddLongWord('QF_QUEST7', QF_QUEST7);
  ATable.AddLongWord('QF_QUEST8', QF_QUEST8);
  ATable.AddLongWord('QF_QUEST9', QF_QUEST9);
  ATable.AddLongWord('QF_QUEST10', QF_QUEST10);
  ATable.AddLongWord('QF_QUEST11', QF_QUEST11);
  ATable.AddLongWord('QF_QUEST12', QF_QUEST12);
  ATable.AddLongWord('QF_QUEST13', QF_QUEST13);
  ATable.AddLongWord('QF_QUEST14', QF_QUEST14);
  ATable.AddLongWord('QF_QUEST15', QF_QUEST15);
  ATable.AddLongWord('QF_QUEST16', QF_QUEST16);
  ATable.AddLongWord('QF_QUEST17', QF_QUEST17);
  ATable.AddLongWord('QF_QUEST18', QF_QUEST18);
  ATable.AddLongWord('QF_QUEST19', QF_QUEST19);
  ATable.AddLongWord('QF_QUEST20', QF_QUEST20);
  ATable.AddLongWord('QF_QUEST21', QF_QUEST21);
  ATable.AddLongWord('QF_QUEST22', QF_QUEST22);
  ATable.AddLongWord('QF_QUEST23', QF_QUEST23);
  ATable.AddLongWord('QF_QUEST24', QF_QUEST24);
  ATable.AddLongWord('QF_QUEST25', QF_QUEST25);
  ATable.AddLongWord('QF_QUEST26', QF_QUEST26);
  ATable.AddLongWord('QF_QUEST27', QF_QUEST27);
  ATable.AddLongWord('QF_QUEST28', QF_QUEST28);
  ATable.AddLongWord('QF_QUEST29', QF_QUEST29);
  ATable.AddLongWord('QF_QUEST30', QF_QUEST30);
  ATable.AddLongWord('QF_QUEST31', QF_QUEST31);
  ATable.AddLongWord('QF_ALLQUESTS', QF_ALLQUESTS);
{$ENDIF}
end;

end.
