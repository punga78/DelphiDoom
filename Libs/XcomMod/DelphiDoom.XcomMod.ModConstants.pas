{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom ruleset library - the constants of the ruleset (the         }
{  "constants" node: Mod::loadConstants and the statics of Mod)                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomMod.ModConstants;

interface

uses
  System.SysUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomMod.NodeReader, DelphiDoom.XcomMod.ModOffsets;

type
  /// <summary>
  ///   The sounds, sprites and numbers that the ruleset sets for the whole game: doors, explosions, items, UFO
  ///   and interceptor sounds, cursors, damage ranges and debriefing music. The C++ keeps them in statics that
  ///   Mod::resetGlobalStatics sets; here the values are in a record that the ruleset owns
  /// </summary>
  TXcomModConstants = class
  strict private
    FDoorOpen: Integer;
    FSlidingDoorOpen: Integer;
    FSlidingDoorClose: Integer;
    FSmallExplosion: Integer;
    FLargeExplosion: Integer;
    FExplosionOffset: Integer;
    FSmokeOffset: Integer;
    FUnderwaterSmokeOffset: Integer;
    FItemDrop: Integer;
    FItemThrow: Integer;
    FItemReload: Integer;
    FWalkOffset: Integer;
    FFlyingSound: Integer;
    FButtonPress: Integer;
    FWindowPopup: array[0..2] of Integer;
    FUfoFire: Integer;
    FUfoHit: Integer;
    FUfoCrash: Integer;
    FUfoExplode: Integer;
    FInterceptorHit: Integer;
    FInterceptorExplode: Integer;
    FGeoscapeCursor: Integer;
    FBasescapeCursor: Integer;
    FBattlescapeCursor: Integer;
    FUfopaediaCursor: Integer;
    FGraphsCursor: Integer;
    FDamageRange: Integer;
    FExplosiveDamageRange: Integer;
    FFireDamageRange: array[0..1] of Integer;
    FDebriefMusicGood: string;
    FDebriefMusicBad: string;
    function GetWindowPopup(AIndex: Integer): Integer;
    function GetFireDamageRange(AIndex: Integer): Integer;
  public
    /// <summary>The defaults of Mod::resetGlobalStatics</summary>
    constructor Create;
    /// <summary>Mod::loadConstants: the values that the node has replace the ones there are</summary>
    procedure Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
    property DoorOpen: Integer read FDoorOpen;
    property SlidingDoorOpen: Integer read FSlidingDoorOpen;
    property SlidingDoorClose: Integer read FSlidingDoorClose;
    property SmallExplosion: Integer read FSmallExplosion;
    property LargeExplosion: Integer read FLargeExplosion;
    property ExplosionOffset: Integer read FExplosionOffset;
    property SmokeOffset: Integer read FSmokeOffset;
    property UnderwaterSmokeOffset: Integer read FUnderwaterSmokeOffset;
    property ItemDrop: Integer read FItemDrop;
    property ItemThrow: Integer read FItemThrow;
    property ItemReload: Integer read FItemReload;
    property WalkOffset: Integer read FWalkOffset;
    property FlyingSound: Integer read FFlyingSound;
    property ButtonPress: Integer read FButtonPress;
    /// <summary>WINDOW_POPUP: AIndex is 0 to 2</summary>
    property WindowPopup[AIndex: Integer]: Integer read GetWindowPopup;
    property UfoFire: Integer read FUfoFire;
    property UfoHit: Integer read FUfoHit;
    property UfoCrash: Integer read FUfoCrash;
    property UfoExplode: Integer read FUfoExplode;
    property InterceptorHit: Integer read FInterceptorHit;
    property InterceptorExplode: Integer read FInterceptorExplode;
    property GeoscapeCursor: Integer read FGeoscapeCursor;
    property BasescapeCursor: Integer read FBasescapeCursor;
    property BattlescapeCursor: Integer read FBattlescapeCursor;
    property UfopaediaCursor: Integer read FUfopaediaCursor;
    property GraphsCursor: Integer read FGraphsCursor;
    property DamageRange: Integer read FDamageRange;
    property ExplosiveDamageRange: Integer read FExplosiveDamageRange;
    /// <summary>FIRE_DAMAGE_RANGE: AIndex is 0 or 1</summary>
    property FireDamageRange[AIndex: Integer]: Integer read GetFireDamageRange;
    property DebriefMusicGood: string read FDebriefMusicGood;
    property DebriefMusicBad: string read FDebriefMusicBad;
  end;

implementation

{ TXcomModConstants }

constructor TXcomModConstants.Create;
begin
  inherited Create;
  FDoorOpen := 3;
  FSlidingDoorOpen := 20;
  FSlidingDoorClose := 21;
  FSmallExplosion := 2;
  FLargeExplosion := 5;
  FExplosionOffset := 0;
  FSmokeOffset := 8;
  FUnderwaterSmokeOffset := 0;
  FItemDrop := 38;
  FItemThrow := 39;
  FItemReload := 17;
  FWalkOffset := 22;
  FFlyingSound := 15;
  FButtonPress := 0;
  FWindowPopup[0] := 1;
  FWindowPopup[1] := 2;
  FWindowPopup[2] := 3;
  FUfoFire := 8;
  FUfoHit := 12;
  FUfoCrash := 10;
  FUfoExplode := 11;
  FInterceptorHit := 10;
  FInterceptorExplode := 13;
  FGeoscapeCursor := 252;
  FBasescapeCursor := 252;
  FBattlescapeCursor := 144;
  FUfopaediaCursor := 252;
  FGraphsCursor := 252;
  FDamageRange := 100;
  FExplosiveDamageRange := 50;
  FFireDamageRange[0] := 5;
  FFireDamageRange[1] := 10;
  FDebriefMusicGood := 'GMMARS';
  FDebriefMusicBad := 'GMMARS';
end;

function TXcomModConstants.GetWindowPopup(AIndex: Integer): Integer;
begin
  Result := FWindowPopup[AIndex];
end;

function TXcomModConstants.GetFireDamageRange(AIndex: Integer): Integer;
begin
  Result := FFireDamageRange[AIndex];
end;

procedure TXcomModConstants.Load(const ANode: IYamlNode; const AOffsets: TXcomModOffsets);
var
  LItem, LField: IYamlNode;
  LIndex: Integer;
begin
  AOffsets.LoadSoundOffset('constants', FDoorOpen, TXcomNodeReader.Field(ANode, 'doorSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FSlidingDoorOpen, TXcomNodeReader.Field(ANode, 'slidingDoorSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FSlidingDoorClose, TXcomNodeReader.Field(ANode, 'slidingDoorClose'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FSmallExplosion, TXcomNodeReader.Field(ANode, 'smallExplosion'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FLargeExplosion, TXcomNodeReader.Field(ANode, 'largeExplosion'), 'BATTLE.CAT');
  AOffsets.LoadSpriteOffset('constants', FExplosionOffset, TXcomNodeReader.Field(ANode, 'explosionOffset'), 'X1.PCK');
  AOffsets.LoadSpriteOffset('constants', FSmokeOffset, TXcomNodeReader.Field(ANode, 'smokeOffset'), 'SMOKE.PCK');
  AOffsets.LoadSpriteOffset('constants', FUnderwaterSmokeOffset, TXcomNodeReader.Field(ANode, 'underwaterSmokeOffset'),
    'SMOKE.PCK');
  AOffsets.LoadSoundOffset('constants', FItemDrop, TXcomNodeReader.Field(ANode, 'itemDrop'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FItemThrow, TXcomNodeReader.Field(ANode, 'itemThrow'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FItemReload, TXcomNodeReader.Field(ANode, 'itemReload'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FWalkOffset, TXcomNodeReader.Field(ANode, 'walkOffset'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FFlyingSound, TXcomNodeReader.Field(ANode, 'flyingSound'), 'BATTLE.CAT');
  AOffsets.LoadSoundOffset('constants', FButtonPress, TXcomNodeReader.Field(ANode, 'buttonPress'), 'GEO.CAT');
  LField := TXcomNodeReader.Field(ANode, 'windowPopup');
  if LField.IsDefined then
  begin
    LIndex := 0;
    for LItem in LField.Items do
    begin
      if LIndex >= 3 then
        Break;
      AOffsets.LoadSoundOffset('constants', FWindowPopup[LIndex], LItem, 'GEO.CAT');
      Inc(LIndex);
    end;
  end;
  AOffsets.LoadSoundOffset('constants', FUfoFire, TXcomNodeReader.Field(ANode, 'ufoFire'), 'GEO.CAT');
  AOffsets.LoadSoundOffset('constants', FUfoHit, TXcomNodeReader.Field(ANode, 'ufoHit'), 'GEO.CAT');
  AOffsets.LoadSoundOffset('constants', FUfoCrash, TXcomNodeReader.Field(ANode, 'ufoCrash'), 'GEO.CAT');
  AOffsets.LoadSoundOffset('constants', FUfoExplode, TXcomNodeReader.Field(ANode, 'ufoExplode'), 'GEO.CAT');
  AOffsets.LoadSoundOffset('constants', FInterceptorHit, TXcomNodeReader.Field(ANode, 'interceptorHit'), 'GEO.CAT');
  AOffsets.LoadSoundOffset('constants', FInterceptorExplode, TXcomNodeReader.Field(ANode, 'interceptorExplode'),
    'GEO.CAT');
  FGeoscapeCursor := TXcomNodeReader.ReadInteger(ANode, 'geoscapeCursor', FGeoscapeCursor);
  FBasescapeCursor := TXcomNodeReader.ReadInteger(ANode, 'basescapeCursor', FBasescapeCursor);
  FBattlescapeCursor := TXcomNodeReader.ReadInteger(ANode, 'battlescapeCursor', FBattlescapeCursor);
  FUfopaediaCursor := TXcomNodeReader.ReadInteger(ANode, 'ufopaediaCursor', FUfopaediaCursor);
  FGraphsCursor := TXcomNodeReader.ReadInteger(ANode, 'graphsCursor', FGraphsCursor);
  FDamageRange := TXcomNodeReader.ReadInteger(ANode, 'damageRange', FDamageRange);
  FExplosiveDamageRange := TXcomNodeReader.ReadInteger(ANode, 'explosiveDamageRange', FExplosiveDamageRange);
  LIndex := 0;
  for LItem in TXcomNodeReader.Field(ANode, 'fireDamageRange').Items do
  begin
    if LIndex >= 2 then
      Break;
    FFireDamageRange[LIndex] := LItem.AsInteger(FFireDamageRange[LIndex]);
    Inc(LIndex);
  end;
  FDebriefMusicGood := TXcomNodeReader.ReadString(ANode, 'goodDebriefingMusic', FDebriefMusicGood);
  FDebriefMusicBad := TXcomNodeReader.ReadString(ANode, 'badDebriefingMusic', FDebriefMusicBad);
end;

end.
