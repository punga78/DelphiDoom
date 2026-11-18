{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III renderer without OpenGL (phase R0) - model table      }
{                                                                              }
{  RE_RegisterModel, R_LoadMD3, R_ModelBounds and R_LerpTag of renderer\       }
{  tr_model.c as data. Based on the Quake III Arena GPL Source Code (id        }
{  Software). Copyright (C) 1999-2005 Id Software, Inc. This unit is derived   }
{  from the Quake III Arena source code and is therefore available under the   }
{  GNU General Public License, version 2 or (at your option) any later         }
{  version.                                                                    }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Q3Render.Model.Registry;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.Models.Static.Md3.Intf,
  DelphiDoom.Models.Q3Player.Intf, DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Intf;

type
  /// <summary>
  ///   The models a game asks for. A name "*N" is the brush model N of the world; anything else is an md3 read through
  ///   IQ3RenderFiles with its lower levels of detail (name_1.md3, name_2.md3) as RE_RegisterModel does, and the
  ///   shaders its surfaces name are registered, as R_LoadMD3 does with R_FindShader. A model that cannot be read is
  ///   remembered as missing (the C keeps a MOD_BAD entry for the same reason)
  /// </summary>
  /// <remarks>
  ///   Not ported: MD4 (".md4" skeletal models: no file of OpenArena has one), the check of the md3 offsets and
  ///   byte swapping (the reader checks the offsets and raises), and the order of the shader indexes. Models of
  ///   one handle: lod 0 only is kept (the other levels are read to register their shaders)
  /// </remarks>
  TQ3ModelRegistry = class(TInterfacedObject, IQ3ModelRegistry)
  strict private
    type
      TEntry = record
        Model: IMd3Model;
        BrushIndex: Integer;
      end;
  strict private
    FFiles: IQ3RenderFiles;
    FReader: IMd3Reader;
    FShaders: IQ3ShaderRegistry;
    FTags: IQ3TagLerper;
    FLog: ILog;
    FWorld: IQ3RenderWorld;
    FHandles: TDictionary<string, Integer>;
    FEntries: TList<TEntry>;
    FMissing: TList<string>;
    function LoadFile(const AFileName, AName: AnsiString; out AModel: IMd3Model): Boolean;
  public
    constructor Create(const AFiles: IQ3RenderFiles; const AReader: IMd3Reader; const AShaders: IQ3ShaderRegistry;
      const ATags: IQ3TagLerper; const ALog: ILog = nil);
    destructor Destroy; override;
    function Register(const AName: AnsiString): Integer;
    procedure SetWorld(const AWorld: IQ3RenderWorld);
    function GetModel(AHandle: Integer): IMd3Model;
    function LoadedCount: Integer;
    function MissingNames: TArray<string>;
    function ModelBounds(AHandle: Integer; out AMins, AMaxs: TQ3RenderVec3): Boolean;
    function LerpTag(AHandle, AStartFrame, AEndFrame: Integer; AFraction: Single; const ATagName: AnsiString;
      out AOrigin: TQ3RenderVec3; out AAxis: TQ3RenderAxis): Boolean;
  end;

implementation

uses
  DelphiDoom.Models.Static.Md3.Types, DelphiDoom.Models.Q3Player.Types;

