{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the 3D models library - world of the animator tests    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Models.AnimatorSupport;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Models.Source.Intf,
  DelphiDoom.Models.Md5.Intf,
  DelphiDoom.Models.Md5.JointQuat,
  DelphiDoom.Models.Md5.JointMat,
  DelphiDoom.Models.Anim.Types,
  DelphiDoom.Models.Anim.Intf,
  DelphiDoom.Models.Anim.ModelDef,
  DelphiDoom.Models.Anim.Blend.Types,
  DelphiDoom.Models.Anim.Blend,
  DelphiDoom.Models.Anim.Animator,
  DelphiDoom.Tests.Models.AnimSupport;

type
  /// <summary>An entity that records what the animator tells it</summary>
  TFakeAnimatorEntity = class(TInterfacedObject, IAnimatorEntity)
  strict private
    FEvents: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure CallFrameCommand(const AAnim: IAnim; const AFrame: Integer; const ACommand: TAnimFrameCommand);
    procedure BecomeActive(const AFlags: Integer);
    procedure BecomeInactive(const AFlags: Integer);
    /// <summary>Every event as text: active:4, inactive:4, cmd:anim:frame:type</summary>
    property Events: TList<string> read FEvents;
    function Joined: string;
  end;

  /// <summary>
  ///   A model with two joints (the cube of Tests\Data\Models\md5), three animations (1 idle: the
  ///   synthetic cube animation of 3 frames and 83 ms; 2 short: 2 frames; 3 blend: both together)
  ///   and a log that keeps the warnings
  /// </summary>
  TAnimatorWorld = class
  strict private
    FFiles: TFakeFiles;
    FFilesIntf: IModelFileSource;
    FManager: IAnimManager;
    FModel: IMd5Model;
    FModelDef: TModelDef;
    FModelDefIntf: IModelDef;
    FLog: TRecordingLog;
    FLogIntf: IIdLibLog;
    FIdle, FShort: IMd5Anim;
  public
    constructor Create;
    destructor Destroy; override;
    function NewBlend(const ARandom: TAnimRandomFloat = nil): TAnimBlend;
    function NewAnimator(const ARandom: TAnimRandomFloat = nil): TAnimator;
    /// <summary>The absolute matrices (parents first) of a relative pose, with the offset of the definition on the root</summary>
    function Absolute(const AFrame: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
    property Model: IMd5Model read FModel;
    property ModelDef: IModelDef read FModelDefIntf;
    property ModelDefObject: TModelDef read FModelDef;
    property Idle: IMd5Anim read FIdle;
    property Short: IMd5Anim read FShort;
    property Log: TRecordingLog read FLog;
    property Manager: IAnimManager read FManager;
  end;

implementation

uses
  DelphiDoom.Models.Md5.Factory,
  DelphiDoom.Models.Anim.Factory;

{ TFakeAnimatorEntity }

constructor TFakeAnimatorEntity.Create;
begin
  inherited Create;
  FEvents := TList<string>.Create;
end;

destructor TFakeAnimatorEntity.Destroy;
begin
  FEvents.Free;
  inherited Destroy;
end;

procedure TFakeAnimatorEntity.CallFrameCommand(const AAnim: IAnim; const AFrame: Integer;
  const ACommand: TAnimFrameCommand);
begin
  FEvents.Add(Format('cmd:%s:%d:%d', [string(AAnim.FullName), AFrame, Ord(ACommand.CommandType)]));
end;

procedure TFakeAnimatorEntity.BecomeActive(const AFlags: Integer);
begin
  FEvents.Add(Format('active:%d', [AFlags]));
end;

procedure TFakeAnimatorEntity.BecomeInactive(const AFlags: Integer);
begin
  FEvents.Add(Format('inactive:%d', [AFlags]));
end;

function TFakeAnimatorEntity.Joined: string;
begin
  Result := string.Join(' ', FEvents.ToArray);
end;

{ TAnimatorWorld }

constructor TAnimatorWorld.Create;
var
  LAnim: IAnim;
begin
  inherited Create;
  FFiles := TFakeFiles.Create;
  FFilesIntf := FFiles;
  FFiles.Put('cube.md5anim', CubeAnimText);
  FFiles.Put('short.md5anim', ShortAnimText);
  FLog := TRecordingLog.Create;
  FLogIntf := FLog;
  FManager := TAnimFactory.CreateManager(FFilesIntf, FLogIntf);
  FModel := TMd5Factory.CreateModelParser.Parse(CubeModelText, 'cube.md5mesh');
  FIdle := FManager.GetAnim('cube.md5anim');
  FShort := FManager.GetAnim('short.md5anim');
  FModelDef := TModelDef.Create('cube');
  FModelDefIntf := FModelDef;
  FModelDef.SetModel(FModel);
  LAnim := TAnimFactory.CreateAnim(FManager, 'idle1', 'idle', [FIdle]);
  FModelDef.AddAnim(LAnim);
  LAnim := TAnimFactory.CreateAnim(FManager, 'short1', 'short', [FShort]);
  FModelDef.AddAnim(LAnim);
  LAnim := TAnimFactory.CreateAnim(FManager, 'blend1', 'blend', [FIdle, FShort]);
  FModelDef.AddAnim(LAnim);
end;

destructor TAnimatorWorld.Destroy;
begin
  FModelDefIntf := nil;
  FModelDef := nil;
  FIdle := nil;
  FShort := nil;
  FModel := nil;
  FManager := nil;
  FLogIntf := nil;
  FFilesIntf := nil;
  inherited Destroy;
end;

function TAnimatorWorld.NewBlend(const ARandom: TAnimRandomFloat): TAnimBlend;
begin
  Result := TAnimBlend.Create(FLogIntf, ARandom);
  Result.Reset(FModelDefIntf);
end;

function TAnimatorWorld.NewAnimator(const ARandom: TAnimRandomFloat): TAnimator;
begin
  Result := TAnimFactory.CreateAnimator(FLogIntf, ARandom);
  Result.SetModelDef(FModelDefIntf);
end;

function TAnimatorWorld.Absolute(const AFrame: TArray<TMd5JointQuat>): TArray<TMd5JointMat>;
var
  LOffset: TArray<TMd5JointMat>;
begin
  LOffset := FModel.Skeleton.ConvertToMatrices(AFrame);
  LOffset[0].SetTranslation(LOffset[0].ToVec3 + FModelDefIntf.Offset);
  FModel.Skeleton.TransformJoints(LOffset, 1, High(LOffset));
  Result := LOffset;
end;

end.
