{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the enemies of kd_act1.c                          }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  Broccolash, Tomatooth, Carrot Courier, Asparagusto and Sour Grape            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.Act1Actions;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.UnmanagedObject;

type
  /// <summary>The think, react and spawn functions of the first five enemies</summary>
  TKeenAct1Actions = class(TKeenUnmanagedObject, IKeenActionGroup)
  strict private
    FContext: IKeenActionContext;
    procedure BroccoThink(AObject: PKeenObject);
    procedure TomatBounceThink(AObject: PKeenObject);
    procedure TomatReact(AObject: PKeenObject);
    procedure CarrotReact(AObject: PKeenObject);
    procedure CarrotAirReact(AObject: PKeenObject);
    procedure GrapeThink(AObject: PKeenObject);
    procedure GrapeRiseReact(AObject: PKeenObject);
    procedure GrapeFallReact(AObject: PKeenObject);
  public
    constructor Create(const AContext: IKeenActionContext);
    function TryThink(AAction: Word; AObject: PKeenObject): Boolean;
    function TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
    function TryReact(AAction: Word; AObject: PKeenObject): Boolean;
    procedure SpawnBrocco(ATileX, ATileY: Integer);
    procedure SpawnTomat(ATileX, ATileY: Integer);
    procedure SpawnCarrot(ATileX, ATileY: Integer);
    procedure SpawnAspar(ATileX, ATileY: Integer);
    procedure SpawnGrape(ATileX, ATileY: Integer);
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds, DelphiDoom.Keen.AudioIds, DelphiDoom.Keen.StateTable, DelphiDoom.Keen.Arithmetic;

const
  SPD_TOMAT_BOUNCE = 30;
  TIC_TOMAT_JUMP = 10;
  SPD_TOMAT = 16;
  SPD_CARROT_LEAP_X = 32;
  SPD_CARROT_LEAP_Y = 40;

{ TKeenAct1Actions }

constructor TKeenAct1Actions.Create(const AContext: IKeenActionContext);
begin
  inherited Create;
  if not Assigned(AContext) then
    raise EArgumentNilException.Create('AContext');
  FContext := AContext;
end;

