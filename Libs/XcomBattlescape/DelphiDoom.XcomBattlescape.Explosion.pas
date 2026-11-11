{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom battlescape drawing library - an explosion sprite           }
{  (Explosion)                                                                  }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomBattlescape.Explosion;

interface

uses
  DelphiDoom.XcomMod.MapBlock;

type
  /// <summary>
  ///   An animated sprite of an explosion, of a bullet hit or of a melee or psi hit, at a voxel (Explosion): the
  ///   map draws its current frame, the step that owns it advances it
  /// </summary>
  TXcomExplosion = class
  strict private
    FPosition: TXcomPosition;
    FCurrentFrame: Integer;
    FStartFrame: Integer;
    FFrameDelay: Integer;
    FBig: Boolean;
    FHit: Boolean;
  public
    const HIT_FRAMES = 4;
    const EXPLODE_FRAMES = 8;
    const BULLET_FRAMES = 10;
    /// <param name="APosition">The center in voxels</param>
    /// <param name="AStartFrame">The first frame: different explosions can start at different frames</param>
    /// <param name="AFrameDelay">The frames to wait before the first one is shown</param>
    /// <param name="ABig">A real explosion (true) or a bullet hit (false)</param>
    /// <param name="AHit">A melee or psi hit</param>
    constructor Create(const APosition: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig, AHit: Boolean);
    /// <summary>animate: false when the animation is over</summary>
    function Animate: Boolean;
    /// <summary>getCurrentFrame: -1 while it waits</summary>
    function CurrentFrame: Integer;
    property Position: TXcomPosition read FPosition;
    property IsBig: Boolean read FBig;
    property IsHit: Boolean read FHit;
  end;

implementation

{ TXcomExplosion }

constructor TXcomExplosion.Create(const APosition: TXcomPosition; AStartFrame, AFrameDelay: Integer; ABig,
  AHit: Boolean);
begin
  inherited Create;
  FPosition := APosition;
  FCurrentFrame := AStartFrame;
  FStartFrame := AStartFrame;
  FFrameDelay := AFrameDelay;
  FBig := ABig;
  FHit := AHit;
end;

function TXcomExplosion.Animate: Boolean;
begin
  if FFrameDelay > 0 then
  begin
    Dec(FFrameDelay);
    Exit(True);
  end;
  Inc(FCurrentFrame);
  Result := not ((FHit and (FCurrentFrame = FStartFrame + HIT_FRAMES)) or
    (FBig and (FCurrentFrame = FStartFrame + EXPLODE_FRAMES)) or
    ((not FBig) and (not FHit) and (FCurrentFrame = FStartFrame + BULLET_FRAMES)));
end;

function TXcomExplosion.CurrentFrame: Integer;
begin
  if FFrameDelay > 0 then
    Result := -1
  else
    Result := FCurrentFrame;
end;

end.
