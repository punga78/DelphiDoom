{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the profiles of the games                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Games;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Intf;

type
  TDehackedGame = (dgDoom, dgHeretic, dgHexen, dgStrife);

  /// <summary>
  ///   The profile of each game: the blocks that its patches have and the fields and flags of
  ///   each one. The differences between the games are data here (the lists of names, the
  ///   counts of weapons and ammunition, the ranges of the par times), not conditional compilation
  /// </summary>
  TDehackedGames = class
  public
    /// <summary>DOOM, HERETIC, HEXEN or STRIFE</summary>
    class function NameOf(AGame: TDehackedGame): string; static;
    /// <summary>The game of a name, whatever the case of the letters; false if it is none of the four</summary>
    class function TryFromName(const AName: string; out AGame: TDehackedGame): Boolean; static;
    /// <param name="ALog">May be nil</param>
    class function CreateProfile(AGame: TDehackedGame; const ALog: ILog): IDehackedProfile; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.GameData,
  DelphiDoom.Dehacked.Data.Doom, DelphiDoom.Dehacked.Data.Heretic,
  DelphiDoom.Dehacked.Data.Hexen, DelphiDoom.Dehacked.Data.Strife,
  DelphiDoom.Dehacked.FieldTable, DelphiDoom.Dehacked.FieldKinds,
  DelphiDoom.Dehacked.FieldReader, DelphiDoom.Dehacked.FlagSet, DelphiDoom.Dehacked.FlagSets,
  DelphiDoom.Dehacked.Profile, DelphiDoom.Dehacked.Reader.Thing,
  DelphiDoom.Dehacked.Reader.Frame, DelphiDoom.Dehacked.Reader.Weapon,
  DelphiDoom.Dehacked.Reader.Ammo, DelphiDoom.Dehacked.Reader.Sound,
  DelphiDoom.Dehacked.Reader.Misc, DelphiDoom.Dehacked.Reader.Pars,
  DelphiDoom.Dehacked.Reader.Text, DelphiDoom.Dehacked.Reader.Pointer,
  DelphiDoom.Dehacked.Reader.Marker, DelphiDoom.Dehacked.Reader.Lines;

const
  GAME_NAMES: array[TDehackedGame] of string = ('DOOM', 'HERETIC', 'HEXEN', 'STRIFE');
  // the weapons and the kinds of ammunition of the games (weapontype_t and ammotype_t)
  WEAPON_COUNTS: array[TDehackedGame] of Integer = (9, 9, 4, 11);
  AMMO_COUNTS: array[TDehackedGame] of Integer = (4, 6, 0, 7);

function DataOf(AGame: TDehackedGame): TDehackedGameData;
begin
  case AGame of
    dgDoom: Result := TDehackedDoomData.Build;
    dgHeretic: Result := TDehackedHereticData.Build;
    dgHexen: Result := TDehackedHexenData.Build;
  else
    Result := TDehackedStrifeData.Build;
  end;
end;

function BuildFlagSets(const AData: TDehackedGameData; AGame: TDehackedGame): IDehackedFlagSets;
var
  LSets: TDehackedFlagSets;
  LExtraFrom: Integer;
begin
  LSets := TDehackedFlagSets.Create;
  Result := LSets;
  // the high bits of the flags of the things are the transparent, friend, bouncy and touchy
  // flags that DelphiDoom keeps elsewhere; Strife never had them
  if AGame = dgStrife then
    LExtraFrom := -1
  else
    LExtraFrom := 28;
  LSets.Add('MF', TDehackedFlagSet.Create(AData.MobjFlags, ['MF_'], nil, True, LExtraFrom));
  LSets.Add('MF2', TDehackedFlagSet.Create(AData.MobjFlags2, ['MF2_', 'MF_'], nil, True));
  LSets.Add('MF_EX', TDehackedFlagSet.Create(AData.MobjFlagsEx, ['MF_EX_', 'MF_'], nil, True));
  LSets.Add('MF2_EX', TDehackedFlagSet.Create(AData.MobjFlags2Ex, ['MF2_EX_'], nil, False));
  LSets.Add('MF3_EX', TDehackedFlagSet.Create(AData.MobjFlags3Ex, ['MF3_EX_'], nil, False));
  LSets.Add('MF4_EX', TDehackedFlagSet.Create(AData.MobjFlags4Ex, ['MF4_EX_'], nil, False));
  LSets.Add('MF5_EX', TDehackedFlagSet.Create(AData.MobjFlags5Ex, ['MF5_EX_'], nil, False));
  LSets.Add('MF6_EX', TDehackedFlagSet.Create(AData.MobjFlags6Ex, ['MF6_EX_'], nil, False));
  LSets.Add('MBF21', TDehackedFlagSet.Create(AData.MobjFlagsMbf21, nil, ['MF2_', 'MBM21_'], False));
  LSets.Add('STATE_EX', TDehackedFlagSet.Create(AData.StateFlagsEx, ['MF_EX_', 'MF_'], nil, False));
  LSets.Add('STATE_MBF21', TDehackedFlagSet.Create(AData.StateFlagsMbf21, nil, nil, False));
  LSets.Add('WEAPON_MBF21', TDehackedFlagSet.Create(AData.WeaponFlagsMbf21, nil, nil, False));
end;

function Messages(const AUnknown: string): TDehackedFieldMessages;
begin
  Result := Default(TDehackedFieldMessages);
  Result.UnknownField := AUnknown;
end;

{ TDehackedGames }

class function TDehackedGames.NameOf(AGame: TDehackedGame): string;
begin
  Result := GAME_NAMES[AGame];
end;

class function TDehackedGames.TryFromName(const AName: string; out AGame: TDehackedGame): Boolean;
var
  LGame: TDehackedGame;
begin
  for LGame := Low(TDehackedGame) to High(TDehackedGame) do
    if SameText(AName, GAME_NAMES[LGame]) then
    begin
      AGame := LGame;
      Exit(True);
    end;
  Result := False;
end;

class function TDehackedGames.CreateProfile(AGame: TDehackedGame; const ALog: ILog): IDehackedProfile;
var
  LData: TDehackedGameData;
  LSets: IDehackedFlagSets;
  LMessages: TDehackedFieldMessages;
  LReaders: TArray<IDehackedSectionReader>;
  LLimits: TDehackedParsLimits;

  procedure Add(const AReader: IDehackedSectionReader);
  begin
    SetLength(LReaders, Length(LReaders) + 1);
    LReaders[High(LReaders)] := AReader;
  end;

  function Fields(const ADefs: TArray<TDehackedFieldDef>; AStripQuotes: Boolean;
    const AMessages: TDehackedFieldMessages): TDehackedFieldReader;
  begin
    Result := TDehackedFieldReader.Create(TDehackedFieldTable.Create(ADefs), LSets, ALog,
      AStripQuotes, AMessages);
  end;

begin
  LData := DataOf(AGame);
  LSets := BuildFlagSets(LData, AGame);
  LReaders := nil;

  LMessages := Messages('DEH_Parse(): Wrong think field = %s (Think number = %d)'#13#10);
  LMessages.InvalidKeywordNumber :=
    'DEH_Parse(): After %s keyword found invalid numeric %s (Think number = %d)'#13#10;
  LMessages.Unsupported := 'DEH_Parse(): Unsupported Doom field: "%s".'#13#10;
  Add(TDehackedThingReader.Create(['THING', 'NEWTHING'], ALog,
    Fields(TDehackedFieldKinds.ThingDefs(LData.ThingFields, AGame in [dgHeretic, dgHexen]), True,
      LMessages)));

  Add(TDehackedFrameReader.Create(['FRAME', 'STATE'], ALog,
    Fields(TDehackedFieldKinds.FrameDefs(LData.FrameFields), False,
      Messages('DEH_Parse(): Wrong state field = %s (State number = %d)'#13#10))));

  Add(TDehackedTextReader.Create(['TEXT'], ALog));
  Add(TDehackedPointerReader.Create(['POINTER'], ALog));

  Add(TDehackedSoundReader.Create(['SOUND'], ALog,
    Fields(TDehackedFieldKinds.CountDefs(LData.SoundFields), False,
      Messages('DEH_Parse(): Wrong sound field = %s (Sound number = %d)'#13#10))));

  // Hexen has no ammunition (its mana is the field MAX MANA of Misc). The old parser also compared the word
  // of a line with 'MAX MANA', which has a space and can never be a word: that block was never read
  if AGame <> dgHexen then
    Add(TDehackedAmmoReader.Create(['AMMO'], ALog,
      Fields(TDehackedFieldKinds.CountDefs(LData.AmmoFields), False,
        Messages('DEH_Parse(): Wrong ammo field = %s (Ammo number = %d)'#13#10)),
      AMMO_COUNTS[AGame]));

  LMessages := Messages('DEH_Parse(): Wrong weapon field = %s (Weapon number = %d)'#13#10);
  LMessages.InvalidKeywordNumber :=
    'DEH_Parse(): After %s keyword found invalid numeric %s (Weapon number = %d)'#13#10;
  LMessages.PositiveExpected :=
    'DEH_Parse(): Positive number expected after keyword (%s) - (%s) (Weapon number = %d)'#13#10;
  LMessages.InvalidLevel :=
    'DEH_Parse(): After %s keyword found invalid level %s (Weapon number = %d)'#13#10;
  Add(TDehackedWeaponReader.Create(['WEAPON'], ALog,
    Fields(TDehackedFieldKinds.WeaponDefs(LData.WeaponFields), False, LMessages),
    WEAPON_COUNTS[AGame], AGame = dgHexen));

  Add(TDehackedLinesReader.Create(['[SPRITES]', 'SPRITES'], ALog, dlkSprites));
  Add(TDehackedMarkerReader.Create(['CHEAT'], ALog, dskCheat));
  Add(TDehackedMiscReader.Create(['MISC'], ALog, TDehackedFieldTable.Create(
    TDehackedFieldKinds.CountDefs(LData.MiscFields))));

  // Hexen and Strife have no par times
  if AGame in [dgDoom, dgHeretic] then
  begin
    if AGame = dgDoom then
    begin
      LLimits.Episodes := 3;
      LLimits.MapsPerEpisode := 9;
      LLimits.Maps := 32;
    end
    else
    begin
      LLimits.Episodes := 5;
      LLimits.MapsPerEpisode := 9;
      LLimits.Maps := 0;
    end;
    Add(TDehackedParsReader.Create(['[PARS]', 'PARS'], ALog, LLimits));
  end;

  Add(TDehackedLinesReader.Create(['[STRINGS]', 'STRINGS'], ALog, dlkStrings));
  Add(TDehackedLinesReader.Create(['[CODEPTR]', 'CODEPTR'], ALog, dlkCodePointers));
  Add(TDehackedLinesReader.Create(['[MUSIC]', 'MUSIC'], ALog, dlkMusic, AGame = dgHexen));
  Add(TDehackedLinesReader.Create(['[SOUND]', '[SOUNDS]'], ALog, dlkSounds));
  Add(TDehackedMarkerReader.Create(['SUBMITNEWSTATES', 'SUBMITNEWFRAMES'], ALog,
    dskSubmitNewStates));

  Result := TDehackedProfile.Create(GAME_NAMES[AGame], LReaders);
end;

end.