function TKeenAct1Actions.TryThink(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_BROCCOTHINK:
      BroccoThink(AObject);
    KEEN_ACTION_BROCCOGETUP:
      AObject^.NeedToClip := True;
    KEEN_ACTION_TOMATBOUNCETHINK:
      TomatBounceThink(AObject);
    KEEN_ACTION_GRAPETHINK:
      GrapeThink(AObject);
  else
    Result := False;
  end;
end;

function TKeenAct1Actions.TryContact(AAction: Word; AObject, AOther: PKeenObject): Boolean;
begin
  Result := False;
end;

function TKeenAct1Actions.TryReact(AAction: Word; AObject: PKeenObject): Boolean;
begin
  Result := True;
  case AAction of
    KEEN_ACTION_TOMATREACT:
      TomatReact(AObject);
    KEEN_ACTION_CARROTREACT:
      CarrotReact(AObject);
    KEEN_ACTION_CARROTAIRREACT:
      CarrotAirReact(AObject);
    KEEN_ACTION_GRAPERISEREACT:
      GrapeRiseReact(AObject);
    KEEN_ACTION_GRAPEFALLREACT:
      GrapeFallReact(AObject);
  else
    Result := False;
  end;
end;

procedure TKeenAct1Actions.SpawnBrocco(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcBrocco;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_BROCCOWALK1);
end;

procedure TKeenAct1Actions.BroccoThink(AObject: PKeenObject);
var
  LPlayer: PKeenObject;
  LDelta: Integer;
begin
  LPlayer := FContext.Objects.Player;
  if (AObject^.Top > LPlayer^.Bottom) or (AObject^.Bottom < LPlayer^.Top) then
    Exit;
  LDelta := TKeenArithmetic.ToInt16(Integer(LPlayer^.X) - Integer(AObject^.X));
  if AObject^.XDir = -1 then
  begin
    if LDelta < -3 * KEEN_TILEGLOBAL then
      Exit;
    if LDelta > KEEN_TILEGLOBAL div 2 then
    begin
      AObject^.XDir := 1;
      Exit;
    end;
    AObject^.State := KEEN_STATE_S_BROCCOSMASH1;
    AObject^.NeedToClip := False;
    AObject^.XMove := 0;
  end
  else
  begin
    LDelta := TKeenArithmetic.ToInt16(Integer(LPlayer^.Left) - Integer(AObject^.Right));
    if LDelta > 3 * KEEN_TILEGLOBAL then
      Exit;
    if LDelta < -KEEN_TILEGLOBAL div 2 then
    begin
      AObject^.XDir := -1;
      Exit;
    end;
    AObject^.State := KEEN_STATE_S_BROCCOSMASH1;
    AObject^.NeedToClip := False;
    AObject^.XMove := 0;
  end;
end;

procedure TKeenAct1Actions.SpawnTomat(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcTomat;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_TOMATBOUNCE);
end;

procedure TKeenAct1Actions.TomatBounceThink(AObject: PKeenObject);
var
  LTics: Integer;
begin
  if AObject^.X > FContext.Objects.Player^.X then
    FContext.AccelerateX(AObject, -1, SPD_TOMAT)
  else
    FContext.AccelerateX(AObject, 1, SPD_TOMAT);
  if AObject^.XSpeed > 0 then
    AObject^.XDir := 1
  else
    AObject^.XDir := -1;
  LTics := FContext.View.Tics;
  if AObject^.Temp1 <> 0 then
  begin
    // temp1 is an int and tics an unsigned: the C compares them as unsigned, so a negative temp1 is a large number
    if Word(AObject^.Temp1) < Word(LTics) then
    begin
      AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YSpeed * AObject^.Temp1);
      AObject^.Temp1 := 0;
    end
    else
    begin
      AObject^.YMove := TKeenArithmetic.ToInt16(AObject^.YSpeed * LTics);
      AObject^.Temp1 := TKeenArithmetic.ToInt16(AObject^.Temp1 - LTics);
    end;
  end
  else
    FContext.DoGravity(AObject);
end;

procedure TKeenAct1Actions.TomatReact(AObject: PKeenObject);
var
  LView: IKeenActionView;
  LVisible: Boolean;
begin
  LView := FContext.View;
  // the C compares unsigned tile numbers
  LVisible := (Integer(AObject^.TileRight) >= LView.OriginXTile) and (Integer(AObject^.TileLeft) <= LView.OriginXTileMax) and
    (Integer(AObject^.TileTop) >= LView.OriginYTile) and (Integer(AObject^.TileBottom) <= LView.OriginYTileMax);
  if (AObject^.HitEast <> 0) or (AObject^.HitWest <> 0) then
  begin
    AObject^.XDir := -AObject^.XDir;
    AObject^.XSpeed := -AObject^.XSpeed;
  end;
  if AObject^.HitSouth <> 0 then
  begin
    if LVisible then
      FContext.Events.PlaySound(KEEN_SND_BOUNCESND);
    AObject^.YSpeed := -AObject^.YSpeed;
  end;
  if AObject^.HitNorth <> 0 then
  begin
    if LVisible then
      FContext.Events.PlaySound(KEEN_SND_BOUNCESND);
    AObject^.YSpeed := TKeenArithmetic.ToInt16(-SPD_TOMAT_BOUNCE - (FContext.Random.RndT shr 4));
    AObject^.Temp1 := TIC_TOMAT_JUMP;
  end;
  FContext.PlaceSprite(AObject, 0);
end;

procedure TKeenAct1Actions.SpawnCarrot(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcCarrot;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord((ATileY shl 8) - 2 * KEEN_BLOCKSIZE);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_CARROTWALK1);
  LNew^.HitNorth := 1;
