{******************************************************************************}
{                                                                              }
{  DelphiDoom: war library - the animations of a scene                         }
{                                                                              }
{  Port of war1 (acoto87/war1), war_animations.c (wanim_addAnimation,          }
{  wanim_updateAnimations, wanim_removeAnimation) and renderAnimation of       }
{  war_entities.c for the entity of type animation of a scene, (c) 2019        }
{  Alejandro Coto Gutierrez, zlib License (see Libs\War\LICENSE-war1.txt).     }
{  This is an altered version, not the original.                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.War.Ui.Animations;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.War.Render.Transform, DelphiDoom.War.Ui.Animation;

type
  /// <summary>
  ///   The animations of the entity of a scene (an entity of type animation that has no transform, so the animations
  ///   are drawn at the origin plus their own offset). Defect of the original kept: an animation that finished is
  ///   removed while the list is walked, so the one after it is not updated in that frame
  /// </summary>
  TWarUiAnimations = class
  strict private
    FItems: TObjectList<TWarUiAnimation>;
    function GetCount: Integer;
    function GetItem(AIndex: Integer): TWarUiAnimation;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>wanim_addAnimation: the list owns the animation</summary>
    procedure Add(const AAnimation: TWarUiAnimation);
    /// <summary>wanim_updateAnimations for the entity</summary>
    procedure Update(AInScene: Boolean; ARealDeltaTime, AGlobalSpeed, AGameDeltaTime: Single);
    /// <summary>renderAnimation: the running animations in the order they were added</summary>
    procedure Render(const ATransform: TWarRenderTransform);
    property Count: Integer read GetCount;
    property Items[AIndex: Integer]: TWarUiAnimation read GetItem; default;
  end;

implementation

{ TWarUiAnimations }

constructor TWarUiAnimations.Create;
begin
  inherited Create;
  FItems := TObjectList<TWarUiAnimation>.Create(True);
end;

destructor TWarUiAnimations.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TWarUiAnimations.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TWarUiAnimations.GetItem(AIndex: Integer): TWarUiAnimation;
begin
  Result := FItems[AIndex];
end;

procedure TWarUiAnimations.Add(const AAnimation: TWarUiAnimation);
begin
  FItems.Add(AAnimation);
end;

procedure TWarUiAnimations.Update(AInScene: Boolean; ARealDeltaTime, AGlobalSpeed, AGameDeltaTime: Single);
var
  LIndex: Integer;
begin
  // for (k = 0; k < count; k++): a removal shifts the next animation into k and k moves on
  LIndex := 0;
  while LIndex < FItems.Count do
  begin
    if FItems[LIndex].Status = wasFinished then
      FItems.Delete(LIndex)
    else
      FItems[LIndex].Update(AInScene, ARealDeltaTime, AGlobalSpeed, AGameDeltaTime);
    Inc(LIndex);
  end;
end;

procedure TWarUiAnimations.Render(const ATransform: TWarRenderTransform);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FItems.Count - 1 do
    FItems[LIndex].Render(ATransform);
end;

end.
