{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the articulatedFigure declaration - fakes              }
{                                                                              }
{  A model with joints known by name, and a kit that parses one declaration    }
{  alone with the fake base of the effects tests.                              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.ArticulatedFigureSupport;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.IdLib.Math.Vec3, DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Base,
  DelphiDoom.Decl.ArticulatedFigure, DelphiDoom.Decl.ArticulatedFigure.Intf, DelphiDoom.Tests.Decl.EffectsSupport;

type
  /// <summary>The joints of a model: a name and a place, with an identity axis; an unknown name is not a joint</summary>
  TFakeJointResolver = class(TInterfacedObject, IAfJointResolver)
  strict private
    FJoints: TDictionary<string, TIdVec3>;
    FAsked: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Add(const AName: string; const AX, AY, AZ: Single);
    function GetJointTransform(const AJointName: AnsiString; out AOrigin: TIdVec3; out AAxis: TIdMat3): Boolean;
    /// <summary>The names asked, in order</summary>
    property Asked: TStringList read FAsked;
  end;

  /// <summary>
  ///   Parses figures one at a time: each one has the fake base (name, text, log) and a finder that knows nothing.
  ///   <c>Lines</c> has the warnings of the lexer and of <c>Finish</c> as <c>W: text</c>.
  /// </summary>
  TArticulatedFigureKit = class
  strict private
    FLines: TStringList;
    FLog: IInterface;
    FFinder: IDeclFinder;
    FBases: TDictionary<string, TFakeDeclBase>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>
    ///   Makes a figure named <c>AName</c> from the text <c>ABody</c> (what follows the name: <c>{ ... }</c>) and parses it;
    ///   <c>AParsed</c> is what <c>Parse</c> said
    /// </summary>
    function Make(const AName: AnsiString; const ABody: AnsiString; out AParsed: Boolean): IDecl; overload;
    function Make(const AName: AnsiString; const ABody: AnsiString): IDecl; overload;
    /// <summary>The fake base of a figure made here (for <c>Replaced</c>)</summary>
    function BaseOf(const AName: AnsiString): TFakeDeclBase;
    property Lines: TStringList read FLines;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Tests.Scanner.IdFakes;

{ TFakeJointResolver }

constructor TFakeJointResolver.Create;
begin
  inherited Create;
  FJoints := TDictionary<string, TIdVec3>.Create;
  FAsked := TStringList.Create;
end;

destructor TFakeJointResolver.Destroy;
begin
  FAsked.Free;
  FJoints.Free;
  inherited Destroy;
end;

procedure TFakeJointResolver.Add(const AName: string; const AX, AY, AZ: Single);
begin
  FJoints.AddOrSetValue(AName, TIdVec3.Create(AX, AY, AZ));
end;

function TFakeJointResolver.GetJointTransform(const AJointName: AnsiString; out AOrigin: TIdVec3;
  out AAxis: TIdMat3): Boolean;
begin
  FAsked.Add(string(AJointName));
  AAxis := TIdMat3.Identity;
  Result := FJoints.TryGetValue(string(AJointName), AOrigin);
  if not Result then
    AOrigin.Zero;
end;

{ TArticulatedFigureKit }

constructor TArticulatedFigureKit.Create;
var
  LLog: TFakeIdLibLog;
begin
  inherited Create;
  FLines := TStringList.Create;
  LLog := TFakeIdLibLog.Create(FLines);
  FLog := LLog;
  FFinder := TFakeDeclFinder.Create(FLines, LLog);
  FBases := TDictionary<string, TFakeDeclBase>.Create;
end;

destructor TArticulatedFigureKit.Destroy;
begin
  FBases.Free;
  FFinder := nil;
  FLog := nil;
  FLines.Free;
  inherited Destroy;
end;

function TArticulatedFigureKit.Make(const AName: AnsiString; const ABody: AnsiString; out AParsed: Boolean): IDecl;
var
  LFigure: TDeclArticulatedFigure;
begin
  LFigure := TDeclArticulatedFigure.Create;
  Result := LFigure;
  FBases.AddOrSetValue(string(AName), TFakeDeclMaker.Attach(LFigure, DECL_AF, AName, FFinder, FLog as IIdLibLog));
  AParsed := LFigure.Parse('articulatedFigure ' + AName + #10 + ABody);
end;

function TArticulatedFigureKit.Make(const AName: AnsiString; const ABody: AnsiString): IDecl;
var
  LParsed: Boolean;
begin
  Result := Make(AName, ABody, LParsed);
end;

function TArticulatedFigureKit.BaseOf(const AName: AnsiString): TFakeDeclBase;
begin
  FBases.TryGetValue(string(AName), Result);
end;

end.