end;

procedure TKeenAct1Actions.CarrotReact(AObject: PKeenObject);
begin
  if (AObject^.XDir = 1) and (AObject^.HitWest <> 0) then
    AObject^.XDir := -1
  else if (AObject^.XDir = -1) and (AObject^.HitEast <> 0) then
    AObject^.XDir := 1
  else if AObject^.HitNorth = 0 then
  begin
    AObject^.X := TKeenArithmetic.ToWord(AObject^.X - AObject^.XMove);
    AObject^.Y := TKeenArithmetic.ToWord(AObject^.Y - AObject^.YMove);
    AObject^.YSpeed := -SPD_CARROT_LEAP_Y;
    AObject^.XSpeed := TKeenArithmetic.ToInt16(SPD_CARROT_LEAP_X * AObject^.XDir);
    FContext.ChangeState(AObject, KEEN_STATE_S_CARROTLEAP);
  end;
  FContext.PlaceSprite(AObject, 0);
end;

procedure TKeenAct1Actions.CarrotAirReact(AObject: PKeenObject);
begin
  if AObject^.HitSouth <> 0 then
    AObject^.YSpeed := 0;
  if AObject^.HitNorth <> 0 then
    FContext.ChangeState(AObject, KEEN_STATE_S_CARROTWALK1);
  FContext.PlaceSprite(AObject, 0);
end;

procedure TKeenAct1Actions.SpawnAspar(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcAspar;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord(ATileY shl 8);
  LNew^.XDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_ASPARWALK1);
end;

procedure TKeenAct1Actions.SpawnGrape(ATileX, ATileY: Integer);
var
  LNew: PKeenObject;
begin
  LNew := FContext.Objects.GetNewObj(False);
  LNew^.ObClass := kcGrape;
  LNew^.X := TKeenArithmetic.ToWord(ATileX shl 8);
  LNew^.Y := TKeenArithmetic.ToWord(ATileY shl 8);
  LNew^.XDir := 1;
  LNew^.YDir := 1;
  FContext.Physics.NewState(LNew, KEEN_STATE_S_GRAPEWAIT);
end;

procedure TKeenAct1Actions.GrapeThink(AObject: PKeenObject);
var
  LPlayer: PKeenObject;
  LY: Integer;
begin
  LPlayer := FContext.Objects.Player;
  if (LPlayer^.Left > AObject^.Right) or (LPlayer^.Right < AObject^.Left) or (LPlayer^.Y < AObject^.Y) then
    Exit;
  // are there walls between the grape and the player?
  LY := AObject^.TileBottom;
  while Word(LY) < LPlayer^.TileTop do
  begin
    if FContext.NorthWall(FContext.Tile(1, AObject^.TileMidX, LY)) <> 0 then
      Exit;
    Inc(LY);
  end;
  AObject^.State := KEEN_STATE_S_GRAPEFALL;
  FContext.Events.PlaySound(KEEN_SND_GRAPESCREAMSND);
end;

procedure TKeenAct1Actions.GrapeRiseReact(AObject: PKeenObject);
begin
  if AObject^.HitSouth <> 0 then
    FContext.ChangeState(AObject, KEEN_STATE_S_GRAPEWAIT);
  FContext.PlaceSprite(AObject, 0);
end;

procedure TKeenAct1Actions.GrapeFallReact(AObject: PKeenObject);
begin
  if AObject^.HitNorth <> 0 then
  begin
    FContext.Events.PlaySound(KEEN_SND_BOUNCESND);
    AObject^.YSpeed := TKeenArithmetic.ToInt16((-(Integer(AObject^.YSpeed) shl 1)) div 3);
    if AObject^.YSpeed > -32 then
      FContext.ChangeState(AObject, KEEN_STATE_S_GRAPESIT);
  end;
  FContext.PlaceSprite(AObject, 0);
end;

end.
