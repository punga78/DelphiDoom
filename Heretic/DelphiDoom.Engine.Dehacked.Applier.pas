{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - what a DEHACKED patch does to the tables of Heretic    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}
unit DelphiDoom.Engine.Dehacked.Applier;

interface

uses
  DelphiDoom.Dehacked.Intf,
  DelphiDoom.Scanner.ContextEvaluator.Intf,
  DelphiDoom.Engine.Dehacked.Intf;

type
  /// <summary>
  ///   Reads a patch with the parser of Libs\Dehacked and applies its sections, in the order of
  ///   the file, to the tables of the game (it was DEH_Parse and DEH_Apply of deh_main). The
  ///   parameters of the actions of the states are read with the evaluator of the expressions
  /// </summary>
  TEngineDehackedApplier = class(TInterfacedObject, IEngineDehackedApplier)
  strict private
    FParser: IDehackedParser;
    FEvaluator: IContextExpressionEvaluator;
    procedure ApplyPatch(const APatch: IDehackedPatch);
  public
    /// <param name="AParser">The parser of DEHACKED and BEX of the game</param>
    /// <param name="AEvaluator">The evaluator of the expressions in the parameters of the actions</param>
    constructor Create(const AParser: IDehackedParser; const AEvaluator: IContextExpressionEvaluator);
    procedure Apply(const ALines: TArray<string>);
  end;

implementation

uses
  System.SysUtils,
  d_delphi,
  d_think,
  info_h,
  deh_main,
  TypInfo,
  DelphiDoom.Dehacked.Types,
  DelphiDoom.Dehacked.Section,
  doomdef,
  deh_base,
  d_main,
  h_strings,
  f_finale,
  g_game,
  hu_stuff,
  i_system,
  info,
  info_common,
  m_argv,
  p_mobj,
  p_mobj_h,
  p_enemy,
  p_extra,
  p_common,
  p_gender,
  DelphiDoom.Obituary.Genders,
  p_pspr,
  p_pspr_h,
  p_inter,
  r_renderstyle,
  DelphiDoom.Palette.TranslationBlood,
  sounddata,
  sounds,
  sc_params,
  DelphiDoom.Scanner.Text,
  sc_states;

const
  SParserMissing = 'TEngineDehackedApplier: the parser is nil';
  SEvaluatorMissing = 'TEngineDehackedApplier: the evaluator is nil';

{ TEngineDehackedApplier }

constructor TEngineDehackedApplier.Create(const AParser: IDehackedParser;
  const AEvaluator: IContextExpressionEvaluator);
begin
  inherited Create;
  if not Assigned(AParser) then
    raise EArgumentNilException.Create(SParserMissing);
  if not Assigned(AEvaluator) then
    raise EArgumentNilException.Create(SEvaluatorMissing);
  FParser := AParser;
  FEvaluator := AEvaluator;
end;

procedure TEngineDehackedApplier.Apply(const ALines: TArray<string>);
begin
  ApplyPatch(FParser.ParseLines(ALines));
end;

