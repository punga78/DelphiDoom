{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the functions of the states and the spawners      }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later:        }
{  kd_keen.c, kd_act1.c and kd_act2.c                                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.GameActions;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.CommonActions, DelphiDoom.Keen.Act1Actions, DelphiDoom.Keen.Act2Actions,
  DelphiDoom.Keen.PlayerActions;

type
  /// <summary>
  ///   What a state calls (the think, contact and react of the states by number) and what puts the actors of the
  ///   info plane on the map. It makes the four groups of functions of the game and gives every call to the group
  ///   that has the function. A number that no group has is an EKeenException (a state with no code)
  /// </summary>
  TKeenGameActions = class(TInterfacedObject, IKeenActions, IKeenActorSpawner, IKeenPlayerFunctions)
  strict private
    FCommon: TKeenCommonActions;
    FAct1: TKeenAct1Actions;
    FAct2: TKeenAct2Actions;
    FPlayer: TKeenPlayerActions;
    FGroups: array[0..3] of IKeenActionGroup;
    function NameOf(AAction: Word): string;
  public
    constructor Create(const AContext: IKeenActionContext; const AGraphics: IKeenGraphics;
      const ASprites: IKeenSpriteCache);
    destructor Destroy; override;
    procedure Think(AAction: Word; AObject: PKeenObject);
    procedure Contact(AAction: Word; AObject, AOther: PKeenObject);
    procedure React(AAction: Word; AObject: PKeenObject);
    procedure SpawnKeen(ATileX, ATileY, ADirection: Integer);
    procedure SpawnWorldKeen(ATileX, ATileY: Integer);
    procedure SpawnBonus(ATileX, ATileY, AType: Integer);
    procedure SpawnDoor(ATileX, ATileY: Integer);
    procedure SpawnBrocco(ATileX, ATileY: Integer);
    procedure SpawnTomat(ATileX, ATileY: Integer);
    procedure SpawnCarrot(ATileX, ATileY: Integer);
    procedure SpawnAspar(ATileX, ATileY: Integer);
    procedure SpawnGrape(ATileX, ATileY: Integer);
    procedure SpawnTater(ATileX, ATileY: Integer);
    procedure SpawnCart(ATileX, ATileY: Integer);
    procedure SpawnFrenchy(ATileX, ATileY: Integer);
    procedure SpawnMelon(ATileX, ATileY, ADirection: Integer);
    procedure SpawnSquasher(ATileX, ATileY: Integer);
    procedure SpawnApel(ATileX, ATileY: Integer);
    procedure SpawnPeaPod(ATileX, ATileY: Integer);
    procedure SpawnPeaBrain(ATileX, ATileY: Integer);
    procedure SpawnBoobus(ATileX, ATileY: Integer);
    procedure SpawnScore;
    procedure FixScoreBox;
    procedure KillKeen;
    /// <summary>The functions of the player (the two variables of kd_keen.c, jumptime and leavepoletime, are here)</summary>
    property Player: TKeenPlayerActions read FPlayer;
  end;

implementation

uses
  DelphiDoom.Keen.ActionIds;

{ TKeenGameActions }

constructor TKeenGameActions.Create(const AContext: IKeenActionContext; const AGraphics: IKeenGraphics;
  const ASprites: IKeenSpriteCache);
begin
  inherited Create;
  FCommon := TKeenCommonActions.Create(AContext);
  FAct1 := TKeenAct1Actions.Create(AContext);
  FAct2 := TKeenAct2Actions.Create(AContext);
  FPlayer := TKeenPlayerActions.Create(AContext, FCommon, AGraphics, ASprites);
  FGroups[0] := FPlayer;
  FGroups[1] := FCommon;
  FGroups[2] := FAct1;
  FGroups[3] := FAct2;
end;

destructor TKeenGameActions.Destroy;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FGroups) do
    FGroups[LIndex] := nil;
  FPlayer.Free;
  FAct2.Free;
  FAct1.Free;
  FCommon.Free;
  inherited Destroy;
end;

function TKeenGameActions.NameOf(AAction: Word): string;
begin
  if AAction < KEEN_ACTION_COUNT then
    Result := KEEN_ACTION_NAMES[AAction]
  else
    Result := IntToStr(AAction);
end;

procedure TKeenGameActions.Think(AAction: Word; AObject: PKeenObject);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FGroups) do
    if FGroups[LIndex].TryThink(AAction, AObject) then
      Exit;
  raise EKeenException.CreateFmt(SKeenActionMissing, [NameOf(AAction)]);
end;

procedure TKeenGameActions.Contact(AAction: Word; AObject, AOther: PKeenObject);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FGroups) do
    if FGroups[LIndex].TryContact(AAction, AObject, AOther) then
      Exit;
  raise EKeenException.CreateFmt(SKeenActionMissing, [NameOf(AAction)]);
end;

procedure TKeenGameActions.React(AAction: Word; AObject: PKeenObject);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FGroups) do
    if FGroups[LIndex].TryReact(AAction, AObject) then
      Exit;
  raise EKeenException.CreateFmt(SKeenActionMissing, [NameOf(AAction)]);
end;

procedure TKeenGameActions.SpawnKeen(ATileX, ATileY, ADirection: Integer);
begin
  FPlayer.SpawnKeen(ATileX, ATileY, ADirection);
end;

procedure TKeenGameActions.SpawnWorldKeen(ATileX, ATileY: Integer);
begin
  FPlayer.SpawnWorldKeen(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnBonus(ATileX, ATileY, AType: Integer);
begin
  FCommon.SpawnBonus(ATileX, ATileY, AType);
end;

procedure TKeenGameActions.SpawnDoor(ATileX, ATileY: Integer);
begin
  FCommon.SpawnDoor(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnBrocco(ATileX, ATileY: Integer);
begin
  FAct1.SpawnBrocco(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnTomat(ATileX, ATileY: Integer);
begin
  FAct1.SpawnTomat(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnCarrot(ATileX, ATileY: Integer);
begin
  FAct1.SpawnCarrot(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnAspar(ATileX, ATileY: Integer);
begin
  FAct1.SpawnAspar(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnGrape(ATileX, ATileY: Integer);
begin
  FAct1.SpawnGrape(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnTater(ATileX, ATileY: Integer);
begin
  FAct2.SpawnTater(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnCart(ATileX, ATileY: Integer);
begin
  FAct2.SpawnCart(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnFrenchy(ATileX, ATileY: Integer);
begin
  FAct2.SpawnFrenchy(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnMelon(ATileX, ATileY, ADirection: Integer);
begin
  FAct2.SpawnMelon(ATileX, ATileY, ADirection);
end;

procedure TKeenGameActions.SpawnSquasher(ATileX, ATileY: Integer);
begin
  FAct2.SpawnSquasher(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnApel(ATileX, ATileY: Integer);
begin
  FAct2.SpawnApel(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnPeaPod(ATileX, ATileY: Integer);
begin
  FAct2.SpawnPeaPod(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnPeaBrain(ATileX, ATileY: Integer);
begin
  FAct2.SpawnPeaBrain(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnBoobus(ATileX, ATileY: Integer);
begin
  FAct2.SpawnBoobus(ATileX, ATileY);
end;

procedure TKeenGameActions.SpawnScore;
begin
  FPlayer.ScoreBox.SpawnScore;
end;

procedure TKeenGameActions.FixScoreBox;
begin
  FPlayer.ScoreBox.FixScoreBox;
end;

procedure TKeenGameActions.KillKeen;
begin
  FPlayer.KillKeen;
end;

end.
