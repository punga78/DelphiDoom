{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III host library - a renderer that only records            }
{                                                                              }
{  Stands in for the renderer (re.* of cl_cgame.c and cl_ui.c) until the real   }
{  one exists: it counts and logs the calls, hands out sequential handles       }
{  and draws nothing. Based on the Quake III Arena GPL Source Code (id          }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived    }
{  from the Quake III Arena source code and is therefore available under the    }
{  GNU General Public License, version 2 or (at your option) any later          }
{  version.                                                                     }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Host.ClientRecordingRenderer;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Qvm.Intf, DelphiDoom.Q3Host.Client.Types,
  DelphiDoom.Q3Host.Client.Intf;

type
  /// <summary>
  ///   IQ3HostRenderer without a screen. Models, skins, shaders and fonts get the numbers 1, 2, 3 ... in the order
  ///   they are first registered (the same name gives the same number, ignoring case; 0 is the default shader, as in
  ///   the renderer). Every call is counted by name and the first MaxLoggedCalls are kept as text. The answers that
  ///   have no data behind them are the neutral ones: no tag, no decal fragments, no light grid, every point in the
  ///   PVS, model bounds of a cube of 16 units, and a 640 x 480 window of 32 bit colors in the glconfig
  /// </summary>
  TQ3RecordingRenderer = class(TInterfacedObject, IQ3HostRenderer)
  strict private
    FHandles: array[0..3] of TDictionary<string, Integer>;
    FCounts: TDictionary<string, Integer>;
    FLog: TStringList;
    FMaxLoggedCalls: Integer;
    FSceneRefEntities: Integer;
    procedure Note(const AName: string; const ADetail: string = '');
    function HandleOf(AKind: Integer; const AName: AnsiString; const ACall: string): Integer;
    function Float(AValue: Single): string;
  public
    const
      KIND_MODEL = 0;
      KIND_SKIN = 1;
      KIND_SHADER = 2;
      KIND_FONT = 3;
    constructor Create(AMaxLoggedCalls: Integer = 4096);
    destructor Destroy; override;
    procedure LoadWorld(const AName: AnsiString);
    function RegisterModel(const AName: AnsiString): Integer;
    function RegisterSkin(const AName: AnsiString): Integer;
    function RegisterShader(const AName: AnsiString): Integer;
    function RegisterShaderNoMip(const AName: AnsiString): Integer;
    procedure RegisterFont(const AMemory: IQvmMemory; const AName: AnsiString; APointSize, AFontAddress: Integer);
    procedure ClearScene;
    procedure AddRefEntityToScene(const AMemory: IQvmMemory; AAddress: Integer);
    procedure AddPolyToScene(const AMemory: IQvmMemory; AShader, ANumVerts, AVertsAddress, ANumPolys: Integer);
    procedure AddLightToScene(const AOrigin: TQ3HostVec3; AIntensity, ARed, AGreen, ABlue: Single;
      AAdditive: Boolean);
    procedure RenderScene(const AMemory: IQvmMemory; AAddress: Integer);
    procedure SetColor(const AMemory: IQvmMemory; AAddress: Integer);
    procedure DrawStretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single; AShader: Integer);
    procedure ModelBounds(const AMemory: IQvmMemory; AModel, AMinsAddress, AMaxsAddress: Integer);
    function LerpTag(const AMemory: IQvmMemory; ATagAddress, AModel, AStartFrame, AEndFrame: Integer;
      AFraction: Single; const ATagName: AnsiString): Integer;
    function InPVS(const APoint1, APoint2: TQ3HostVec3): Integer;
    function LightForPoint(const AMemory: IQvmMemory; const APoint: TQ3HostVec3;
      AAmbientAddress, ADirectedAddress, ALightDirAddress: Integer): Integer;
    procedure RemapShader(const AOldShader, ANewShader, ATimeOffset: AnsiString);
    function MarkFragments(const AMemory: IQvmMemory; ANumPoints, APointsAddress, AProjectionAddress,
      AMaxPoints, APointBufferAddress, AMaxFragments, AFragmentBufferAddress: Integer): Integer;
    function GlConfig: TBytes;
    /// <summary>How many times a call was made (RegisterShader, RenderScene ...)</summary>
    function CallCount(const AName: string): Integer;
    /// <summary>The number of all the calls</summary>
    function TotalCalls: Integer;
    /// <summary>The names registered of a kind, in the order of their numbers (the first has number 1)</summary>
    function RegisteredNames(AKind: Integer): TArray<string>;
    /// <summary>The first calls, one per line: "name detail"</summary>
    property Log: TStringList read FLog;
  end;