//==============================================================================
//
// TEngineDehackedApplier.ApplyPatch
// Applies a patch that the parser of Libs\Dehacked has read: the sections come
// in the order of the file and are applied in that order (the old DEH_Apply,
// in the style of the historic code)
//
//==============================================================================
procedure TEngineDehackedApplier.ApplyPatch(const APatch: IDehackedPatch);
var
  sectionindex: integer;
  section: TDehackedSection;
  entry: TDehackedEntry;
  entryindex: integer;
  i, j: integer;
  stmp: string;
  token1: string;
  token2: string;

  mobj_no: integer;
  mobj_val: integer;
  state_no: integer;
  newstate: boolean;
  ammo_no: integer;
  weapon_no: integer;
  weapon_val: integer;
  sound_no: integer;
  music_idx: integer;
  sprite_idx: integer;
  sprite_val: integer;
  group: integer; // MBF21
  foundtext: boolean;
  len1, len2: integer;
  settext: string;
  did_max_soulsphere: boolean;
  par_episode: integer;
  par_map: integer;
  par_time: integer;

  deh_initialstates: integer;
  code_ptrs: Pactionf_tArray;

  function StateValue(const ent: TDehackedEntry): integer;
  begin
    case ent.StateRef.Kind of
      srNew: result := ent.StateRef.Number + deh_initialstates;
    else
      result := ent.StateRef.Number;
    end;
  end;

  procedure SetActionParams(const stnum: integer; const args: string);
  begin
    if states[stnum].params <> nil then
      begin
        states[stnum].params.Free;
        states[stnum].params := nil;
      end;
    if args <> '' then
      states[stnum].params := TCustomParamList.Create(TScannerText.FixParenthesisLevel(args), FEvaluator);
  end;

  function FindActionByName(const aname: string): integer;
  begin
    result := DEH_FindActionByName(aname);
  end;

  procedure ApplyThing;
  var
    istransparent, isfriend, isbouncy: boolean;
    entryindex: integer;
  begin
    if section.Reference.IsNew then
    begin
      if devparm then
      begin
        printf('DEH_Parse(): Expanding mobjinfo table...'#13#10);
        if section.Reference.Name <> '' then
          printf('             Adding %s mobj'#13#10, [section.Reference.Name]);
      end;
      mobj_no := Info_GetNewMobjInfo;
      Info_SetMobjName(mobj_no, section.Reference.Name);
    end
    else
    begin
      mobj_no := section.Reference.Number;
      if (mobj_no <= 0) or (mobj_no > nummobjtypes) then
      begin
        I_Warning('DEH_Parse(): Wrong think number = %d'#13#10, [mobj_no]);
        exit;
      end;
      dec(mobj_no); // JVAL DEH patches start Think numbers from 1
    end;

    istransparent := section.ExtraFlags and 1 <> 0;
    isfriend := section.ExtraFlags and 2 <> 0;
    isbouncy := section.ExtraFlags and 4 <> 0;

    for entryindex := 0 to section.Count - 1 do
    begin
      entry := section[entryindex];
      token2 := entry.Text;
      mobj_val := entry.Number;
      if entry.Mbf21 then
        ismbf21 := true;

      case entry.Field of
         0: mobjinfo[mobj_no].doomednum := mobj_val;
         1: mobjinfo[mobj_no].spawnstate := StateValue(entry);
         2: mobjinfo[mobj_no].spawnhealth := mobj_val;
         3: mobjinfo[mobj_no].seestate := StateValue(entry);
         4: mobjinfo[mobj_no].seesound := S_GetSoundNumForName(token2);
         5: mobjinfo[mobj_no].reactiontime := mobj_val;
         6: mobjinfo[mobj_no].attacksound := S_GetSoundNumForName(token2);
         7: mobjinfo[mobj_no].painstate := StateValue(entry);
         8: mobjinfo[mobj_no].painchance := mobj_val;
         9: mobjinfo[mobj_no].painsound := S_GetSoundNumForName(token2);
        10: mobjinfo[mobj_no].meleestate := StateValue(entry);
        11: mobjinfo[mobj_no].missilestate := StateValue(entry);
        12: mobjinfo[mobj_no].deathstate := StateValue(entry);
        13: mobjinfo[mobj_no].xdeathstate := StateValue(entry);
        14: mobjinfo[mobj_no].deathsound := S_GetSoundNumForName(token2);
        15: mobjinfo[mobj_no].speed := mobj_val;
        16: mobjinfo[mobj_no].radius := mobj_val;
        17: mobjinfo[mobj_no].height := mobj_val;
        18: mobjinfo[mobj_no].mass := mobj_val;
        19: mobjinfo[mobj_no].damage := mobj_val;
        20: mobjinfo[mobj_no].activesound := S_GetSoundNumForName(token2);
        21: if entry.HasFlags then
              mobjinfo[mobj_no].flags := entry.Flags;
        22: if entry.HasFlags then
              mobjinfo[mobj_no].flags2 := entry.Flags;
        23: mobjinfo[mobj_no].raisestate := StateValue(entry);
        24: if entry.HasFlags then
              mobjinfo[mobj_no].flags_ex := entry.Flags;
        25: mobjinfo[mobj_no].customsound1 := S_GetSoundNumForName(token2); // DelphiDoom specific
        26: mobjinfo[mobj_no].customsound2 := S_GetSoundNumForName(token2); // DelphiDoom specific
        27: mobjinfo[mobj_no].customsound3 := S_GetSoundNumForName(token2); // DelphiDoom specific
        28: mobjinfo[mobj_no].explosiondamage := mobj_val;
        29: mobjinfo[mobj_no].explosionradius := mobj_val;
        30: mobjinfo[mobj_no].meleedamage := mobj_val;
        31: begin
              mobjinfo[mobj_no].inheritsfrom := Info_GetMobjNumForName(token2);
              if mobjinfo[mobj_no].inheritsfrom = mobj_no then
                mobjinfo[mobj_no].inheritsfrom := -1;
            end;
        32: Info_SetMobjName(mobj_no, token2);
        33: mobjinfo[mobj_no].meleesound := S_GetSoundNumForName(token2);
        34: begin
              if mobj_val >= 0 then
              begin
                if mobj_val < Ord(NUMMOBJRENDERSTYLES) then
                  mobjinfo[mobj_no].renderstyle := mobjrenderstyle_t(mobj_val)
                else
                  I_Warning('DEH_Parse(): Wrong renderstyle = %s (Think number = %d).'#13#10, [token2, mobj_no]);
              end
              else
              begin
                mobj_val := Ord(R_GetRenderstyleForName(token2));
                if mobj_val >= 0 then
                  mobjinfo[mobj_no].renderstyle := mobjrenderstyle_t(mobj_val)
                else
                  I_Warning('DEH_Parse(): Wrong renderstyle = %s (Think number = %d).'#13#10, [token2, mobj_no])
              end;
            end;
        35: mobjinfo[mobj_no].alpha := mobj_val;
        36: mobjinfo[mobj_no].dropitem := Info_GetMobjNumForName(token2);
        37: mobjinfo[mobj_no].missiletype := Info_GetMobjNumForName(token2);
        38: mobjinfo[mobj_no].healstate := StateValue(entry);
        39: if entry.HasFlags then
              mobjinfo[mobj_no].flags2_ex := entry.Flags;
        40: mobjinfo[mobj_no].crashstate := StateValue(entry);
        64: mobjinfo[mobj_no].interactstate := StateValue(entry);
        78: mobjinfo[mobj_no].missileheight := mobj_val;
        41: mobjinfo[mobj_no].vspeed := mobj_val;
        42: mobjinfo[mobj_no].pushfactor := entry.Fixed;
        43: mobjinfo[mobj_no].scale := entry.Fixed;
        44: mobjinfo[mobj_no].gravity := entry.Fixed;
        45: if entry.HasFlags then
              mobjinfo[mobj_no].flags3_ex := entry.Flags;
        46: if entry.HasFlags then
              mobjinfo[mobj_no].flags4_ex := entry.Flags;
        47: mobjinfo[mobj_no].minmissilechance := mobj_val;
        48: mobjinfo[mobj_no].floatspeed := mobj_val;
        49: mobjinfo[mobj_no].normalspeed := mobj_val;
        50: mobjinfo[mobj_no].fastspeed := mobj_val;
        51: mobjinfo[mobj_no].obituary := token2;
        52: mobjinfo[mobj_no].hitobituary := token2;
        53: begin
              if mobj_val >= 0 then
              begin
                if mobj_val < Ord(NUMGENDERS) then
                  mobjinfo[mobj_no].gender := gender_t(mobj_val)
                else
                  I_Warning('DEH_Parse(): Wrong gender = %s (Think number = %d).'#13#10, [token2, mobj_no]);
              end
              else
              begin
                mobj_val := Ord(TObituaryGenders.FindByName(token2));
                if mobj_val >= 0 then
                  mobjinfo[mobj_no].gender := gender_t(mobj_val)
                else
                  I_Warning('DEH_Parse(): Wrong gender = %s (Think number = %d).'#13#10, [token2, mobj_no])
              end;
            end;
        54: mobjinfo[mobj_no].meleerange := mobj_val;
        55: mobjinfo[mobj_no].maxstepheight := entry.Fixed;
        56: mobjinfo[mobj_no].maxdropoffheight := entry.Fixed;
        57: mobjinfo[mobj_no].gibhealth := mobj_val;
        58: mobjinfo[mobj_no].maxtargetrange := mobj_val;
        59: mobjinfo[mobj_no].WeaveIndexXY := mobj_val;
        60: mobjinfo[mobj_no].WeaveIndexZ := mobj_val;
        61: mobjinfo[mobj_no].friction := entry.Fixed;
        62: mobjinfo[mobj_no].spriteDX := entry.Fixed;
        63: mobjinfo[mobj_no].spriteDY := entry.Fixed;
        65: if entry.HasFlags then
              mobjinfo[mobj_no].flags5_ex := entry.Flags;
        66: if entry.HasFlags then
              mobjinfo[mobj_no].flags6_ex := entry.Flags;
        67: if entry.HasFlags then // .mbf21flags
              mobjinfo[mobj_no].mbf21bits := entry.Flags;
        68: begin // .infighting_group (MBF21)
              group := Info_InfightingGroupToInt(token2);
              if group <> IG_INVALID then
                mobjinfo[mobj_no].infighting_group := group;
            end;
        69: begin // .projectile_group (MBF21)
              group := Info_ProjectileGroupToInt(token2);
              if group <> PG_INVALID then
                mobjinfo[mobj_no].projectile_group := group;
            end;
        70: begin // .splash_group (MBF21)
              group := Info_SplashGroupToInt(token2);
              if group <> SG_INVALID then
                mobjinfo[mobj_no].splash_group := group;
            end;
        71: mobjinfo[mobj_no].ripsound := S_GetSoundNumForName(token2); // .ripsound (MBF21)
        72: mobjinfo[mobj_no].crushstate := StateValue(entry);
        75: mobjinfo[mobj_no].bloodcolor := TTranslationBlood.IdForName(token2);
        76: mobjinfo[mobj_no].translationname := strupper(token2);
        79: mobjinfo[mobj_no].meleethreshold := mobj_val;
      end;
    end;

    if istransparent then
      mobjinfo[mobj_no].flags_ex := mobjinfo[mobj_no].flags_ex or MF_EX_TRANSPARENT;
    if isfriend then
      mobjinfo[mobj_no].flags2_ex := mobjinfo[mobj_no].flags2_ex or MF2_EX_FRIEND;
    if isbouncy then
      mobjinfo[mobj_no].flags3_ex := mobjinfo[mobj_no].flags3_ex or MF3_EX_BOUNCE;

    P_ResolveMBF21Flags(@mobjinfo[mobj_no]);
  end;

  procedure ApplyFrame;
  var
    fidx: integer;
    ent: TDehackedEntry;
    act: integer;
  begin
    newstate := section.Reference.IsNew;
    if newstate then
    begin
      state_no := section.Reference.Number + deh_initialstates;
      if devparm then
        printf('DEH_Parse(): Expanding states table, new state number found: %d'#13#10, [state_no]);
    end
    else
    begin
      state_no := section.Reference.Number;
      if state_no < 0 then
        state_no := statenames.IndexOfToken(section.Reference.Name);
      if state_no < 0 then
      begin
        I_Warning('DEH_Parse(): Wrong state number = %s'#13#10, [section.Reference.Name]);
        exit;
      end;
    end;
    while numstates <= state_no do
      Info_GetNewState;
    SC_FillStateNames;

    for fidx := 0 to section.Count - 1 do
    begin
      ent := section[fidx];
      case ent.Field of
         0: states[state_no].sprite := Info_GetSpriteNumForName(ent.Text);
         1: if ent.Bright then
              states[state_no].frame := FF_FULLBRIGHT + ent.Number
            else
              states[state_no].frame := ent.Number;
         2: states[state_no].tics := ent.Number;
         3: begin
              if ent.StateRef.Kind = srOriginal then
                states[state_no].nextstate := statenum_t(ent.StateRef.Number)
              else if ent.StateRef.Kind = srNew then
                states[state_no].nextstate := statenum_t(deh_initialstates + ent.StateRef.Number)
              else if statenames.IndexOfToken(ent.Text) >= 0 then
                states[state_no].nextstate := statenum_t(statenames.IndexOfToken(ent.Text))
              else if newstate then
                states[state_no].nextstate := statenum_t(deh_initialstates + ent.Number)
              else
                states[state_no].nextstate := statenum_t(ent.Number);
            end;
         4: begin
              if ent.Number >= 0 then
              begin
                if ent.Number < DEH_ActionCount then
                  states[state_no].action.acp1 := DEH_ActionProc(ent.Number)
                else
                  I_Warning('DEH_Parse(): Wrong action number = %d in state %d (Must be in [0..%d])'#13#10, [ent.Number, state_no, DEH_ActionCount]);
              end
              else
              begin
                act := FindActionByName(ent.ActionName);
                if act >= 0 then
                begin
                  states[state_no].action.acp1 := DEH_ActionProc(act);
                  SetActionParams(state_no, ent.ActionArguments);
                end
                else
                  I_Warning('DEH_Parse(): Unknown action function = "%s" in state %d'#13#10, [ent.ActionName, state_no]);
              end;
            end;
         5: states[state_no].misc1 := ent.Number;
         6: states[state_no].misc2 := ent.Number;
         7: if ent.HasFlags then
              states[state_no].flags_ex := ent.Flags;
         8: Info_AddStateOwner(@states[state_no], Info_GetMobjNumForName(ent.Text));
         9: states[state_no].tics2 := ent.Number;
        10: begin
              states[state_no].args[0] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG1_DEFINED;
            end;
        11: begin
              states[state_no].args[1] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG2_DEFINED;
            end;
        12: begin
              states[state_no].args[2] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG3_DEFINED;
            end;
        13: begin
              states[state_no].args[3] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG4_DEFINED;
            end;
        14: begin
              states[state_no].args[4] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG5_DEFINED;
            end;
        15: begin
              states[state_no].args[5] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG6_DEFINED;
            end;
        16: begin
              states[state_no].args[6] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG7_DEFINED;
            end;
        17: begin
              states[state_no].args[7] := ent.Number;  // MBF21
              states[state_no].argsdefined := states[state_no].argsdefined or ARG8_DEFINED;
            end;
        18: if ent.HasFlags then // MBF21
              states[state_no].mbf21bits := ent.Flags;
      end;
    end;

    // MBF21
    if states[state_no].mbf21bits <> 0 then
      ismbf21 := true;
  end;

  procedure ApplyText;
  var
    j: integer;
  begin
    len1 := section.OldLength;
    len2 := section.NewLength;
    settext := section.OldText;
    token1 := DEH_StringValue(settext);
    token2 := section.NewText;

    foundtext := false;
    for j := 0 to deh_strings.numstrings - 1 do
      if DEH_StringValue(deh_strings._array[j].pstr^) = token1 then
      begin
        foundtext := true;
        deh_strings._array[j].pstr^ := DEH_CStringToString(token2);
        break;
      end;

    if not foundtext then
    begin
      for j := 1 to nummusic - 1 do // First music is dummy
      begin
        stmp := strupper(S_music[j].name);
        if stmp = token1 then
        begin
          foundtext := true;
          S_music[j].name := token2;
          break;
        end
        else if 'D_' + stmp = token1 then // JVAL Allow D_ prefix for checking
        begin
          foundtext := true;
          S_music[j].name := token2;
          break;
        end
        else if strupper(S_music[j].mapname) = token1 then
        begin
          foundtext := true;
          S_music[j].name := token2;
          break;
        end
      end;

      if not foundtext and (len1 = 4) and (len2 = 4) then
      begin
        for j := 0 to numsprites - 1 do
        begin
          stmp := Chr(sprnames[j] and $FF) +
                  Chr(sprnames[j] shr 8 and $FF) +
                  Chr(sprnames[j] shr 16 and $FF) +
                  Chr(sprnames[j] shr 24 and $FF);
          if stmp = token1 then
          begin
            sprnames[j] := Ord(toupper(token2[1])) +
                           Ord(toupper(token2[2])) shl 8 +
                           Ord(toupper(token2[3])) shl 16 +
                           Ord(toupper(token2[4])) shl 24;
            foundtext := true;
            break;
          end;
        end;
      end;
    end;

    if not foundtext then
      I_Warning('DEH_Parse(): Can not find setable text "%s" - should be changed to "%s"'#13#10, [settext, token2]);
  end;

  procedure ApplyPointer;
  var
    frame_no: integer;
    value: integer;
  begin
    frame_no := section.Reference.Number;
    value := section[0].Number;
    if (value >= 0) and (value < numstates) then
    begin
      if (frame_no >= numstates) then
        exit;
      // JVAL: 20201203 - Preserve initial actions
      if value < deh_initialstates then
        states[frame_no].action.acp1 := code_ptrs[value].acp1
      else
        states[frame_no].action.acp1 := states[value].action.acp1;
    end
    else
      I_Warning('DEH_Parse(): Invalid state number "%s" while parsing CODEP FRAME'#13#10, [section[0].Text]);
  end;

  procedure ApplySound;
  var
    sidx: integer;
    ent: TDehackedEntry;
  begin
    stmp := section.Reference.Name;
    if stmp = '' then
      exit;
    if not (stmp[1] in ['1'..'9', '0']) then
      sound_no := S_GetSoundNumForName(stmp)
    else
    begin
      sound_no := section.Reference.Number;
      if (sound_no < 0) or (sound_no >= numsfx) then
      begin
        I_Warning('DEH_Parse(): Wrong sound number = %s'#13#10, [stmp]);
        if sound_no >= numsfx then
          I_Warning('DEH_Parse(): New sounds can only specified in things definition!'#13#10);
        exit;
      end;
    end;

    for sidx := 0 to section.Count - 1 do
    begin
      ent := section[sidx];
      case ent.Field of
        0: S_sfx[sound_no].singularity := ent.Number <> 0;
        1: S_sfx[sound_no].priority := ent.Number;
        2: S_sfx[sound_no].name := ent.Text;
      end;
    end;
  end;

  procedure ApplyAmmo;
  var
    aidx: integer;
    ent: TDehackedEntry;
  begin
    ammo_no := section.Reference.Number;
    if (ammo_no < 0) or (ammo_no >= Ord(NUMAMMO)) then
    begin
      I_Warning('DEH_Parse(): Wrong ammo number = %s'#13#10, [itoa(ammo_no)]);
      exit;
    end;
    for aidx := 0 to section.Count - 1 do
    begin
      ent := section[aidx];
      case ent.Field of
        0: maxammo[ammo_no] := ent.Number;
      end;
    end;
  end;

  procedure ApplyWeapon;
  var
    widx: integer;
    ent: TDehackedEntry;
    weapon_level: integer;
    weaponinfo_p: Pweaponinfo_tArray;
  begin
    stmp := section.Reference.Name;
    weapon_no := section.Reference.Number;
    if weapon_no < 0 then
      weapon_no := DEH_WeaponType(stmp);
    if (weapon_no < 0) or (weapon_no >= Ord(NUMWEAPONS)) then
    begin
      if stmp = '' then
        stmp := itoa(section.Reference.Number);
      I_Warning('DEH_Parse(): Wrong weapon number = %s'#13#10, [stmp]);
      exit;
    end;

    weapon_level := 1;
    for widx := 0 to section.Count - 1 do
    begin
      ent := section[widx];
      if ent.Field = 7 then
      begin
        weapon_level := ent.Number;
        continue;
      end;

      if weapon_level = 1 then
        weaponinfo_p := @wpnlev1info
      else
        weaponinfo_p := @wpnlev2info;

      case ent.Field of
        0: begin
             weapon_val := ent.Number;
             if weapon_val < 0 then
               weapon_val := DEH_AmmoType(ent.Text);
             if weapon_val < 0 then
               I_Warning('DEH_Parse(): After %s keyword found invalid ammo %s (Weapon number = %d)'#13#10, [ent.FieldName, ent.Text, weapon_no]);
             weaponinfo_p[weapon_no].ammo := ammotype_t(weapon_val);
           end;
        1: weaponinfo_p[weapon_no].upstate := StateValue(ent);
        2: weaponinfo_p[weapon_no].downstate := StateValue(ent);
        3: weaponinfo_p[weapon_no].readystate := StateValue(ent);
        4: weaponinfo_p[weapon_no].atkstate := StateValue(ent);
        6: weaponinfo_p[weapon_no].holdatkstate := StateValue(ent);
        5: weaponinfo_p[weapon_no].flashstate := StateValue(ent);
        8: begin
             if weapon_level = 1 then
               WeaponAmmoUsePL1[weapon_no] := ent.Number
             else
               WeaponAmmoUsePL2[weapon_no] := ent.Number;
             weaponinfo_p[weapon_no].intflags := weaponinfo_p[weapon_no].intflags or WIF_ENABLEAPS;
           end;
        9: if ent.HasFlags then // MBF21
             weaponinfo_p[weapon_no].mbf21bits := ent.Flags;
      end;
    end;
  end;

  procedure ApplySprites;
  var
    j: integer;
    pidx: integer;
    ent: TDehackedEntry;
  begin
    for pidx := 0 to section.Count - 1 do
    begin
      ent := section[pidx];
      token1 := ent.Key;
      token2 := ent.Text;

      sprite_idx := -1;
      sprite_val := ent.Number;
      if IsIntegerInRange(sprite_val, 0, Ord(DO_NUMSPRITES) - 1) then
      begin
        sprite_idx := sprite_val;
        token1 := DO_sprnames[sprite_idx];
      end
      else if (numsprites >= Ord(DO_NUMSPRITES)) and IsIntegerInRange(sprite_val, Ord(DO_NUMSPRITES), numsprites) then
      begin
        sprite_idx := sprite_val;
        token1 := Chr(sprnames[sprite_idx] and $FF) +
                  Chr(sprnames[sprite_idx] shr 8 and $FF) +
                  Chr(sprnames[sprite_idx] shr 16 and $FF) +
                  Chr(sprnames[sprite_idx] shr 24 and $FF);
      end;

      if length(token1) <> 4 then
      begin
        I_Warning('DEH_Parse(): Sprite name with %d characters = %s'#13#10, [length(token1), token1]);
        Continue;
      end;

      strupperproc(token1);
      strupperproc(token2);

      // JVAL: Check the original sprite names (https://eternity.youfailit.net/wiki/DeHackEd_/_BEX_Reference/Eternity_Extension:_SPRITES_Block)
      if sprite_idx < 0 then
      begin
        for j := 0 to Ord(DO_NUMSPRITES) - 1 do
          if DO_sprnames[j] = token1 then
          begin
            sprite_idx := j;
            break;
          end;
        if sprite_idx < 0 then
          for j := Ord(DO_NUMSPRITES) to numsprites - 1 do
            if Chr(sprnames[j] and $FF) + Chr(sprnames[j] shr 8 and $FF) +
              Chr(sprnames[j] shr 16 and $FF) + Chr(sprnames[j] shr 24 and $FF) = token1 then
            begin
              sprite_idx := j;
              break;
            end;
      end;

      if sprite_idx < 0 then
      begin
        I_Warning('DEH_Parse(): Can not find sprite = %s'#13#10, [token1]);
        Continue;
      end;

      sprnames[sprite_idx] :=
        Ord(token2[1]) +
        Ord(token2[2]) shl 8 +
        Ord(token2[3]) shl 16 +
        Ord(token2[4]) shl 24;
    end;
  end;

  procedure ApplyMisc;
  var
    midx: integer;
    ent: TDehackedEntry;
  begin
    for midx := 0 to section.Count - 1 do
    begin
      ent := section[midx];
      case ent.Field of
        0: p_maxhealth := ent.Number;
        1: p_soulspherehealth := ent.Number;
        2: p_megaspherehealth := ent.Number;
        3: p_medikithealth := ent.Number;
        4: p_stimpackhealth := ent.Number;
        5: p_bonushealth := ent.Number;
        6: p_maxarmor := ent.Number;
        7: p_greenarmorclass := ent.Number;
        8: p_bluearmorclass := ent.Number;
        9: p_maxchickenhealth := ent.Number;
       10: p_maxartifacts := ent.Number;
      end;
    end;
  end;

  procedure ApplyPars;
  var
    pidx: integer;
    ent: TDehackedEntry;
  begin
    for pidx := 0 to section.Count - 1 do
    begin
      ent := section[pidx];
      if Length(ent.Numbers) >= 3 then
      begin // Doom1, Ultimate Doom
        par_episode := ent.Numbers[0];
        par_map := ent.Numbers[1];
        par_time := ent.Numbers[2];
        if par_episode in [1, 2, 3, 4, 5] then
          if par_map in [1..9] then
            if par_time >= 0 then // JVAL =0 ????
              pars[par_episode, par_map] := par_time;
      end
      else if Length(ent.Numbers) = 2 then
      begin
        I_Warning('DEH_Parse(): Wrong misc value %s, field = %s'#13#10, [itoa(ent.Numbers[0]), 'PAR']);
      end;
    end;
  end;

  procedure ApplyStrings;
  var
    j: integer;
    sidx: integer;
    ent: TDehackedEntry;
  begin
    for sidx := 0 to section.Count - 1 do
    begin
      ent := section[sidx];
      for j := 0 to deh_strings.numstrings - 1 do
        if deh_strings._array[j].name = ent.Key then
        begin
          deh_strings._array[j].pstr^ := DEH_CStringToString(ent.Text);
          break;
        end;
    end;
  end;

  procedure ApplyCodePointers;
  var
    cidx: integer;
    ent: TDehackedEntry;
    act: integer;
  begin
    for cidx := 0 to section.Count - 1 do
    begin
      ent := section[cidx];
      state_no := ent.Numbers[0];
      if state_no >= numstates then
        continue;

      if ent.Number >= 0 then
      begin
        if ent.Number < DEH_ActionCount then
          states[state_no].action.acp1 := DEH_ActionProc(ent.Number);
      end
      else
      begin
        act := DEH_SearchActionFromHash(ent.Text);
        if act < 0 then
          act := FindActionByName(ent.ActionName);
        if act >= 0 then
          states[state_no].action.acp1 := DEH_ActionProc(act);
        SetActionParams(state_no, ent.ActionArguments);
      end;
    end;
  end;

  procedure ApplyMusic;
  var
    j: integer;
    midx: integer;
    ent: TDehackedEntry;
  begin
    for midx := 0 to section.Count - 1 do
    begin
      ent := section[midx];
      token1 := ent.Key;
      token2 := ent.Text;
      music_idx := ent.Number;
      if (music_idx >= 1) and (music_idx < nummusic) then
        S_music[music_idx].name := token2
      else
      begin
        for j := 1 to nummusic - 1 do // First music is dummy
        begin
          stmp := strupper(S_music[j].name);
          if stmp = token1 then
          begin
            S_music[j].name := token2;
            break;
          end
          else if 'MUS_' + stmp = token1 then // JVAL Allow D_ prefix for checking
          begin
            S_music[j].name := token2;
            break;
          end
          else if strupper(S_music[j].mapname) = token1 then
          begin
            S_music[j].name := token2;
            break;
          end
        end;
      end;
    end;
  end;

  procedure ApplySounds;
  var
    j: integer;
    sidx: integer;
    ent: TDehackedEntry;
  begin
    for sidx := 0 to section.Count - 1 do
    begin
      ent := section[sidx];
      token1 := ent.Key;
      token2 := ent.Text;
      sound_no := ent.Number;
      if (sound_no >= 1) and (sound_no < numsfx) then
        S_sfx[sound_no].name := token2
      else
      begin
        for j := 1 to numsfx - 1 do // First sfx is dummy
        begin
          stmp := strupper(S_sfx[j].name);
          if stmp = token1 then
          begin
            S_sfx[j].name := token2;
            break;
          end
          else if 'DS' + stmp = token1 then // JVAL, check the 'DS' prefix
          begin
            S_sfx[j].name := token2;
            break;
          end;
        end;
      end;
    end;
  end;

begin
  // DEH_Init does nothing after the first call
  DEH_Init;

  deh_initialstates := numstates;

  // JVAL: 20201203 - Preserve initial actions
  code_ptrs := mallocz(deh_initialstates * SizeOf(actionf_t));
  for i := 0 to numstates - 1 do
    code_ptrs[i] := states[i].action;

  for sectionindex := 0 to APatch.SectionCount - 1 do
  begin
    section := APatch.Section(sectionindex);
    case section.Kind of
      dskThing: ApplyThing;
      dskFrame: ApplyFrame;
      dskText: ApplyText;
      dskPointer: ApplyPointer;
      dskSound: ApplySound;
      dskAmmo: ApplyAmmo;
      dskWeapon: ApplyWeapon;
      dskSprites: ApplySprites;
      dskCheat: ;
      dskMisc: ApplyMisc;
      dskPars: ApplyPars;
      dskStrings: ApplyStrings;
      dskCodePointers: ApplyCodePointers;
      dskMusic: ApplyMusic;
      dskSounds: ApplySounds;
      dskSubmitNewStates:
        begin
          // JVAL: 20201203 - Preserve initial actions
          realloc(pointer(code_ptrs), deh_initialstates * SizeOf(actionf_t), numstates * SizeOf(actionf_t));
          for j := 0 to numstates - 1 do
            code_ptrs[j] := states[j].action;

          // Resetting internal states counter
          deh_initialstates := numstates;
        end;
    end;
  end;

  // JVAL: 20201203 - Preserve initial actions
  memfree(pointer(code_ptrs), numstates * SizeOf(actionf_t));
end;

end.
