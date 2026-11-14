{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the animations of the effects and the buildings   }
{                                                                              }
{  Port of war1 (acoto87/war1), war_animations.c, (c) 2019 Alejandro Coto      }
{  Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt). This is an         }
{  altered version, not the original.                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Model.Animations;

interface

uses
  DelphiDoom.War.Model.Types, DelphiDoom.War.Model.Context;

type
  /// <summary>
  ///   war_animations.c as far as it is state of the game: which animations an entity plays (the damage of a building,
  ///   its collapse, an explosion, the flash of a spell, a poison cloud), how far each one has gone and when it ends.
  ///   The image, its offset and its scale are the business of whoever draws (the kind and the position say which and
  ///   where). The animations live in the slot of the entity, in a list. Defects of the original kept: an animation that
  ///   ends is removed at the tic after, and the animation that follows it in the list of the same entity skips that
  ///   tic; the entity of an explosion or of a spell is never removed; a building that is told to collapse again while
  ///   it collapses gets one more collapse animation each time
  /// </summary>
  TWarAnimations = class
  public
    /// <summary>wanim_createAnimation + wanim_addAnimationFrames + wanim_addAnimation</summary>
    class function Add(AEntity: PWarEntity; AKind: Integer; AFrameDelay: Single; ALoop: Boolean; AFrames: Integer;
      const APosition: TWarVec2): PWarAnimation; static;
    /// <summary>wanim_findAnimationIndex: the first animation with that name, -1 if none</summary>
    class function IndexOf(AEntity: PWarEntity; AKind: Integer): Integer; static;
    /// <summary>wanim_containsAnimation</summary>
    class function Contains(AEntity: PWarEntity; AKind: Integer): Boolean; static;
    /// <summary>wanim_removeAnimation: nothing if the entity has none with that name</summary>
    class procedure Remove(AEntity: PWarEntity; AKind: Integer); static;
    /// <summary>wanim_getAnimationDuration: the delay of a frame by the frames (seconds)</summary>
    class function Duration(const AAnimation: TWarAnimation): Single; static;
    /// <summary>wanim_createDamageAnimation: level 1 is littleDamage, any other is hugeDamage (4 frames of 0.2 s, in a loop)</summary>
    class procedure CreateDamage(AEntity: PWarEntity; ALevel: Integer); static;
    /// <summary>wanim_createCollapseAnimation (17 frames of 0.1 s): the animation that was added</summary>
    class function CreateCollapse(AEntity: PWarEntity): PWarAnimation; static;
    /// <summary>wanim_createExplosionAnimation (6 frames of 0.1 s)</summary>
    class procedure CreateExplosion(AEntity: PWarEntity; const APosition: TWarVec2); static;
    /// <summary>wanim_createRainOfFireExplosionAnimation (the frames 3..5 of the explosion)</summary>
    class procedure CreateRainOfFireExplosion(AEntity: PWarEntity; const APosition: TWarVec2); static;
    /// <summary>wanim_createSpellAnimation (6 frames of 0.4 s)</summary>
    class procedure CreateSpell(AEntity: PWarEntity; const APosition: TWarVec2); static;
    /// <summary>wanim_createPoisonCloudAnimation (4 frames of 0.5 s, in a loop)</summary>
    class procedure CreatePoisonCloud(AEntity: PWarEntity; const APosition: TWarVec2); static;
    /// <summary>
    ///   A new entity of type animation with the flash of a spell at the position (what the original does after a
    ///   spell: we_createEntity, we_addAnimationsComponent, wanim_createSpellAnimation); 0 if the pool is full
    /// </summary>
    class function SpawnSpellEffect(AContext: TWarModelContext; const APosition: TWarVec2): Integer; static;
    /// <summary>wanim_updateAnimation for one animation of an entity (AIndex in its list)</summary>
    class procedure UpdateOne(AEntity: PWarEntity; AIndex: Integer; ADeltaTime: Single); static;
    /// <summary>wanim_updateAnimations: every animation of every entity, in the order of the slots</summary>
    class procedure UpdateAll(AContext: TWarModelContext); static;
  end;

implementation

const
  // the float constants of the original (0.2f, 0.1f, 0.4f, 0.5f), not the doubles
  DAMAGE_FRAME_DELAY: Single = 0.2;
  SHORT_FRAME_DELAY: Single = 0.1;
  SPELL_FRAME_DELAY: Single = 0.4;
  CLOUD_FRAME_DELAY: Single = 0.5;

// the name of the original is made of the kind and, for the effects, of the position (explosion_x_y for both explosions)
function SameName(const A, B: TWarAnimation): Boolean;
var
  LKindA: Integer;
  LKindB: Integer;
begin
  LKindA := A.Kind;
  LKindB := B.Kind;
  if LKindA = WAR_ANIMATION_RAIN_OF_FIRE_EXPLOSION then
    LKindA := WAR_ANIMATION_EXPLOSION;
  if LKindB = WAR_ANIMATION_RAIN_OF_FIRE_EXPLOSION then
    LKindB := WAR_ANIMATION_EXPLOSION;
  Result := (LKindA = LKindB) and (A.Position.X = B.Position.X) and (A.Position.Y = B.Position.Y);
end;

procedure RemoveAt(AEntity: PWarEntity; AIndex: Integer);
var
  LIndex: Integer;
begin
  for LIndex := AIndex to AEntity^.AnimationCount - 2 do
    AEntity^.Animations[LIndex] := AEntity^.Animations[LIndex + 1];
  Dec(AEntity^.AnimationCount);
end;

{ TWarAnimations }

class function TWarAnimations.Add(AEntity: PWarEntity; AKind: Integer; AFrameDelay: Single; ALoop: Boolean;
  AFrames: Integer; const APosition: TWarVec2): PWarAnimation;
begin
  if AEntity^.AnimationCount >= Length(AEntity^.Animations) then
    SetLength(AEntity^.Animations, AEntity^.AnimationCount * 2 + 2);
  AEntity^.HasAnimations := True;
  Result := @AEntity^.Animations[AEntity^.AnimationCount];
  Inc(AEntity^.AnimationCount);
  Result^ := Default(TWarAnimation);
  Result^.Kind := Byte(AKind);
  Result^.Loop := ALoop;
  Result^.FrameDelay := AFrameDelay;
  Result^.FramesCount := AFrames;
  Result^.Status := WAR_ANIM_NOT_STARTED;
  Result^.Position := APosition;
end;

class function TWarAnimations.IndexOf(AEntity: PWarEntity; AKind: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to AEntity^.AnimationCount - 1 do
    if AEntity^.Animations[LIndex].Kind = AKind then
      Exit(LIndex);
  Result := -1;
end;

class function TWarAnimations.Contains(AEntity: PWarEntity; AKind: Integer): Boolean;
begin
  Result := IndexOf(AEntity, AKind) >= 0;
end;

class procedure TWarAnimations.Remove(AEntity: PWarEntity; AKind: Integer);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AEntity, AKind);
  if LIndex >= 0 then
    RemoveAt(AEntity, LIndex);
end;

class function TWarAnimations.Duration(const AAnimation: TWarAnimation): Single;
begin
  Result := AAnimation.FrameDelay * AAnimation.FramesCount;
end;

class procedure TWarAnimations.CreateDamage(AEntity: PWarEntity; ALevel: Integer);
var
  LZero: TWarVec2;
begin
  LZero := Default(TWarVec2);
  if ALevel = 1 then
    Add(AEntity, WAR_ANIMATION_LITTLE_DAMAGE, DAMAGE_FRAME_DELAY, True, 4, LZero)
  else
    Add(AEntity, WAR_ANIMATION_HUGE_DAMAGE, DAMAGE_FRAME_DELAY, True, 4, LZero);
end;

class function TWarAnimations.CreateCollapse(AEntity: PWarEntity): PWarAnimation;
begin
  Result := Add(AEntity, WAR_ANIMATION_COLLAPSE, SHORT_FRAME_DELAY, False, 17, Default(TWarVec2));
end;

class procedure TWarAnimations.CreateExplosion(AEntity: PWarEntity; const APosition: TWarVec2);
begin
  Add(AEntity, WAR_ANIMATION_EXPLOSION, SHORT_FRAME_DELAY, False, 6, APosition);
end;

class procedure TWarAnimations.CreateRainOfFireExplosion(AEntity: PWarEntity; const APosition: TWarVec2);
begin
  Add(AEntity, WAR_ANIMATION_RAIN_OF_FIRE_EXPLOSION, SHORT_FRAME_DELAY, False, 3, APosition);
end;

class procedure TWarAnimations.CreateSpell(AEntity: PWarEntity; const APosition: TWarVec2);
begin
  Add(AEntity, WAR_ANIMATION_SPELL, SPELL_FRAME_DELAY, False, 6, APosition);
end;

class procedure TWarAnimations.CreatePoisonCloud(AEntity: PWarEntity; const APosition: TWarVec2);
begin
  Add(AEntity, WAR_ANIMATION_POISON_CLOUD, CLOUD_FRAME_DELAY, True, 4, APosition);
end;

class function TWarAnimations.SpawnSpellEffect(AContext: TWarModelContext; const APosition: TWarVec2): Integer;
begin
  Result := AContext.Pool.CreateEntity(WAR_ENTITY_ANIMATION, True);
  if Result <> 0 then
    CreateSpell(AContext.Pool.Slots[Result], APosition);
end;

class procedure TWarAnimations.UpdateOne(AEntity: PWarEntity; AIndex: Integer; ADeltaTime: Single);
var
  LAnimation: PWarAnimation;
  LIndex: Integer;
  LStep: Single;
begin
  LAnimation := @AEntity^.Animations[AIndex];
  if LAnimation^.Status = WAR_ANIM_FINISHED then
  begin
    // wanim_removeAnimation by name: the first of the entity with the same name
    for LIndex := 0 to AEntity^.AnimationCount - 1 do
      if SameName(AEntity^.Animations[LIndex], LAnimation^) then
      begin
        RemoveAt(AEntity, LIndex);
        Break;
      end;
    Exit;
  end;
  LAnimation^.Status := WAR_ANIM_RUNNING;
  if LAnimation^.LoopTime > 0 then
  begin
    LAnimation^.LoopTime := LAnimation^.LoopTime - ADeltaTime;
    Exit;
  end;
  LStep := ADeltaTime / Duration(LAnimation^);
  LAnimation^.AnimTime := LAnimation^.AnimTime + LStep;
  if LAnimation^.AnimTime >= 1 then
  begin
    LAnimation^.AnimTime := 1;
    LAnimation^.Status := WAR_ANIM_FINISHED;
    if LAnimation^.Loop then
    begin
      // wanim_resetAnimation
      LAnimation^.AnimTime := 0;
      LAnimation^.LoopTime := LAnimation^.LoopDelay;
      LAnimation^.Status := WAR_ANIM_RUNNING;
    end;
  end;
end;

class procedure TWarAnimations.UpdateAll(AContext: TWarModelContext);
var
  LSlot: Integer;
  LEntity: PWarEntity;
  LIndex: Integer;
  LDelta: Single;
begin
  LDelta := AContext.Clock^.DeltaTime;
  for LSlot := 1 to WAR_MODEL_MAX_ENTITIES - 1 do
  begin
    LEntity := AContext.Pool.Slots[LSlot];
    if (LEntity^.Id = 0) or (LEntity^.AnimationCount = 0) then
      Continue;
    // the list can shrink under the walk (an animation that ended is removed): the one after it is skipped, as in the original
    LIndex := 0;
    while LIndex < LEntity^.AnimationCount do
    begin
      UpdateOne(LEntity, LIndex, LDelta);
      Inc(LIndex);
    end;
  end;
end;

end.
