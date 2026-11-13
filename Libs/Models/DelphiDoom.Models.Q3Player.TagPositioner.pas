{******************************************************************************}
{                                                                              }
{  DelphiDoom: 3D models library - Quake III player models, placing an entity  }
{  on a tag of its parent                                                      }
{                                                                              }
{  Port of CG_PositionEntityOnTag and CG_PositionRotatedEntityOnTag of         }
{  cgame\cg_ents.c. Based on the Quake III Arena GPL Source Code (id           }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Models.Q3Player.TagPositioner;

{$Q-}
{$R-}

interface

uses
  System.SysUtils,
  DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Types,
  DelphiDoom.Models.Q3Player.Intf;

type
  /// <summary>
  ///   The torso of a player is on a tag of the legs, the head on a tag of the torso, a weapon on
  ///   a tag of the torso: the child takes the origin of the parent moved along the axes of the
  ///   parent by the tag, and the axes of the tag turned by the axes of the parent. A tag that
  ///   the model does not have is the identity.
  /// </summary>
  TQ3TagPositioner = class(TInterfacedObject, IQ3TagPositioner)
  strict private
    FLerper: IQ3TagLerper;
    procedure LerpParentTag(const AParent: TQ3Entity; const AParentModel: IMd3Model;
      const ATagName: AnsiString; out ATag: TQ3Orientation);
    procedure PositionOrigin(var AEntity: TQ3Entity; const AParent: TQ3Entity; const ATag: TQ3Orientation);
  public
    constructor Create(const ALerper: IQ3TagLerper);
    procedure PositionEntityOnTag(var AEntity: TQ3Entity; const AParent: TQ3Entity;
      const AParentModel: IMd3Model; const ATagName: AnsiString);
    procedure PositionRotatedEntityOnTag(var AEntity: TQ3Entity; const AParent: TQ3Entity;
      const AParentModel: IMd3Model; const ATagName: AnsiString);
  end;

implementation

uses
  DelphiDoom.Models.Q3Player.FloatMath;

constructor TQ3TagPositioner.Create(const ALerper: IQ3TagLerper);
begin
  inherited Create;
  FLerper := ALerper;
end;

procedure TQ3TagPositioner.LerpParentTag(const AParent: TQ3Entity; const AParentModel: IMd3Model;
  const ATagName: AnsiString; out ATag: TQ3Orientation);
var
  LFraction: Single;
begin
  // 1.0 - parent->backlerp is a double passed as a float
  LFraction := Single(1.0 - Double(AParent.BackLerp));
  FLerper.LerpTag(AParentModel, AParent.OldFrame, AParent.Frame, LFraction, ATagName, ATag);
end;

procedure TQ3TagPositioner.PositionOrigin(var AEntity: TQ3Entity; const AParent: TQ3Entity;
  const ATag: TQ3Orientation);
var
  LIndex: Integer;
  LProduct: Single;
begin
  // FIXME: allow origin offsets along tag?
  AEntity.Origin := AParent.Origin;
  for LIndex := 0 to 2 do
  begin
    // VectorMA( entity->origin, lerped.origin[i], parent->axis[i], entity->origin )
    LProduct := AParent.Axis[LIndex].X * ATag.Origin[LIndex];
    AEntity.Origin.X := AEntity.Origin.X + LProduct;
    LProduct := AParent.Axis[LIndex].Y * ATag.Origin[LIndex];
    AEntity.Origin.Y := AEntity.Origin.Y + LProduct;
    LProduct := AParent.Axis[LIndex].Z * ATag.Origin[LIndex];
    AEntity.Origin.Z := AEntity.Origin.Z + LProduct;
  end;
end;

procedure TQ3TagPositioner.PositionEntityOnTag(var AEntity: TQ3Entity; const AParent: TQ3Entity;
  const AParentModel: IMd3Model; const ATagName: AnsiString);
var
  LTag: TQ3Orientation;
begin
  LerpParentTag(AParent, AParentModel, ATagName, LTag);
  PositionOrigin(AEntity, AParent, LTag);
  TQ3FloatMath.MatrixMultiply(LTag.Axis, AParent.Axis, AEntity.Axis);
  AEntity.BackLerp := AParent.BackLerp;
end;

procedure TQ3TagPositioner.PositionRotatedEntityOnTag(var AEntity: TQ3Entity; const AParent: TQ3Entity;
  const AParentModel: IMd3Model; const ATagName: AnsiString);
var
  LTag: TQ3Orientation;
  LTemp: TQ3Axis;
begin
  LerpParentTag(AParent, AParentModel, ATagName, LTag);
  PositionOrigin(AEntity, AParent, LTag);
  TQ3FloatMath.MatrixMultiply(AEntity.Axis, LTag.Axis, LTemp);
  TQ3FloatMath.MatrixMultiply(LTemp, AParent.Axis, AEntity.Axis);
end;

end.
