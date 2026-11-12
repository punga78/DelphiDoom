{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - what the renderer and the sound ask of the game  }
{  Port of xGreed (Jim Valavanis, GPL v2 or later): timecount, spritemovetime,  }
{  RF_CheckActionFlag of r_public.pas and the place of the player               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.Game.Hosts.Render;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Types, DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.Sound.Intf,
  DelphiDoom.Greed.Spawner.Intf, DelphiDoom.Greed.Game.Parts;

type
  /// <summary>
  ///   The game seen by what draws and by what plays: the clock of the tics and of the moves of the sprites
  ///   (the renderer places the sprites between two moves), the action hook that the renderer calls four times
  ///   while it draws a view (a TimeUpdate and the shot of the player, as RF_CheckActionFlag with SC.vrhelmet 0),
  ///   the place of the player for the sound effects, and the pictures of the monsters that the spawner asks for,
  ///   passed to the renderer once it exists. The object does not own the parts
  /// </summary>
  TGreedGameRenderHost = class(TInterfacedObject, IGreedRenderClock, IGreedRenderActionHook, IGreedListener,
    IGreedSpritePictures)
  strict private
    FParts: TGreedGameParts;
  public
    /// <summary>EArgumentNilException if AParts is nil</summary>
    constructor Create(AParts: TGreedGameParts);
    // IGreedRenderClock
    function GetTimeCount: Integer;
    function GetSpriteMoveTime: Integer;
    // IGreedRenderActionHook
    procedure CheckActionFlag;
    // IGreedListener
    function GetX: TGreedFixed;
    function GetY: TGreedFixed;
    function GetAngle: Integer;
    // IGreedSpritePictures
    procedure DemandLoadMonster(ALump, ACount: Integer);
  end;

implementation

{ TGreedGameRenderHost }

constructor TGreedGameRenderHost.Create(AParts: TGreedGameParts);
begin
  inherited Create;
  if not Assigned(AParts) then
    raise EArgumentNilException.Create('AParts');
  FParts := AParts;
end;

function TGreedGameRenderHost.GetTimeCount: Integer;
begin
  Result := FParts.State.TimeCount;
end;

function TGreedGameRenderHost.GetSpriteMoveTime: Integer;
begin
  Result := FParts.State.SpriteMoveTime;
end;

procedure TGreedGameRenderHost.CheckActionFlag;
begin
  FParts.Level.TimeUpdate;
  FParts.Control.RunActionHook;
end;

function TGreedGameRenderHost.GetX: TGreedFixed;
begin
  Result := FParts.State.Player.X;
end;

function TGreedGameRenderHost.GetY: TGreedFixed;
begin
  Result := FParts.State.Player.Y;
end;

function TGreedGameRenderHost.GetAngle: Integer;
begin
  Result := FParts.State.Player.Angle;
end;

procedure TGreedGameRenderHost.DemandLoadMonster(ALump, ACount: Integer);
begin
  if Assigned(FParts.Renderer) then
    FParts.Renderer.DemandLoadMonster(ALump, ACount);
end;

end.