implementation

uses
  DelphiDoom.Q3Host.Arguments;

constructor TQ3RecordingRenderer.Create(AMaxLoggedCalls: Integer);
var
  LKind: Integer;
begin
  inherited Create;
  for LKind := 0 to 3 do
    FHandles[LKind] := TDictionary<string, Integer>.Create;
  FCounts := TDictionary<string, Integer>.Create;
  FLog := TStringList.Create;
  FMaxLoggedCalls := AMaxLoggedCalls;
end;

destructor TQ3RecordingRenderer.Destroy;
var
  LKind: Integer;
begin
  for LKind := 0 to 3 do
    FHandles[LKind].Free;
  FCounts.Free;
  FLog.Free;
  inherited Destroy;
end;

function TQ3RecordingRenderer.Float(AValue: Single): string;
begin
  Result := FloatToStr(AValue, TFormatSettings.Invariant);
end;

procedure TQ3RecordingRenderer.Note(const AName: string; const ADetail: string);
var
  LCount: Integer;
begin
  FCounts.TryGetValue(AName, LCount);
  FCounts.AddOrSetValue(AName, LCount + 1);
  if FLog.Count < FMaxLoggedCalls then
    FLog.Add(Trim(AName + ' ' + ADetail));
end;

function TQ3RecordingRenderer.HandleOf(AKind: Integer; const AName: AnsiString; const ACall: string): Integer;
var
  LKey: string;
begin
  LKey := LowerCase(string(AName));
  Note(ACall, string(AName));
  if not FHandles[AKind].TryGetValue(LKey, Result) then
  begin
    Result := FHandles[AKind].Count + 1;
    FHandles[AKind].Add(LKey, Result);
  end;
end;

procedure TQ3RecordingRenderer.LoadWorld(const AName: AnsiString);
begin
  Note('LoadWorld', string(AName));
end;

function TQ3RecordingRenderer.RegisterModel(const AName: AnsiString): Integer;
begin
  Result := HandleOf(KIND_MODEL, AName, 'RegisterModel');
end;

function TQ3RecordingRenderer.RegisterSkin(const AName: AnsiString): Integer;
begin
  Result := HandleOf(KIND_SKIN, AName, 'RegisterSkin');
end;

function TQ3RecordingRenderer.RegisterShader(const AName: AnsiString): Integer;
begin
  Result := HandleOf(KIND_SHADER, AName, 'RegisterShader');
end;

function TQ3RecordingRenderer.RegisterShaderNoMip(const AName: AnsiString): Integer;
begin
  Result := HandleOf(KIND_SHADER, AName, 'RegisterShaderNoMip');
end;

procedure TQ3RecordingRenderer.RegisterFont(const AMemory: IQvmMemory; const AName: AnsiString; APointSize,
  AFontAddress: Integer);
begin
  HandleOf(KIND_FONT, AName, 'RegisterFont');
end;

procedure TQ3RecordingRenderer.ClearScene;
begin
  Note('ClearScene');
  FSceneRefEntities := 0;
end;

procedure TQ3RecordingRenderer.AddRefEntityToScene(const AMemory: IQvmMemory; AAddress: Integer);
begin
  Inc(FSceneRefEntities);
  Note('AddRefEntityToScene');
end;

procedure TQ3RecordingRenderer.AddPolyToScene(const AMemory: IQvmMemory; AShader, ANumVerts, AVertsAddress,
  ANumPolys: Integer);
begin
  Note('AddPolyToScene', Format('%d %d %d', [AShader, ANumVerts, ANumPolys]));
end;

procedure TQ3RecordingRenderer.AddLightToScene(const AOrigin: TQ3HostVec3; AIntensity, ARed, AGreen, ABlue: Single;
  AAdditive: Boolean);
begin
  if AAdditive then
    Note('AddAdditiveLightToScene', Float(AIntensity))
  else
    Note('AddLightToScene', Float(AIntensity));
end;

procedure TQ3RecordingRenderer.RenderScene(const AMemory: IQvmMemory; AAddress: Integer);
begin
  Note('RenderScene', IntToStr(FSceneRefEntities));
end;

procedure TQ3RecordingRenderer.SetColor(const AMemory: IQvmMemory; AAddress: Integer);
begin
  Note('SetColor');
end;

procedure TQ3RecordingRenderer.DrawStretchPic(AX, AY, AWidth, AHeight, AS1, AT1, AS2, AT2: Single;
  AShader: Integer);
