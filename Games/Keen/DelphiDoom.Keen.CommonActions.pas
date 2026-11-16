{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the common actions, doors, flowers and bonuses    }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  DrawReact, WalkReact, SpawnDoor, ChangeToFlower, SpawnBonus... of kd_act1.c  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.CommonActions;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.UnmanagedObject;

type
  /// <summary>
  ///   The functions that most of the actors use (sprites drawn at a priority, the walk that turns at a wall) and the
  ///   door, the flower that an actor becomes and the bonus
  /// </summary>
  TKeenCommonActions = class(TKeenUnmanagedObject, IKeenActionGroup, IKeenFlowerChanger)
  strict private
    FContext: IKeenActionContext;
    procedure WalkReact(AObject: PKeenObject);
    procedure ChangeFromFlower(AObject: PKeenObject);
    procedure FlowerThink(AObject: PKeenObject);
    procedure BonusThink(AObject: PKeenObject);
  public
    constructor Create(const AContext: IKeenActionContext);
    /// <summary>ChangeToFlower: an enemy hit by a flower power becomes a flower for a while</summary>
    procedure ChangeToFlower(AObject: PKeenObject);
    function TryThink(AAction: Word; AObject: PKeenObject): Boolean;
    function TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
    function TryReact(AAction: Word; AObject: PKeenObject): Boolean;
    procedure SpawnDoor(ATileX, ATileY: Integer);
    procedure SpawnBonus(ATileX, ATileY, AType: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.GraphicsIds, DelphiDoom.Keen.StateTable,
  DelphiDoom.Keen.Arithmetic;

const
  FLOWER_TIME: array[0..3] of Integer = (700, 700, 350, 175);
  BONUS_SHAPE: array[0..11] of Integer = (KEEN_GFX_PEPPERMINT1SPR, KEEN_GFX_COOKIE1SPR, KEEN_GFX_CANDYCANE1SPR,
    KEEN_GFX_CANDYBAR1SPR, KEEN_GFX_LOLLIPOP1SPR, KEEN_GFX_COTTONCANDY1SPR, KEEN_GFX_EXTRAKEEN1SPR,
    KEEN_GFX_SUPERBONUS1SPR, KEEN_GFX_FLOWERPOWER1SPR, KEEN_GFX_FLOWERPOWERUP1SPR, KEEN_GFX_BOOBUSBOMB1SPR,
    KEEN_GFX_MAGICKEY1SPR);

{ TKeenCommonActions }

constructor TKeenCommonActions.Create(const AContext: IKeenActionContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  FContext := AContext;
end;

function TKeenCommonActions.TryThink(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_PROJECTILETHINK:
      FContext.ProjectileThink(AObject);
    KEEN_ACTION_FLOWERTHINK:
      FlowerThink(AObject);
    KEEN_ACTION_CHANGEFROMFLOWER:
      ChangeFromFlower(AObject);
    KEEN_ACTION_BONUSTHINK:
      BonusThink(AObject);
  else
    Result := False;
  end;
end;

function TKeenCommonActions.TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
begin
  Result := AAction = KEEN_ACTION_DOORCONTACT;
  if Result then
    // DoorContact
    FContext.Physics.ClipToSpriteSide(AOther, AObject);
end;

function TKeenCommonActions.TryReact(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_DRAWREACT:
      FContext.PlaceSprite(AObject, 1);
    KEEN_ACTION_DRAWREACT2:
      FContext.PlaceSprite(AObject, 2);
    KEEN_ACTION_DRAWREACT3:
      FContext.PlaceSprite(AObject, 3);
    KEEN_ACTION_WALKREACT:
      WalkReact(AObject);
  else
    Result := False;
  end;
end;

procedure TKeenCommonActions.WalkReact(AObject: PKeenObject);
begin
  if (AObject^.XDir = 1) and (AObject^.HitWest <> 0) then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
    AObject^.XDir := -1;
    AObject^.NoThink := FContext.Random.RndT shr 5;
    FContext.ChangeState(AObject, AObject^.State);
  end
  else if (AObject^.XDir = -1) and (AObject^.HitEast <> 0) then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
    AObject^.XDir := 1;
    AObject^.NoThink := FContext.Random.RndT shr 5;
    FContext.ChangeState(AObject, AObject^.State);
  end
  else if AObject^.HitNorth = 0 then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - 2 * AObject^.XMove);
    AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y - AObject^.YMove);
    AObject^.XDir := -AObject^.XDir;
    AObject^.NoThink := FContext.Random.RndT shr 5;
    FContext.ChangeState(AObject, AObject^.State);
  end;
  FContext.PlaceSprite(AObject, 0);
end;

procedure TKeenCommonActions.SpawnDoor(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcDoor;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  LNew^.YDir := -1;
  LNew^.NeedToClip := False;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_DOOR);
end;

procedure TKeenCommonActions.ChangeToFlower(AObject: PKeenObject);
var
  LNew: PKeenObject;
begin
  FContext.Events.PlaySound(KEEN_SND_FLOWERPOWERSND);
  AObject^.Y := TKeenArithmetic.ToWord(AObject^.Bottom - KEEN_TILEGLOBAL * 2);
  AObject^.Temp1 := Ord(AObject^.ObClass);
  AObject^.Temp2 := AObject^.State;
  AObject^.Temp3 := 0;
  AObject^.NeedToClip := True;
  AObject^.ObClass := kcInert;
  AObject^.XSpeed := 0;
  FContext.ChangeState(AObject, KEEN_STATE_S_FLOWER1);
  AObject^.Active := kaAllways; // a flower is never deactivated
  LNew := FContext.Objects.GetNewObj(True);
  LNew^.X := AObject^.X;
  LNew^.Y := AObject^.Y;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_POOFTO1);
  LNew^.Active := kaRemovable;
end;

procedure TKeenCommonActions.FlowerThink(AObject: PKeenObject);
var
  LNew: PKeenObject;
begin
  FContext.ProjectileThink(AObject);
  AObject^.Temp3 := TKeenArithmetic.ToInt16(AObject^.Temp3 + FContext.View.Tics);
  if AObject^.Temp3 >= FLOWER_TIME[FContext.Play.GameState^.Difficulty and 3] then
  begin
    LNew := FContext.Objects.GetNewObj(True);
    LNew^.Active := kaAllways;
    // the C keeps the pointer to the flower: here its place in the list
    LNew^.Temp1 := AObject^.Slot;
    LNew^.X := AObject^.X;
    LNew^.Y := AObject^.Y;
    FContext.Physics.NewState(LNew, KEEN_STATE_S_POOFFROM1);
    AObject^.Temp3 := 0;
  end;
end;

procedure TKeenCommonActions.ChangeFromFlower(AObject: PKeenObject);
var
  LFlower: PKeenObject;
  LOldBottom: Word;
begin
  FContext.Events.PlaySound(KEEN_SND_UNFLOWERPOWERSND);
  LFlower := FContext.Objects[AObject^.Temp1];
  LOldBottom := LFlower^.Bottom;
  FContext.ChangeState(LFlower, LFlower^.Temp2);
  LFlower^.Y := TKeenArithmetic.ToWord(LFlower^.Y + LOldBottom - LFlower^.Bottom);
  LFlower^.ObClass := TKeenClass(LFlower^.Temp1);
  LFlower^.Active := kaYes; // allow it to unspawn now if off screen
end;

procedure TKeenCommonActions.SpawnBonus(ATileX, ATileY, AType: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.NeedToClip := False;
  LNew^.ObClass := kcBonus;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord(ATileY shl 8);
  if AType = 9 then
    LNew^.Y := TKeenArithmetic.ToWord(LNew^.Y - 8 * KEEN_PIXGLOBAL); // flower power up one block
  LNew^.YDir := -1; // bonus stuff flies up when touched
  LNew^.Temp1 := AType;
  LNew^.Temp2 := BONUS_SHAPE[AType];
  LNew^.ShapeNum := Word(BONUS_SHAPE[AType]);
  if AType <> 7 then
    LNew^.Temp3 := LNew^.Temp2 + 2
  else
    LNew^.Temp3 := LNew^.Temp2 + 4; // super bonus is 4 stage animation
  FContext.Physics.NewState(LNew, KEEN_STATE_S_BONUS);
end;

procedure TKeenCommonActions.BonusThink(AObject: PKeenObject);
begin
  Inc(AObject^.ShapeNum);
  if AObject^.ShapeNum = Word(AObject^.Temp3) then
    AObject^.ShapeNum := Word(AObject^.Temp2);
end;

end.
