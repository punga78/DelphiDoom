{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - the recorder of I3D drawing    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.I3dRecorder;

interface

uses
  System.SysUtils, System.Generics.Collections,
  DelphiDoom.Models.Intf, DelphiDoom.Models.I3d.Intf, DelphiDoom.Tests.Models.Fingerprint;

type
  /// <summary>
  ///   A fake target of the drawing of an I3D model: it fingerprints every call with its numbers
  ///   (the bits of the Single values) and keeps a short text of them. The same class is used by
  ///   the temporary harness that runs the old RenderGL with fake OpenGL functions, so the two
  ///   sides fingerprint the same way.
  /// </summary>
  TI3dRecorder = class(TInterfacedObject, IModelRenderer, II3dRenderTarget)
  strict private
    FPrint: TFingerprint;
    FCalls: Integer;
    FLog: TList<string>;
    FKeepLog: Boolean;
    procedure Note(const ACode: Integer; const AText: string);
  public
    constructor Create(const AKeepLog: Boolean = False);
    destructor Destroy; override;
    procedure BeginPrimitive(const AMode: Integer);
    procedure EndPrimitive;
    procedure TexCoord2f(const AU, AV: Single);
    procedure Vertex3f(const AX, AY, AZ: Single);
    procedure Color3f(const AR, AG, AB: Single);
    procedure Color4f(const AR, AG, AB, AA: Single);
    procedure Normal3f(const ANX, ANY, ANZ: Single);
    procedure MatrixMode(const AMode: Integer);
    procedure PushMatrix;
    procedure PopMatrix;
    procedure Translatef(const AX, AY, AZ: Single);
    procedure Rotatef(const AAngle, AX, AY, AZ: Single);
    procedure LoadIdentity;
    procedure Scalef(const AX, AY, AZ: Single);
    procedure SetTexturing(const AEnabled: Boolean);
    procedure BindTexture(const ATextureIndex: Integer);
    procedure ResetTextureCache;
    function Hash: string;
    property Calls: Integer read FCalls;
    /// <summary>One text per call (only when asked in the constructor)</summary>
    property Log: TList<string> read FLog;
  end;

implementation

{ TI3dRecorder }

constructor TI3dRecorder.Create(const AKeepLog: Boolean);
begin
  inherited Create;
  FPrint := TFingerprint.Create;
  FLog := TList<string>.Create;
  FKeepLog := AKeepLog;
end;

destructor TI3dRecorder.Destroy;
begin
  FLog.Free;
  FPrint.Free;
  inherited Destroy;
end;

procedure TI3dRecorder.Note(const ACode: Integer; const AText: string);
begin
  Inc(FCalls);
  FPrint.AddInteger(ACode);
  if FKeepLog then
    FLog.Add(AText);
end;

function TI3dRecorder.Hash: string;
begin
  Result := FPrint.ToHex;
end;

procedure TI3dRecorder.BeginPrimitive(const AMode: Integer);
begin
  Note(1, Format('begin %d', [AMode]));
  FPrint.AddInteger(AMode);
end;

procedure TI3dRecorder.EndPrimitive;
begin
  Note(2, 'end');
end;

procedure TI3dRecorder.TexCoord2f(const AU, AV: Single);
begin
  Note(3, 'texcoord');
  FPrint.AddSingle(AU);
  FPrint.AddSingle(AV);
end;

procedure TI3dRecorder.Vertex3f(const AX, AY, AZ: Single);
begin
  Note(4, Format('vertex %g %g %g', [AX, AY, AZ]));
  FPrint.AddSingle(AX);
  FPrint.AddSingle(AY);
  FPrint.AddSingle(AZ);
end;

procedure TI3dRecorder.Color3f(const AR, AG, AB: Single);
begin
  Note(20, 'color3');
  FPrint.AddSingle(AR);
  FPrint.AddSingle(AG);
  FPrint.AddSingle(AB);
end;

procedure TI3dRecorder.Color4f(const AR, AG, AB, AA: Single);
begin
  Note(5, Format('color %g %g %g %g', [AR, AG, AB, AA]));
  FPrint.AddSingle(AR);
  FPrint.AddSingle(AG);
  FPrint.AddSingle(AB);
  FPrint.AddSingle(AA);
end;

procedure TI3dRecorder.Normal3f(const ANX, ANY, ANZ: Single);
begin
  Note(21, 'normal');
  FPrint.AddSingle(ANX);
  FPrint.AddSingle(ANY);
  FPrint.AddSingle(ANZ);
end;

procedure TI3dRecorder.MatrixMode(const AMode: Integer);
begin
  Note(22, 'matrixmode');
  FPrint.AddInteger(AMode);
end;

procedure TI3dRecorder.PushMatrix;
begin
  Note(8, 'push');
end;

procedure TI3dRecorder.PopMatrix;
begin
  Note(9, 'pop');
end;

procedure TI3dRecorder.Translatef(const AX, AY, AZ: Single);
begin
  Note(10, Format('translate %g %g %g', [AX, AY, AZ]));
  FPrint.AddSingle(AX);
  FPrint.AddSingle(AY);
  FPrint.AddSingle(AZ);
end;

procedure TI3dRecorder.Rotatef(const AAngle, AX, AY, AZ: Single);
begin
  Note(11, Format('rotate %g %g %g %g', [AAngle, AX, AY, AZ]));
  FPrint.AddSingle(AAngle);
  FPrint.AddSingle(AX);
  FPrint.AddSingle(AY);
  FPrint.AddSingle(AZ);
end;

procedure TI3dRecorder.LoadIdentity;
begin
  Note(23, 'identity');
end;

procedure TI3dRecorder.Scalef(const AX, AY, AZ: Single);
begin
  Note(24, 'scale');
  FPrint.AddSingle(AX);
  FPrint.AddSingle(AY);
  FPrint.AddSingle(AZ);
end;

procedure TI3dRecorder.SetTexturing(const AEnabled: Boolean);
begin
  Note(6, Format('texturing %s', [BoolToStr(AEnabled, True)]));
  FPrint.AddBoolean(AEnabled);
end;

procedure TI3dRecorder.BindTexture(const ATextureIndex: Integer);
begin
  Note(7, Format('bind %d', [ATextureIndex]));
  FPrint.AddInteger(ATextureIndex);
end;

procedure TI3dRecorder.ResetTextureCache;
begin
  Note(12, 'reset');
end;

end.
