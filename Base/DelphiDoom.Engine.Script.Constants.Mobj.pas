{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - the constants of the mobjs, for scripts                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Script.Constants.Mobj;

interface

uses
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>
  ///   The alignments of the overlay, the flags of the mobjs, the names of the states and the types of the
  ///   mobjs, as constants of the scripts (they were in PS_ScriptOnUses). The flags of the second word
  ///   exist in Heretic and Hexen only
  /// </summary>
  TEngineScriptMobjConstants = class(TInterfacedObject, IScriptConstantProvider)
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
  psi_overlay,
  TypInfo;

{ TEngineScriptMobjConstants }

procedure TEngineScriptMobjConstants.Describe(const ATable: IScriptConstantTable);
var
  I: Integer;
  M: Integer;
  LFlagCount: LongWord;
  LStates: TDStringList;
begin
  // Overlay drawing
  ATable.AddInteger('alLeft', OVR_ALIGN_LEFT);
  ATable.AddInteger('alRight', OVR_ALIGN_RIGHT);
  ATable.AddInteger('alCenter', OVR_ALIGN_CENTER);

  // mobj flags
  LFlagCount := 0;
  for I := 0 to mobj_flags.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags[I], LFlagCount);
    Inc(LFlagCount);
  end;

{$IFDEF HERETIC_OR_HEXEN}
  // mobj flags2
  LFlagCount := 32;
  for I := 0 to mobj_flags2.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags2[I], LFlagCount);
    Inc(LFlagCount);
  end;
{$ENDIF}

  // mobj flags_ex
  LFlagCount := 64;
  for I := 0 to mobj_flags_ex.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags_ex[I], LFlagCount);
    Inc(LFlagCount);
  end;

  // mobj flags2_ex
  LFlagCount := 96;
  for I := 0 to mobj_flags2_ex.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags2_ex[I], LFlagCount);
    Inc(LFlagCount);
  end;

  // mobj flags3_ex
  LFlagCount := 128;
  for I := 0 to mobj_flags3_ex.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags3_ex[I], LFlagCount);
    Inc(LFlagCount);
  end;

  // mobj flags4_ex
  LFlagCount := 160;
  for I := 0 to mobj_flags4_ex.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags4_ex[I], LFlagCount);
    Inc(LFlagCount);
  end;

  // mobj flags5_ex
  LFlagCount := 192;
  for I := 0 to mobj_flags5_ex.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags5_ex[I], LFlagCount);
    Inc(LFlagCount);
  end;

  // mobj flags6_ex
  LFlagCount := 224;
  for I := 0 to mobj_flags6_ex.Count - 1 do
  begin
    ATable.AddLongWord(mobj_flags6_ex[I], LFlagCount);
    Inc(LFlagCount);
  end;

  // states
  LStates := statenames.AllTokensWithIndex;
  for I := 0 to LStates.Count - 1 do
  begin
    ATable.AddInteger(LStates[I], (LStates.Objects[I] as TInteger).intnum);
    (LStates.Objects[I] as TInteger).Free;
  end;
  LStates.Free;

  // mobj types
  for M := 0 to Ord(DO_NUMMOBJTYPES) - 1 do
    ATable.AddInteger(GetENumName(TypeInfo(mobjtype_t), M), M);
end;

end.
