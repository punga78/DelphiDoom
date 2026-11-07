{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the TableExport library - the fake catalog             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.TableExport.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.TableExport.Types, DelphiDoom.TableExport.Intf;

type
  TFakeThings = class(TInterfacedObject, IExportThingSource)
  public
    Items: TList<TExportThing>;
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    function Get(AIndex: Integer): TExportThing;
    /// <summary>A thing with the defaults of the game: the engine values of a thing that did not change</summary>
    class function Blank(const AName: string): TExportThing; static;
  end;

  TFakeStates = class(TInterfacedObject, IExportStateSource)
  public
    Items: TList<TExportState>;
    Names: TList<string>;
    OwnerMap: TDictionary<Integer, TArray<Integer>>;
    Sprites: TList<string>;
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    function Get(AIndex: Integer): TExportState;
    function NameCount: Integer;
    function StateName(AIndex: Integer): string;
    function Owners(AIndex: Integer): TArray<Integer>;
    function SpriteCount: Integer;
    function SpriteName(AIndex: Integer): string;
    /// <summary>Adds a state with a sprite and a next state</summary>
    procedure AddState(const ASprite: string; AFrame, ATics, ANext: Integer; const AAction: string = '');
  end;

  TFakeWeapons = class(TInterfacedObject, IExportWeaponSource)
  public
    Items: TList<TExportWeapon>;
    constructor Create;
    destructor Destroy; override;
    function Count: Integer;
    function Get(AIndex: Integer): TExportWeapon;
  end;

  TFakeSettings = class(TInterfacedObject, IExportSettingsSource)
  public
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

  /// <summary>The names of a small game: three states, two sounds, two weapons...</summary>
  TFakeNames = class(TInterfacedObject, IExportFlagNames, IExportEnumNames, IExportLookups)
  public
    function Names(ASet: TExportFlagSet): TArray<string>;
    function Count(AKind: TExportEnum): Integer;
    function Name(AKind: TExportEnum; AOrdinal: Integer): string;
    function ThingName(AIndex: Integer): string;
    function SoundName(ASound: Integer): string;
    function BloodName(AColor: Integer): string;
    function GroupName(AGroup: TExportGroup; AValue: Integer): string;
    function RenderStyleToken(AValue: Integer): string;
    function GenderToken(AValue: Integer): string;
    function AmmoToken(AIndex: Integer): string;
    function WeaponToken(AIndex: Integer): string;
    function PlayerClassToken(AIndex: Integer): string;
  end;

implementation

{ TFakeThings }

constructor TFakeThings.Create;
begin
  inherited Create;
  Items := TList<TExportThing>.Create;
end;

destructor TFakeThings.Destroy;
begin
  Items.Free;
  inherited Destroy;
end;

function TFakeThings.Count: Integer;
begin
  Result := Items.Count;
end;

function TFakeThings.Get(AIndex: Integer): TExportThing;
begin
  Result := Items[AIndex];
end;

class function TFakeThings.Blank(const AName: string): TExportThing;
begin
  Result := Default(TExportThing);
  Result.Texts[ttName] := AName;
  Result.Numbers[tfInheritsFrom] := -1;
  Result.Numbers[tfPushFactor] := EXPORT_DEFAULT_PUSHFACTOR;
  Result.Numbers[tfFriction] := EXPORT_ORIGINAL_FRICTION;
  Result.Numbers[tfScale] := EXPORT_FRACUNIT;
  Result.Numbers[tfGravity] := EXPORT_FRACUNIT;
end;

{ TFakeStates }

constructor TFakeStates.Create;
begin
  inherited Create;
  Items := TList<TExportState>.Create;
  Names := TList<string>.Create;
  OwnerMap := TDictionary<Integer, TArray<Integer>>.Create;
  Sprites := TList<string>.Create;
end;

destructor TFakeStates.Destroy;
begin
  Sprites.Free;
  OwnerMap.Free;
  Names.Free;
  Items.Free;
  inherited Destroy;
end;

function TFakeStates.Count: Integer;
begin
  Result := Items.Count;
end;

function TFakeStates.Get(AIndex: Integer): TExportState;
begin
  Result := Items[AIndex];
end;

function TFakeStates.NameCount: Integer;
begin
  Result := Names.Count;
end;

function TFakeStates.StateName(AIndex: Integer): string;
begin
  Result := Names[AIndex];
end;

function TFakeStates.Owners(AIndex: Integer): TArray<Integer>;
begin
  if not OwnerMap.TryGetValue(AIndex, Result) then
    Result := nil;
end;

function TFakeStates.SpriteCount: Integer;
begin
  Result := Sprites.Count;
end;

function TFakeStates.SpriteName(AIndex: Integer): string;
begin
  Result := Sprites[AIndex];
end;

procedure TFakeStates.AddState(const ASprite: string; AFrame, ATics, ANext: Integer; const AAction: string);
var
  LState: TExportState;
begin
  LState := Default(TExportState);
  LState.SpriteName := ASprite;
  LState.Numbers[sfFrame] := AFrame;
  LState.Numbers[sfTics] := ATics;
  LState.Numbers[sfTics2] := ATics;
  LState.Numbers[sfNextState] := ANext;
  if AAction <> '' then
  begin
    LState.HasAction := True;
    LState.ActionName := AAction;
  end;
  Items.Add(LState);
end;

{ TFakeWeapons }

constructor TFakeWeapons.Create;
begin
  inherited Create;
  Items := TList<TExportWeapon>.Create;
end;

destructor TFakeWeapons.Destroy;
begin
  Items.Free;
  inherited Destroy;
end;

function TFakeWeapons.Count: Integer;
begin
  Result := Items.Count;
end;

function TFakeWeapons.Get(AIndex: Integer): TExportWeapon;
begin
  Result := Items[AIndex];
end;

{ TFakeSettings }

function TFakeSettings.CreatedWith: string;
begin
  Result := 'Fake 1.0, built today';
end;

function TFakeSettings.CommandLine: string;
begin
  Result := 'fake.exe -iwad x.wad';
end;

function TFakeSettings.AmmoCount: Integer;
begin
  Result := 2;
end;

function TFakeSettings.Ammo(AIndex, AValue: Integer): Integer;
begin
  Result := (AIndex + 1) * 100 + AValue;
end;

function TFakeSettings.Misc(AIndex: Integer): Integer;
begin
  Result := 10 + AIndex;
end;

function TFakeSettings.Par(AEpisode, AMap: Integer): Integer;
begin
  Result := AEpisode * 100 + AMap;
end;

function TFakeSettings.CommercialPar(AMap: Integer): Integer;
begin
  Result := 1000 + AMap;
end;

function TFakeSettings.StringCount: Integer;
begin
  Result := 2;
end;

function TFakeSettings.StringName(AIndex: Integer): string;
begin
  Result := 'STR' + IntToStr(AIndex);
end;

function TFakeSettings.StringValue(AIndex: Integer): string;
begin
  if AIndex = 0 then
    Result := 'one'#13#10'two'
  else
    Result := 'plain';
end;

function TFakeSettings.MusicCount: Integer;
begin
  Result := 3;
end;

function TFakeSettings.MusicName(AIndex: Integer): string;
begin
  Result := 'mus' + IntToStr(AIndex);
end;

function TFakeSettings.MusicMapName(AIndex: Integer): string;
begin
  if AIndex = 2 then
    Result := 'MAP02'
  else
    Result := '';
end;

function TFakeSettings.SoundCount: Integer;
begin
  Result := 3;
end;

function TFakeSettings.SoundName(AIndex: Integer): string;
begin
  Result := 'snd' + IntToStr(AIndex);
end;

{ TFakeNames }

function TFakeNames.Names(ASet: TExportFlagSet): TArray<string>;
begin
  case ASet of
    fsMobjFlags: Result := ['MF_SPECIAL', 'MF_SOLID', 'MF_SHOOTABLE'];
    fsMobjFlagsEx: Result := ['MF_EX_TRANSPARENT', 'MF_EX_WHITELIGHT'];
    fsStateFlagsEx: Result := ['MF_EX_STATE_BRIGHT'];
    fsWeaponFlagsMbf21: Result := ['WPF_NOTHRUST', 'WPF_SILENT'];
  else
    Result := nil;
  end;
end;

function TFakeNames.Count(AKind: TExportEnum): Integer;
begin
  case AKind of
    eeState: Result := 3;
    eeSprite: Result := 2;
    eeSound: Result := 3;
    eeMobj: Result := 2;
    eeGender: Result := 6;
    eeRenderStyle: Result := 4;
    eeWeapon: Result := 2;
    eePlayerClass: Result := 2;
    eeAmmo: Result := 3;
  else
    Result := 0;
  end;
end;

function TFakeNames.Name(AKind: TExportEnum; AOrdinal: Integer): string;
const
  STATES: array[0..2] of string = ('s_null', 's_first', 's_second');
  SPRITES: array[0..1] of string = ('SPR_NULL', 'SPR_TROO');
  SOUNDS: array[0..2] of string = ('sfx_None', 'sfx_pistol', 'sfx_shotgn');
  MOBJS: array[0..1] of string = ('mt_player', 'mt_possessed');
  GENDERS: array[0..5] of string = ('gender_Default', 'gender_Male', 'gender_Female', 'gender_Plural',
    'gender_Team', 'gender_Neutral');
  STYLES: array[0..3] of string = ('mrs_normal', 'mrs_translucent', 'mrs_add', 'mrs_subtract');
  WEAPONS: array[0..1] of string = ('wp_fist', 'wp_pistol');
  CLASSES: array[0..1] of string = ('PCLASS_FIGHTER', 'PCLASS_CLERIC');
  AMMOS: array[0..2] of string = ('am_clip', 'am_shell', 'am_noammo');
begin
  case AKind of
    eeState: Result := STATES[AOrdinal];
    eeSprite: Result := SPRITES[AOrdinal];
    eeSound: Result := SOUNDS[AOrdinal];
    eeMobj: Result := MOBJS[AOrdinal];
    eeGender: Result := GENDERS[AOrdinal];
    eeRenderStyle: Result := STYLES[AOrdinal];
    eeWeapon: Result := WEAPONS[AOrdinal];
    eePlayerClass: Result := CLASSES[AOrdinal];
    eeAmmo: Result := AMMOS[AOrdinal];
  else
    Result := '';
  end;
end;

function TFakeNames.ThingName(AIndex: Integer): string;
begin
  Result := 'Thing' + IntToStr(AIndex);
end;

function TFakeNames.SoundName(ASound: Integer): string;
begin
  Result := 'DS' + IntToStr(ASound);
end;

function TFakeNames.BloodName(AColor: Integer): string;
begin
  if AColor = 1 then
    Result := 'Red'
  else
    Result := '';
end;

function TFakeNames.GroupName(AGroup: TExportGroup; AValue: Integer): string;
begin
  Result := 'G' + IntToStr(Ord(AGroup)) + '_' + IntToStr(AValue);
end;

function TFakeNames.RenderStyleToken(AValue: Integer): string;
begin
  Result := Name(eeRenderStyle, AValue);
end;

function TFakeNames.GenderToken(AValue: Integer): string;
begin
  Result := Copy(Name(eeGender, AValue), 8, MaxInt);
end;

function TFakeNames.AmmoToken(AIndex: Integer): string;
begin
  Result := UpperCase(Name(eeAmmo, AIndex));
end;

function TFakeNames.WeaponToken(AIndex: Integer): string;
begin
  Result := UpperCase(Name(eeWeapon, AIndex));
end;

function TFakeNames.PlayerClassToken(AIndex: Integer): string;
begin
  Result := Name(eePlayerClass, AIndex);
end;

end.
