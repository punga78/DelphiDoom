{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the OpenGL math library - the new classes as subject   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.GlMath.Subject;

interface

uses
  DelphiDoom.GlMath.Types,
  DelphiDoom.GlMath.Intf,
  DelphiDoom.Tests.GlMath.Scenarios;

type
  /// <summary>The classes of the library, asked by the scenarios of parity</summary>
  TGlMathSubject = class(TInterfacedObject, IGlMathSubject)
  strict private
    FFrustum: IGlFrustum;
    FClipper: IGlAngleClipper;
  public
    constructor Create;
    procedure CalculateFrustum(const AProjection, AModelView: TGlMatrix4);
    function Plane(const ASide, AIndex: Integer): Single;
    function ContainsPoint(const AX, AY, AZ: Single): Boolean;
    function ContainsSphere(const AX, AY, AZ, ARadius: Single): Boolean;
    function ContainsBox(const AX, AY, AZ, ASizeX, ASizeY, ASizeZ: Single): Boolean;
    function ContainsCube(const AX, AY, AZ, ASize: Single): Boolean;
    procedure ClipperClear;
    procedure ClipperSafeAdd(const AStart, AEnd: Cardinal);
    function ClipperSafeCheck(const AStart, AEnd: Cardinal): Boolean;
    function ClipperCount: Integer;
    function ClipperStart(const AIndex: Integer): Cardinal;
    function ClipperFinish(const AIndex: Integer): Cardinal;
    function FrustumAngle(const ALookDirection16: Integer; const AAspect: Double): Cardinal;
  end;

implementation

uses
  DelphiDoom.GlMath.Factory,
  DelphiDoom.GlMath.ViewAngle;

{ TGlMathSubject }

constructor TGlMathSubject.Create;
begin
  inherited Create;
  FFrustum := TGlMathFactory.CreateFrustum;
  FClipper := TGlMathFactory.CreateAngleClipper;
end;

procedure TGlMathSubject.CalculateFrustum(const AProjection, AModelView: TGlMatrix4);
begin
  FFrustum.Calculate(AProjection, AModelView);
end;

function TGlMathSubject.Plane(const ASide, AIndex: Integer): Single;
begin
  Result := FFrustum.GetPlane(TGlFrustumSide(ASide), AIndex);
end;

function TGlMathSubject.ContainsPoint(const AX, AY, AZ: Single): Boolean;
begin
  Result := FFrustum.ContainsPoint(AX, AY, AZ);
end;

function TGlMathSubject.ContainsSphere(const AX, AY, AZ, ARadius: Single): Boolean;
begin
  Result := FFrustum.ContainsSphere(AX, AY, AZ, ARadius);
end;

function TGlMathSubject.ContainsBox(const AX, AY, AZ, ASizeX, ASizeY, ASizeZ: Single): Boolean;
begin
  Result := FFrustum.ContainsBox(AX, AY, AZ, ASizeX, ASizeY, ASizeZ);
end;

function TGlMathSubject.ContainsCube(const AX, AY, AZ, ASize: Single): Boolean;
begin
  Result := FFrustum.ContainsCube(AX, AY, AZ, ASize);
end;

procedure TGlMathSubject.ClipperClear;
begin
  FClipper.Clear;
end;

procedure TGlMathSubject.ClipperSafeAdd(const AStart, AEnd: Cardinal);
begin
  FClipper.SafeAddRange(AStart, AEnd);
end;

function TGlMathSubject.ClipperSafeCheck(const AStart, AEnd: Cardinal): Boolean;
begin
  Result := FClipper.SafeCheckRange(AStart, AEnd);
end;

function TGlMathSubject.ClipperCount: Integer;
begin
  Result := FClipper.GetRangeCount;
end;

function TGlMathSubject.ClipperStart(const AIndex: Integer): Cardinal;
begin
  Result := FClipper.GetRangeStart(AIndex);
end;

function TGlMathSubject.ClipperFinish(const AIndex: Integer): Cardinal;
begin
  Result := FClipper.GetRangeFinish(AIndex);
end;

function TGlMathSubject.FrustumAngle(const ALookDirection16: Integer;
  const AAspect: Double): Cardinal;
begin
  Result := TGlViewAngle.FrustumAngle(ALookDirection16, AAspect);
end;

end.