begin
  Note('DrawStretchPic', Float(AX) + ' ' + Float(AY) + ' ' + Float(AWidth) + ' ' + Float(AHeight) + ' ' +
    IntToStr(AShader));
end;

procedure TQ3RecordingRenderer.ModelBounds(const AMemory: IQvmMemory; AModel, AMinsAddress, AMaxsAddress: Integer);
var
  LIndex: Integer;
begin
  Note('ModelBounds', IntToStr(AModel));
  for LIndex := 0 to 2 do
  begin
    AMemory.WriteInt32(AMinsAddress + 4 * LIndex, TQ3SyscallArguments.FromSingle(-8));
    AMemory.WriteInt32(AMaxsAddress + 4 * LIndex, TQ3SyscallArguments.FromSingle(8));
  end;
end;

function TQ3RecordingRenderer.LerpTag(const AMemory: IQvmMemory; ATagAddress, AModel, AStartFrame, AEndFrame: Integer;
  AFraction: Single; const ATagName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Note('LerpTag', string(ATagName));
  // R_LerpTag for a tag that is not there: the origin at zero and the axis clear (the identity)
  for LIndex := 0 to 11 do
    AMemory.WriteInt32(ATagAddress + 4 * LIndex, 0);
  AMemory.WriteInt32(ATagAddress + 12, TQ3SyscallArguments.FromSingle(1));
  AMemory.WriteInt32(ATagAddress + 28, TQ3SyscallArguments.FromSingle(1));
  AMemory.WriteInt32(ATagAddress + 44, TQ3SyscallArguments.FromSingle(1));
  Result := 0;
end;

function TQ3RecordingRenderer.InPVS(const APoint1, APoint2: TQ3HostVec3): Integer;
begin
  Note('InPVS');
  Result := 1;
end;

function TQ3RecordingRenderer.LightForPoint(const AMemory: IQvmMemory; const APoint: TQ3HostVec3;
  AAmbientAddress, ADirectedAddress, ALightDirAddress: Integer): Integer;
begin
  Note('LightForPoint');
  Result := 0;
end;

procedure TQ3RecordingRenderer.RemapShader(const AOldShader, ANewShader, ATimeOffset: AnsiString);
begin
  Note('RemapShader', string(AOldShader) + ' ' + string(ANewShader));
end;

function TQ3RecordingRenderer.MarkFragments(const AMemory: IQvmMemory; ANumPoints, APointsAddress,
  AProjectionAddress, AMaxPoints, APointBufferAddress, AMaxFragments, AFragmentBufferAddress: Integer): Integer;
begin
  Note('MarkFragments');
  Result := 0;
end;

function TQ3RecordingRenderer.GlConfig: TBytes;
  procedure PutText(AOffset: Integer; const AText: AnsiString);
  begin
    Move(AText[1], Result[AOffset], Length(AText));
  end;
  procedure PutInt(AOffset, AValue: Integer);
  begin
    PInteger(@Result[AOffset])^ := AValue;
  end;
begin
  SetLength(Result, Q3_GLCONFIG_SIZE);
  FillChar(Result[0], Q3_GLCONFIG_SIZE, 0);
  PutText(0, 'DelphiDoom recording renderer');
  PutText(1024, 'DelphiDoom');
  PutText(2048, '1.0');
  PutInt(11264, 2048); // maxTextureSize
  PutInt(11268, 2); // maxActiveTextures
  PutInt(11272, 32); // colorBits
  PutInt(11276, 24); // depthBits
  PutInt(11280, 8); // stencilBits
  PutInt(11300, 1); // textureEnvAddAvailable
  PutInt(11304, 640); // vidWidth
  PutInt(11308, 480); // vidHeight
  PutInt(11312, TQ3SyscallArguments.FromSingle(1.3333334)); // windowAspect
  PutInt(11316, 60); // displayFrequency
end;

function TQ3RecordingRenderer.CallCount(const AName: string): Integer;
begin
  if not FCounts.TryGetValue(AName, Result) then
    Result := 0;
end;

function TQ3RecordingRenderer.TotalCalls: Integer;
var
  LCount: Integer;
begin
  Result := 0;
  for LCount in FCounts.Values do
    Inc(Result, LCount);
end;

function TQ3RecordingRenderer.RegisteredNames(AKind: Integer): TArray<string>;
var
  LPair: TPair<string, Integer>;
begin
  SetLength(Result, FHandles[AKind].Count);
  for LPair in FHandles[AKind] do
    Result[LPair.Value - 1] := LPair.Key;
end;

end.
