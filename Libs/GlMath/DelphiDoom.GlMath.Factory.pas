{******************************************************************************}
{                                                                              }
{  DelphiDoom: OpenGL math library - the factory: the composition root         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.GlMath.Factory;

interface

uses
  DelphiDoom.GlMath.Intf;

type
  /// <summary>The only place that knows the classes behind the interfaces of the OpenGL math library</summary>
  TGlMathFactory = class
  public
    /// <summary>A view frustum with no planes yet (call Calculate)</summary>
    class function CreateFrustum: IGlFrustum; static;
    /// <summary>A clipper with an empty set of ranges</summary>
    class function CreateAngleClipper: IGlAngleClipper; static;
  end;

implementation

uses
  DelphiDoom.GlMath.Frustum,
  DelphiDoom.GlMath.AngleClipper;

{ TGlMathFactory }

class function TGlMathFactory.CreateFrustum: IGlFrustum;
begin
  Result := TGlFrustum.Create;
end;

class function TGlMathFactory.CreateAngleClipper: IGlAngleClipper;
begin
  Result := TGlAngleClipper.Create;
end;

end.
