{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Dehacked library - a stand-in for the engine       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Dehacked.DumpApplier;

interface

uses
  System.SysUtils, System.StrUtils, System.Generics.Collections, DelphiDoom.Dehacked.Types,
  DelphiDoom.Dehacked.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.GameData;

type
  /// <summary>
  ///   What the engine does with the blocks of a Doom patch, written down in the form of the dump
  ///   of DEH_CurrentSettings: "header|field=value" for each field that the patch changes. The
  ///   golden files hold the lines that the old parser changed in that dump; the library has to
  ///   explain the same lines. Whatever depends on the tables of the engine (the names of the
  ///   sounds, the sprites, the actions, the strings) is not resolved: those lines are "soft"
  /// </summary>
  TDehackedSectionKinds = set of TDehackedSectionKind;

  TDumpApplier = class
  private
    FData: TDehackedGameData;
    FKinds: TDehackedSectionKinds;
    FBase: Integer;
    FTop: Integer;
    FChanges: TDictionary<string, string>;
    FOrder: TList<string>;
    FSoftHeaders: TList<string>;
    FOldStrings: TDictionary<string, string>;
    procedure SetValue(const AHeader, AField, AValue: string);
    procedure Soft(const AHeader: string);
    function StateValue(const ARef: Integer; AKind: Integer; AIsNew: Boolean): Integer;
    function FlagsText(const ANames: TArray<string>; AMask: Integer): string;
    procedure ApplyThing(ASection: TDehackedSection);
    procedure ApplyFrame(ASection: TDehackedSection);
    procedure ApplyWeapon(ASection: TDehackedSection);
    procedure ApplyAmmo(ASection: TDehackedSection);
    procedure ApplyMisc(ASection: TDehackedSection);
    procedure ApplyPars(ASection: TDehackedSection);
    procedure ApplyStrings(ASection: TDehackedSection);
    procedure ApplyText(ASection: TDehackedSection);
    procedure ApplyMusic(ASection: TDehackedSection);
    procedure ApplySounds(ASection: TDehackedSection);
    procedure ApplySprites(ASection: TDehackedSection);
    procedure ApplySound(ASection: TDehackedSection);
  public
    /// <param name="ABase">The number of states of the engine before the patch</param>
    /// <param name="AOldStrings">The strings of the engine that the golden file says were changed, as "[Strings]|NAME=text" before</param>
    /// <param name="AKinds">The blocks that are applied; the other games have other headers for the weapons, so only some are</param>
    constructor Create(const AData: TDehackedGameData; ABase: Integer; AOldStrings: TDictionary<string, string>;
      AKinds: TDehackedSectionKinds);
    destructor Destroy; override;
    procedure Apply(const APatch: IDehackedPatch);
    /// <summary>The changes: "header|field" and the value</summary>
    property Changes: TDictionary<string, string> read FChanges;
    /// <summary>The headers of the lines that cannot be explained completely (new elements, names that need the engine)</summary>
    property SoftHeaders: TList<string> read FSoftHeaders;
  end;

/// <summary>capitalizedstring of d_delphi: the letters in lower case but the first and those after a space</summary>
function Capitalized(const AText: string): string;

implementation

uses
  System.Classes, DelphiDoom.Dehacked.Text, DelphiDoom.Dehacked.Strings;

const
  WEAPON_NAMES: array[0..8] of string = ('WP_FIST', 'WP_PISTOL', 'WP_SHOTGUN', 'WP_CHAINGUN',
    'WP_MISSILE', 'WP_PLASMA', 'WP_BFG', 'WP_CHAINSAW', 'WP_SUPERSHOTGUN');
  AMMO_NAMES: array[0..3] of string = ('AM_CLIP', 'AM_SHELL', 'AM_CELL', 'AM_MISL');
  NUM_MUSIC = 68;
  NUM_SFX = 699;
  FF_FULLBRIGHT = $8000;

function Capitalized(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := LowerCase(AText);
  if Result = '' then
    Exit;
  Result[1] := UpCase(Result[1]);
  for LIndex := 2 to Length(Result) do
    if Result[LIndex - 1] = ' ' then
      Result[LIndex] := UpCase(Result[LIndex]);
end;

{ TDumpApplier }

constructor TDumpApplier.Create(const AData: TDehackedGameData; ABase: Integer;
  AOldStrings: TDictionary<string, string>; AKinds: TDehackedSectionKinds);
begin
  inherited Create;
  FData := AData;
  FKinds := AKinds;
  FBase := ABase;
  FTop := ABase;
  FOldStrings := AOldStrings;
  FChanges := TDictionary<string, string>.Create;
  FOrder := TList<string>.Create;
  FSoftHeaders := TList<string>.Create;
end;

destructor TDumpApplier.Destroy;
begin
  FSoftHeaders.Free;
  FOrder.Free;
  FChanges.Free;
  inherited Destroy;
end;

procedure TDumpApplier.SetValue(const AHeader, AField, AValue: string);
begin
  FChanges.AddOrSetValue(AHeader + '|' + AField, AValue);
end;

procedure TDumpApplier.Soft(const AHeader: string);
begin
  if not FSoftHeaders.Contains(AHeader) then
    FSoftHeaders.Add(AHeader);
end;

function TDumpApplier.StateValue(const ARef: Integer; AKind: Integer; AIsNew: Boolean): Integer;
begin
  case TDehackedStateRefKind(AKind) of
    srNew: Result := FBase + ARef;
    srOriginal: Result := ARef;
  else
    Result := ARef;
  end;
end;

function TDumpApplier.FlagsText(const ANames: TArray<string>; AMask: Integer): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(ANames) do
    if AMask and (1 shl LIndex) <> 0 then
    begin
      if Result <> '' then
        Result := Result + ', ';
      Result := Result + ANames[LIndex];
    end;
  if Result = '' then
    Result := '0';
end;

procedure TDumpApplier.Apply(const APatch: IDehackedPatch);
var
  LIndex: Integer;
  LSection: TDehackedSection;
begin
  for LIndex := 0 to APatch.SectionCount - 1 do
  begin
    LSection := APatch.Section(LIndex);
    if not (LSection.Kind in FKinds) then
      Continue;
    case LSection.Kind of
      dskThing: ApplyThing(LSection);
      dskFrame: ApplyFrame(LSection);
      dskWeapon: ApplyWeapon(LSection);
      dskAmmo: ApplyAmmo(LSection);
      dskMisc: ApplyMisc(LSection);
      dskPars: ApplyPars(LSection);
      dskStrings: ApplyStrings(LSection);
      dskText: ApplyText(LSection);
      dskMusic: ApplyMusic(LSection);
      dskSounds: ApplySounds(LSection);
      dskSprites: ApplySprites(LSection);
      dskSound: ApplySound(LSection);
      dskSubmitNewStates: FBase := FTop; // the new states of the patch become original ones
    end;
  end;
end;

procedure TDumpApplier.ApplyThing(ASection: TDehackedSection);
const
  SOUND_FIELDS: array[0..9] of string = ('ALERT SOUND', 'ATTACK SOUND', 'PAIN SOUND',
    'DEATH SOUND', 'ACTION SOUND', 'CUSTOM SOUND 1', 'CUSTOM SOUND 2', 'CUSTOM SOUND 3',
    'MELEE SOUND', 'RIP SOUND');
  NAME_FIELDS: array[0..8] of string = ('INHERITSFROM', 'NAME', 'DROPITEM', 'MISSILETYPE',
    'RENDERSTYLE', 'BLOOD COLOR', 'INFIGHTING GROUP', 'PROJECTILE GROUP', 'SPLASH GROUP');
  TEXT_FIELDS: array[0..2] of string = ('OBITUARY', 'HIT OBITUARY', 'TRANSLATION');
  FIXED_FIELDS: array[0..7] of string = ('PUSHFACTOR', 'SCALE', 'GRAVITY', 'FRICTION',
    'MAX STEP HEIGHT', 'MAX DROPOFF HEIGHT', 'SPRITE DX', 'SPRITE DY');
var
  LHeader, LName, LValue: string;
  LIndex: Integer;
  LEntry: TDehackedEntry;
  LFlagFields: TDictionary<string, Integer>;
  LHasMbf21: Boolean;
  LExtra: Integer;

  // a field of flags that the extra bits of BITS change too; without the field in the block the
  // value before it would be needed
  procedure EmitFlags(const AField, AName: string; const ANames: TArray<string>;
    AExtraBit, AExtraMask: Integer);
  var
    LMask: Integer;
  begin
    if (Length(ANames) > 0) and LFlagFields.TryGetValue(AField, LMask) then
    begin
      if (AExtraBit <> 0) and (LExtra and AExtraBit <> 0) then
        LMask := LMask or AExtraMask;
      SetValue(LHeader, AName, FlagsText(ANames, LMask));
    end
    else if (AExtraBit <> 0) and (LExtra and AExtraBit <> 0) then
      Soft(LHeader);
  end;

begin
  if ASection.Reference.IsNew then
  begin
    Soft('Thing');
    Exit;
  end;
  if (ASection.Reference.Number <= 0) or (ASection.Reference.Number > 137) then
    Exit;
  LHeader := 'Thing ' + IntToStr(ASection.Reference.Number);
  LHasMbf21 := False;
  for LIndex := 0 to ASection.Count - 1 do
    if ASection[LIndex].Mbf21 then
      LHasMbf21 := True;
  LFlagFields := TDictionary<string, Integer>.Create;
  try
    for LIndex := 0 to ASection.Count - 1 do
    begin
      LEntry := ASection[LIndex];
      LName := Capitalized(LEntry.FieldName);
      if LEntry.Mbf21 then
        Continue; // merged into the other flags by the engine, and not dumped
      if MatchStr(LEntry.FieldName, NAME_FIELDS) then
      begin
        Soft(LHeader); // a name that the engine resolves
        Continue;
      end;
      if LEntry.FieldName = 'GENDER' then
      begin
        if LEntry.Number = 1 then
          SetValue(LHeader, LName, 'Male')
        else
          Soft(LHeader);
        Continue;
      end;
      if MatchStr(LEntry.FieldName, TEXT_FIELDS) then
      begin
        SetValue(LHeader, LName, '"' + LEntry.Text + '"');
        Continue;
      end;
      if MatchStr(LEntry.FieldName, ['BITS', 'FLAGS_EX', 'FLAGS2_EX', 'FLAGS3_EX', 'FLAGS4_EX',
        'FLAGS5_EX', 'FLAGS6_EX']) then
      begin
        if LEntry.HasFlags then
          LFlagFields.AddOrSetValue(LEntry.FieldName, LEntry.Flags);
        Continue;
      end;
      if MatchStr(LEntry.FieldName, SOUND_FIELDS) then
      begin
        if LEntry.IsNumber then
          SetValue(LHeader, LName, IntToStr(LEntry.Number))
        else
          Soft(LHeader);
        Continue;
      end;
      case LEntry.StateRef.Kind of
        srNew: LValue := IntToStr(FBase + LEntry.StateRef.Number);
        srOriginal: LValue := IntToStr(LEntry.StateRef.Number);
      else
        LValue := IntToStr(LEntry.Number);
      end;
      if MatchStr(LEntry.FieldName, FIXED_FIELDS) then
        LValue := IntToStr(LEntry.Fixed);
      SetValue(LHeader, LName, LValue);
    end;

    LExtra := ASection.ExtraFlags;
    if LHasMbf21 then
      Soft(LHeader)
    else
    begin
      EmitFlags('BITS', 'Bits', FData.MobjFlags, 0, 0);
      EmitFlags('FLAGS_EX', 'Flags_ex', FData.MobjFlagsEx, 1, 1);               // MF_EX_TRANSPARENT
      EmitFlags('FLAGS2_EX', 'Flags2_ex', FData.MobjFlags2Ex, 2, 1 shl 27);      // MF2_EX_FRIEND
      EmitFlags('FLAGS3_EX', 'Flags3_ex', FData.MobjFlags3Ex, 4, 7);             // MF3_EX_BOUNCE
      EmitFlags('FLAGS4_EX', 'Flags4_ex', FData.MobjFlags4Ex, 0, 0);
      EmitFlags('FLAGS5_EX', 'Flags5_ex', FData.MobjFlags5Ex, 0, 0);
      EmitFlags('FLAGS6_EX', 'Flags6_ex', FData.MobjFlags6Ex, 0, 0);
    end;
  finally
    LFlagFields.Free;
  end;
end;
procedure TDumpApplier.ApplyFrame(ASection: TDehackedSection);
var
  LHeader, LName, LValue: string;
  LIndex: Integer;
  LEntry: TDehackedEntry;
  LNumber: Integer;
begin
  if ASection.Reference.Number < 0 then
    Exit; // the name of a state: the engine finds it
  if ASection.Reference.IsNew then
  begin
    LNumber := FBase + ASection.Reference.Number;
    Soft('Frame ' + IntToStr(LNumber));
    if LNumber + 1 > FTop then
      FTop := LNumber + 1;
  end
  else
    LNumber := ASection.Reference.Number;
  LHeader := 'Frame ' + IntToStr(LNumber);
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    LName := Capitalized(LEntry.FieldName);
    if LEntry.FieldName = 'CODEP FRAME' then
      Continue;
    if LEntry.FieldName = 'OWNER' then
    begin
      Soft(LHeader);
      Continue;
    end;
    if LEntry.FieldName = 'SPRITE NUMBER' then
    begin
      if LEntry.IsNumber then
        SetValue(LHeader, LName, IntToStr(LEntry.Number))
      else
      begin
        Soft(LHeader);
        Soft('[SPRITES]'); // the engine may add a sprite with that name
      end;
      Continue;
    end;
    if LEntry.FieldName = 'SPRITE SUBNUMBER' then
    begin
      if LEntry.Bright then
        SetValue(LHeader, LName, IntToStr(FF_FULLBRIGHT + LEntry.Number))
      else
        SetValue(LHeader, LName, IntToStr(LEntry.Number));
      Continue;
    end;
    if LEntry.FieldName = 'NEXT FRAME' then
    begin
      case LEntry.StateRef.Kind of
        srOriginal: LValue := IntToStr(LEntry.StateRef.Number);
        srNew: LValue := IntToStr(FBase + LEntry.StateRef.Number);
      else
        if ASection.Reference.IsNew then
          LValue := IntToStr(FBase + LEntry.Number)
        else
          LValue := IntToStr(LEntry.Number);
      end;
      SetValue(LHeader, LName, LValue);
      Continue;
    end;
    if LEntry.FieldName = 'FLAGS_EX' then
    begin
      if LEntry.HasFlags then
        SetValue(LHeader, LName, FlagsText(FData.StateFlagsEx, LEntry.Flags));
      Continue;
    end;
    if LEntry.FieldName = 'MBF21 BITS' then
    begin
      if LEntry.HasFlags then
        SetValue(LHeader, LName, FlagsText(FData.StateFlagsMbf21, LEntry.Flags));
      Continue;
    end;
    if (Copy(LEntry.FieldName, 1, 4) = 'ARGS') then
      Continue; // the arguments are not in the dump
    SetValue(LHeader, LName, IntToStr(LEntry.Number));
  end;
end;

procedure TDumpApplier.ApplyWeapon(ASection: TDehackedSection);
var
  LHeader, LName, LValue: string;
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  if ASection.Reference.Number < 0 then
    Exit;
  LHeader := 'Weapon ' + WEAPON_NAMES[ASection.Reference.Number];
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    LName := Capitalized(LEntry.FieldName);
    if LEntry.FieldName = 'AMMO TYPE' then
    begin
      if LEntry.Number >= 0 then
      begin
        if LEntry.Number <= High(AMMO_NAMES) then
          SetValue(LHeader, LName, AMMO_NAMES[LEntry.Number])
        else
          Soft(LHeader);
      end
      else
        Soft(LHeader);
      Continue;
    end;
    if LEntry.FieldName = 'MBF21 BITS' then
    begin
      if LEntry.HasFlags then
        SetValue(LHeader, LName, FlagsText(FData.WeaponFlagsMbf21, LEntry.Flags));
      Continue;
    end;
    case LEntry.StateRef.Kind of
      srNew: LValue := IntToStr(FBase + LEntry.StateRef.Number);
      srOriginal: LValue := IntToStr(LEntry.StateRef.Number);
    else
      LValue := IntToStr(LEntry.Number);
    end;
    SetValue(LHeader, LName, LValue);
  end;
end;

procedure TDumpApplier.ApplyAmmo(ASection: TDehackedSection);
var
  LHeader: string;
  LIndex: Integer;
begin
  LHeader := 'Ammo ' + IntToStr(ASection.Reference.Number);
  for LIndex := 0 to ASection.Count - 1 do
    SetValue(LHeader, Capitalized(ASection[LIndex].FieldName), IntToStr(ASection[LIndex].Number));
end;

procedure TDumpApplier.ApplyMisc(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
  LDidMaxSoulsphere: Boolean;
begin
  LDidMaxSoulsphere := False;
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    SetValue('Misc', Capitalized(LEntry.FieldName), IntToStr(LEntry.Number));
    // only Doom has the second maximum
    if (LEntry.FieldName = 'MAX HEALTH') and (IndexStr('MAX SOULSPHERE', FData.MiscFields) >= 0) then
    begin
      if not LDidMaxSoulsphere then
        SetValue('Misc', 'Max Soulsphere', IntToStr(LEntry.Number));
    end
    else if LEntry.FieldName = 'MAX SOULSPHERE' then
      LDidMaxSoulsphere := True;
  end;
end;

procedure TDumpApplier.ApplyPars(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    if Length(LEntry.Numbers) = 3 then
      SetValue('[PARS]', Format('PAR %d %d', [LEntry.Numbers[0], LEntry.Numbers[1]]),
        IntToStr(LEntry.Numbers[2]))
    else
      SetValue('[PARS]', Format('PAR %d', [LEntry.Numbers[0]]), IntToStr(LEntry.Numbers[1]));
  end;
end;

procedure TDumpApplier.ApplyStrings(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  Soft('[Strings]'); // the names of the strings are the engine's
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    SetValue('[Strings]', LEntry.Key,
      TDehackedText.StringToCString(TDehackedText.CStringToString(LEntry.Text)));
  end;
end;

procedure TDumpApplier.ApplyText(ASection: TDehackedSection);
var
  LPair: TPair<string, string>;
  LName: string;
begin
  Soft('[Strings]');
  for LPair in FOldStrings do
  begin
    if TDehackedText.StringValue(Copy(LPair.Value, 1, MaxInt)) =
      TDehackedText.StringValue(ASection.OldText) then
    begin
      LName := LPair.Key;
      SetValue('[Strings]', LName,
        TDehackedText.StringToCString(TDehackedText.CStringToString(ASection.NewText)));
      Break;
    end;
  end;
  // a text of 4 and 4 characters can also be a sprite: the engine's
  if (ASection.OldLength = 4) and (ASection.NewLength = 4) then
    Soft('[SPRITES]');
end;

procedure TDumpApplier.ApplyMusic(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  Soft('[MUSIC]');
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    if (LEntry.Number >= 1) and (LEntry.Number < NUM_MUSIC) then
      SetValue('[MUSIC]', IntToStr(LEntry.Number), LEntry.Text);
  end;
end;

procedure TDumpApplier.ApplySounds(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  Soft('[SOUND]');
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    if (LEntry.Number >= 1) and (LEntry.Number < NUM_SFX) then
      SetValue('[SOUND]', IntToStr(LEntry.Number), LEntry.Text);
  end;
end;

procedure TDumpApplier.ApplySprites(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  Soft('[SPRITES]');
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    if (LEntry.Number >= 0) and (LEntry.Number < 138) then
      SetValue('[SPRITES]', IntToStr(LEntry.Number + 1), LEntry.Text);
  end;
end;

procedure TDumpApplier.ApplySound(ASection: TDehackedSection);
var
  LIndex: Integer;
  LEntry: TDehackedEntry;
begin
  if (ASection.Reference.Number < 1) or (ASection.Reference.Number >= NUM_SFX) then
    Exit;
  for LIndex := 0 to ASection.Count - 1 do
  begin
    LEntry := ASection[LIndex];
    if LEntry.FieldName = 'NAME' then
    begin
      Soft('[SOUND]');
      SetValue('[SOUND]', IntToStr(ASection.Reference.Number), LEntry.Text);
    end;
  end;
end;

end.
