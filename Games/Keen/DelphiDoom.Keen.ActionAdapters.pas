{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - the adapters of the actions to the game           }
{  Port of Commander Keen in Keen Dreams (id Software), GPL v2 or later         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.ActionAdapters;

interface

uses
  System.SysUtils, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes, DelphiDoom.Keen.Intf,
  DelphiDoom.Keen.ActorMover, DelphiDoom.Keen.StateMachine;

type
  /// <summary>The view of the actions on the refresh manager and the clock</summary>
  TKeenActionView = class(TInterfacedObject, IKeenActionView)
  strict private
    FRefresh: IKeenRefresh;
    FClock: IKeenClock;
  public
    constructor Create(const ARefresh: IKeenRefresh; const AClock: IKeenClock);
    function GetTics: Integer;
    function GetLastTimeCount: Integer;
    function GetTimeCount: Integer;
    function GetOriginXGlobal: Integer;
    function GetOriginYGlobal: Integer;
    function GetOriginXTile: Integer;
    function GetOriginYTile: Integer;
    /// <summary>originxtilemax: the last tile of the view (CalcInactivate)</summary>
    function GetOriginXTileMax: Integer;
    function GetOriginYTileMax: Integer;
    procedure PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk, APriority: Integer);
    procedure RemoveSprite(var AUser: TKeenSpriteHandle);
  end;

  /// <summary>The motion functions of the actions on the mover and the state machine of the game</summary>
  TKeenActorPhysics = class(TInterfacedObject, IKeenActorPhysics)
  strict private
    FMover: TKeenActorMover;
    FMachine: TKeenStateMachine;
  public
    /// <param name="AMover">Not owned</param>
    /// <param name="AMachine">Not owned</param>
    constructor Create(AMover: TKeenActorMover; AMachine: TKeenStateMachine);
    procedure ClipToWalls(AObject: PKeenObject);
    procedure ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
    procedure ClipToSpriteSide(APush, ASolid: PKeenObject);
    procedure NewState(AObject: PKeenObject; AState: Integer);
  end;

implementation

{ TKeenActionView }

constructor TKeenActionView.Create(const ARefresh: IKeenRefresh; const AClock: IKeenClock);
begin
  inherited Create;
  if not Assigned(ARefresh) then
    raise EArgumentNilException.Create('ARefresh');
  if not Assigned(AClock) then
    raise EArgumentNilException.Create('AClock');
  FRefresh := ARefresh;
  FClock := AClock;
end;

function TKeenActionView.GetTics: Integer;
begin
  Result := FRefresh.Tics;
end;

function TKeenActionView.GetLastTimeCount: Integer;
begin
  Result := FRefresh.LastTimeCount;
end;

function TKeenActionView.GetTimeCount: Integer;
begin
  Result := FClock.TimeCount;
end;

function TKeenActionView.GetOriginXGlobal: Integer;
begin
  Result := FRefresh.OriginXGlobal;
end;

function TKeenActionView.GetOriginYGlobal: Integer;
begin
  Result := FRefresh.OriginYGlobal;
end;

function TKeenActionView.GetOriginXTile: Integer;
begin
  Result := FRefresh.OriginXTile;
end;

function TKeenActionView.GetOriginYTile: Integer;
begin
  Result := FRefresh.OriginYTile;
end;

function TKeenActionView.GetOriginXTileMax: Integer;
begin
  Result := FRefresh.OriginXTile + KEEN_PORTTILESWIDE - 1;
end;

function TKeenActionView.GetOriginYTileMax: Integer;
begin
  Result := FRefresh.OriginYTile + KEEN_PORTTILESHIGH - 1;
end;

procedure TKeenActionView.PlaceSprite(var AUser: TKeenSpriteHandle; AGlobalX, AGlobalY, ASpriteChunk,
  APriority: Integer);
begin
  FRefresh.PlaceSprite(AUser, AGlobalX, AGlobalY, ASpriteChunk, kdtSpriteDraw, APriority);
end;

procedure TKeenActionView.RemoveSprite(var AUser: TKeenSpriteHandle);
begin
  FRefresh.RemoveSprite(AUser);
end;

{ TKeenActorPhysics }

constructor TKeenActorPhysics.Create(AMover: TKeenActorMover; AMachine: TKeenStateMachine);
begin
  inherited Create;
  if not Assigned(AMover) then
    raise EArgumentNilException.Create('AMover');
  if not Assigned(AMachine) then
    raise EArgumentNilException.Create('AMachine');
  FMover := AMover;
  FMachine := AMachine;
end;

procedure TKeenActorPhysics.ClipToWalls(AObject: PKeenObject);
begin
  FMover.ClipToWalls(AObject);
end;

procedure TKeenActorPhysics.ClipToSprite(APush, ASolid: PKeenObject; ASquish: Boolean);
begin
  FMover.ClipToSprite(APush, ASolid, ASquish);
end;

procedure TKeenActorPhysics.ClipToSpriteSide(APush, ASolid: PKeenObject);
begin
  FMover.ClipToSpriteSide(APush, ASolid);
end;

procedure TKeenActorPhysics.NewState(AObject: PKeenObject; AState: Integer);
begin
  FMachine.NewState(AObject, AState);
end;

end.