constructor TQ3ModelRegistry.Create(const AFiles: IQ3RenderFiles; const AReader: IMd3Reader;
  const AShaders: IQ3ShaderRegistry; const ATags: IQ3TagLerper; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(AFiles) then
    raise EArgumentNilException.Create('AFiles');
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  if not Assigned(AShaders) then
    raise EArgumentNilException.Create('AShaders');
  if not Assigned(ATags) then
    raise EArgumentNilException.Create('ATags');
  FFiles := AFiles;
  FReader := AReader;
  FShaders := AShaders;
  FTags := ATags;
  FLog := ALog;
  FHandles := TDictionary<string, Integer>.Create;
  FEntries := TList<TEntry>.Create;
  FMissing := TList<string>.Create;
end;

destructor TQ3ModelRegistry.Destroy;
begin
  FHandles.Free;
  FEntries.Free;
  FMissing.Free;
  inherited Destroy;
end;

procedure TQ3ModelRegistry.SetWorld(const AWorld: IQ3RenderWorld);
begin
  FWorld := AWorld;
end;

function TQ3ModelRegistry.LoadFile(const AFileName, AName: AnsiString; out AModel: IMd3Model): Boolean;
var
  LData: TBytes;
  LSurface, LShader: Integer;
begin
  AModel := nil;
  Result := False;
  if not FFiles.ReadFile(AFileName, LData) then
    Exit;
  try
    AModel := FReader.Read(LData, string(AName));
  except
    on E: Exception do
    begin
      // RE_RegisterModel warns and goes on to fail the model
      if Assigned(FLog) then
        FLog.Warning(Format('RE_RegisterModel: %s: %s', [string(AName), E.Message]));
      Exit;
    end;
  end;
  for LSurface := 0 to AModel.NumSurfaces - 1 do
    for LShader := 0 to Length(AModel.Surfaces[LSurface].Shaders) - 1 do
      if AModel.Surfaces[LSurface].Shaders[LShader] <> '' then
        FShaders.Register(AModel.Surfaces[LSurface].Shaders[LShader]);
  Result := True;
end;

function TQ3ModelRegistry.Register(const AName: AnsiString): Integer;
var
  LKey: string;
  LEntry: TEntry;
  LModel: IMd3Model;
  LIndex, LLod, LBrush: Integer;
  LFileName: AnsiString;
  LDot: Integer;
begin
  Result := 0;
  if (AName = '') or (Length(AName) >= Q3_RENDER_MAX_QPATH) then
    Exit;
  LKey := string(AName);
  if FHandles.TryGetValue(LKey, Result) then
    Exit;
  LEntry := Default(TEntry);
  LEntry.BrushIndex := -1;
  // a brush model of the world: "*1", "*2" ...
  if AName[1] = '*' then
  begin
    LBrush := StrToIntDef(string(Copy(AName, 2, MaxInt)), -1);
    if Assigned(FWorld) and (LBrush >= 0) and (LBrush < FWorld.SubmodelCount) then
    begin
      LEntry.BrushIndex := LBrush;
      FEntries.Add(LEntry);
      Result := FEntries.Count;
      FHandles.Add(LKey, Result);
      Exit;
    end;
    FHandles.Add(LKey, 0);
    FMissing.Add(LKey);
    Exit;
  end;
  // lod 0 decides, the lower levels of detail only add their shaders
  for LLod := Q3_RENDER_MD3_MAX_LODS - 1 downto 0 do
  begin
    LFileName := AName;
    if LLod <> 0 then
    begin
      LDot := LastDelimiter('.', LKey);
      if LDot > 0 then
        LFileName := Copy(AName, 1, LDot - 1);
      LFileName := LFileName + AnsiString(Format('_%d.md3', [LLod]));
    end;
    if LLod = 0 then
    begin
      if LoadFile(LFileName, AName, LModel) then
        LEntry.Model := LModel;
    end
    else
      LoadFile(LFileName, AName, LModel);
  end;
  LIndex := 0;
  if not Assigned(LEntry.Model) then
  begin
    FHandles.Add(LKey, LIndex);
    FMissing.Add(LKey);
    Exit;
  end;
  FEntries.Add(LEntry);
  Result := FEntries.Count;
  FHandles.Add(LKey, Result);
end;

function TQ3ModelRegistry.GetModel(AHandle: Integer): IMd3Model;
begin
  if (AHandle >= 1) and (AHandle <= FEntries.Count) then
    Result := FEntries[AHandle - 1].Model
  else
    Result := nil;
end;

function TQ3ModelRegistry.LoadedCount: Integer;
begin
  Result := FEntries.Count;
end;

function TQ3ModelRegistry.MissingNames: TArray<string>;
begin
  Result := FMissing.ToArray;
end;

function TQ3ModelRegistry.ModelBounds(AHandle: Integer; out AMins, AMaxs: TQ3RenderVec3): Boolean;
var
  LEntry: TEntry;
  LFrame: TMd3Frame;
begin
  AMins := Default(TQ3RenderVec3);
  AMaxs := Default(TQ3RenderVec3);
  Result := False;
  if (AHandle < 1) or (AHandle > FEntries.Count) then
    Exit;
  LEntry := FEntries[AHandle - 1];
  if LEntry.BrushIndex >= 0 then
    Exit(Assigned(FWorld) and FWorld.SubmodelBounds(LEntry.BrushIndex, AMins, AMaxs));
  if not Assigned(LEntry.Model) or (LEntry.Model.NumFrames < 1) then
    Exit;
  // R_ModelBounds of a mesh: the bounds of the first frame
  LFrame := LEntry.Model.Frames[0];
  AMins[0] := LFrame.BoundsMin.X;
  AMins[1] := LFrame.BoundsMin.Y;
  AMins[2] := LFrame.BoundsMin.Z;
  AMaxs[0] := LFrame.BoundsMax.X;
  AMaxs[1] := LFrame.BoundsMax.Y;
  AMaxs[2] := LFrame.BoundsMax.Z;
  Result := True;
end;

function TQ3ModelRegistry.LerpTag(AHandle, AStartFrame, AEndFrame: Integer; AFraction: Single;
  const ATagName: AnsiString; out AOrigin: TQ3RenderVec3; out AAxis: TQ3RenderAxis): Boolean;
var
  LOrientation: TQ3Orientation;
  LAxis, LComponent: Integer;
begin
  AOrigin := Default(TQ3RenderVec3);
  AAxis := Default(TQ3RenderAxis);
  Result := False;
  if (AHandle < 1) or (AHandle > FEntries.Count) or not Assigned(FEntries[AHandle - 1].Model) then
    Exit;
  Result := FTags.LerpTag(FEntries[AHandle - 1].Model, AStartFrame, AEndFrame, AFraction, ATagName, LOrientation);
  AOrigin[0] := LOrientation.Origin.X;
  AOrigin[1] := LOrientation.Origin.Y;
  AOrigin[2] := LOrientation.Origin.Z;
  for LAxis := 0 to 2 do
    for LComponent := 0 to 2 do
      AAxis[LAxis][LComponent] := LOrientation.Axis[LAxis][LComponent];
end;

end.
