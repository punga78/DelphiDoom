{******************************************************************************}
{                                                                              }
{  DelphiDoom: greed library - makes the renderer of a game from an archive     }
{  Port of xGreed (Jim Valavanis, GPL v2 or later)                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Greed.GameRendererFactory;

interface

uses
  System.SysUtils, DelphiDoom.Greed.Intf, DelphiDoom.Greed.Actor.Types, DelphiDoom.Greed.LinkedPool,
  DelphiDoom.Greed.Random, DelphiDoom.Greed.Render.Types, DelphiDoom.Greed.GameRenderer.Intf;

type
  /// <summary>The first person renderer of the library on the lumps of an archive (GREED.BLO)</summary>
  TGreedGameRendererFactory = class(TInterfacedObject, IGreedGameRendererFactory)
  strict private
    FArchive: IGreedArchive;
  public
    /// <summary>EArgumentNilException if the archive is nil</summary>
    constructor Create(const AArchive: IGreedArchive);
    function CreateRenderer(ASprites: TGreedLinkedPool<TGreedSprite>; const AClock: IGreedRenderClock;
      const ARandom: IGreedRandom): IGreedGameRenderer;
  end;

implementation

uses
  DelphiDoom.Greed.GameRenderer;

{ TGreedGameRendererFactory }

constructor TGreedGameRendererFactory.Create(const AArchive: IGreedArchive);
begin
  inherited Create;
  if not Assigned(AArchive) then
    raise EArgumentNilException.Create('AArchive');
  FArchive := AArchive;
end;

function TGreedGameRendererFactory.CreateRenderer(ASprites: TGreedLinkedPool<TGreedSprite>;
  const AClock: IGreedRenderClock; const ARandom: IGreedRandom): IGreedGameRenderer;
begin
  Result := TGreedGameRenderer.Create(FArchive, ASprites, AClock, ARandom);
end;

end.
