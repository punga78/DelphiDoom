{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the voxel library - the scenarios of the new code      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Voxel.Subject;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>The function of TVoxelSamples that makes the file of an index</summary>
  TVoxelSampleFunction = function(const AIndex: Integer): TBytes;

  /// <summary>
  ///   What the classes of the library give for the files of TVoxelSamples, as a fingerprint:
  ///   each function has the key of the golden file that the old code produced. The harness that
  ///   compared old and new in the same program called the same functions.
  /// </summary>
  TVoxelSubject = class
  strict private
    class function Decode(const AFormat: IVoxelFormat; const ABytes: TBytes): IVoxelModel; static;
    class function CubeFingerprint(const AFormat: IVoxelFormat; const AFit: TVoxelCubeFit;
      const ACount: Integer; const AFile: TVoxelSampleFunction): string; static;
    class function GridFingerprint(const AFormat: IVoxelFormat; const ACount: Integer;
      const AFile: TVoxelSampleFunction): string; static;
    class function PatchFingerprint(const AFormat: IVoxelFormat; const ACount: Integer;
      const AFile: TVoxelSampleFunction): string; static;
  public
    class function DdvoxCubes: string; static;
    class function DdmeshCubes: string; static;
    class function DdmeshQuads: string; static;
    class function KvxCubesForRenderer: string; static;
    class function KvxCubesForSprite: string; static;
    class function KvxGrids: string; static;
    class function KvxExtremeCubesForRenderer: string; static;
    class function KvxExtremeGrids: string; static;
    class function Slab6Cubes: string; static;
    class function Rejects: string; static;
    class function DdvoxPatches: string; static;
    class function DdmeshPatches: string; static;
    class function KvxPatches: string; static;
    class function Slab6Patches: string; static;
    class function Definitions: string; static;
  end;

implementation

uses
  System.Classes,
  DelphiDoom.Voxel.Factory,
  DelphiDoom.Voxel.Format.Ddvox,
  DelphiDoom.Voxel.Format.Ddmesh,
  DelphiDoom.Voxel.Format.Kvx,
  DelphiDoom.Voxel.Format.Slab6,
  DelphiDoom.Tests.Voxel.Fingerprint,
  DelphiDoom.Tests.Voxel.Scenarios,
  DelphiDoom.Tests.Voxel.Samples,
  DelphiDoom.Tests.Voxel.Fakes;

{ TVoxelSubject }

class function TVoxelSubject.Decode(const AFormat: IVoxelFormat; const ABytes: TBytes): IVoxelModel;
begin
  Result := AFormat.Decode(ABytes);
end;

class function TVoxelSubject.CubeFingerprint(const AFormat: IVoxelFormat; const AFit: TVoxelCubeFit;
  const ACount: Integer; const AFile: TVoxelSampleFunction): string;
var
  LFingerprint: TFingerprint;
  LBuilder: IVoxelCubeBuilder;
  LCube: IVoxelCube;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    LBuilder := TVoxelFactory.CreateCubeBuilder;
    for LIndex := 0 to ACount - 1 do
    begin
      LCube := LBuilder.Build(Decode(AFormat, AFile(LIndex)), AFit);
      TVoxelScenarios.AddCube(LFingerprint, LCube.Size, LCube.Cells);
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

class function TVoxelSubject.GridFingerprint(const AFormat: IVoxelFormat; const ACount: Integer;
  const AFile: TVoxelSampleFunction): string;
var
  LFingerprint: TFingerprint;
  LModel: IVoxelModel;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to ACount - 1 do
    begin
      LModel := Decode(AFormat, AFile(LIndex));
      TVoxelScenarios.AddGrid(LFingerprint, LModel.SizeX, LModel.SizeY, LModel.SizeZ, LModel.PivotX,
        LModel.PivotY, LModel.PivotZ, LModel.Cells);
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

class function TVoxelSubject.PatchFingerprint(const AFormat: IVoxelFormat; const ACount: Integer;
  const AFile: TVoxelSampleFunction): string;
var
  LFingerprint: TFingerprint;
  LBuilder: IVoxelCubeBuilder;
  LPatches: IVoxelPatchBuilder;
  LIndex: Integer;
begin
  LFingerprint := TFingerprint.Create;
  try
    LBuilder := TVoxelFactory.CreateCubeBuilder;
    LPatches := TVoxelFactory.CreatePatchBuilder(TVoxelFakeMapper.Create);
    for LIndex := 0 to ACount - 1 do
      TVoxelScenarios.AddBytes(LFingerprint,
        LPatches.Build(LBuilder.Build(Decode(AFormat, AFile(LIndex)), cfSprite)));
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

class function TVoxelSubject.DdvoxCubes: string;
begin
  Result := CubeFingerprint(TVoxelDdvoxFormat.Create(TVoxelFakeLog.Create), cfRenderer,
    SAMPLE_DDVOX_COUNT, TVoxelSamples.Ddvox);
end;

class function TVoxelSubject.DdmeshCubes: string;
begin
  Result := CubeFingerprint(TVoxelDdmeshFormat.Create, cfRenderer, SAMPLE_DDMESH_COUNT,
    TVoxelSamples.Ddmesh);
end;

class function TVoxelSubject.DdmeshQuads: string;
var
  LFingerprint: TFingerprint;
  LModel: IVoxelModel;
  LQuads: TArray<TVoxelQuad>;
  LIndex, LQuad: Integer;
  LFormat: IVoxelFormat;
begin
  LFormat := TVoxelDdmeshFormat.Create;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to SAMPLE_DDMESH_COUNT - 1 do
    begin
      LModel := Decode(LFormat, TVoxelSamples.Ddmesh(LIndex));
      SetLength(LQuads, LModel.QuadCount);
      for LQuad := 0 to LModel.QuadCount - 1 do
        LQuads[LQuad] := LModel.Quad(LQuad);
      TVoxelScenarios.AddQuads(LFingerprint, LQuads);
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

class function TVoxelSubject.KvxCubesForRenderer: string;
begin
  Result := CubeFingerprint(TVoxelKvxFormat.Create, cfRenderer, SAMPLE_KVX_COUNT, TVoxelSamples.Kvx);
end;

class function TVoxelSubject.KvxCubesForSprite: string;
begin
  Result := CubeFingerprint(TVoxelKvxFormat.Create, cfSprite, SAMPLE_KVX_COUNT, TVoxelSamples.Kvx);
end;

class function TVoxelSubject.KvxGrids: string;
begin
  Result := GridFingerprint(TVoxelKvxFormat.Create, SAMPLE_KVX_COUNT, TVoxelSamples.Kvx);
end;

class function TVoxelSubject.KvxExtremeCubesForRenderer: string;
begin
  Result := CubeFingerprint(TVoxelKvxFormat.Create, cfRenderer, SAMPLE_KVX_EXTREME_COUNT,
    TVoxelSamples.KvxExtreme);
end;

class function TVoxelSubject.KvxExtremeGrids: string;
begin
  Result := GridFingerprint(TVoxelKvxFormat.Create, SAMPLE_KVX_EXTREME_COUNT, TVoxelSamples.KvxExtreme);
end;

class function TVoxelSubject.Slab6Cubes: string;
begin
  Result := CubeFingerprint(TVoxelSlab6Format.Create, cfRenderer, SAMPLE_SLAB6_COUNT, TVoxelSamples.Slab6);
end;

class function TVoxelSubject.Rejects: string;
var
  LFingerprint: TFingerprint;
  LFormats: array[0..5] of IVoxelFormat;
  LBytes: TArray<TBytes>;
  LIndex: Integer;
begin
  LFormats[0] := TVoxelKvxFormat.Create;
  LFormats[1] := TVoxelSlab6Format.Create;
  LFormats[2] := TVoxelSlab6Format.Create;
  LFormats[3] := TVoxelSlab6Format.Create;
  LFormats[4] := TVoxelDdmeshFormat.Create;
  LFormats[5] := TVoxelDdmeshFormat.Create;
  LBytes := TVoxelSamples.Rejects;
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to High(LBytes) do
      try
        LFormats[LIndex].Decode(LBytes[LIndex]);
        LFingerprint.AddBoolean(True);
      except
        on EVoxelException do
          LFingerprint.AddBoolean(False);
      end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

class function TVoxelSubject.DdvoxPatches: string;
begin
  Result := PatchFingerprint(TVoxelDdvoxFormat.Create(TVoxelFakeLog.Create), SAMPLE_DDVOX_COUNT,
    TVoxelSamples.Ddvox);
end;

class function TVoxelSubject.DdmeshPatches: string;
begin
  Result := PatchFingerprint(TVoxelDdmeshFormat.Create, SAMPLE_DDMESH_COUNT, TVoxelSamples.Ddmesh);
end;

class function TVoxelSubject.KvxPatches: string;
begin
  Result := PatchFingerprint(TVoxelKvxFormat.Create, SAMPLE_KVX_COUNT, TVoxelSamples.Kvx);
end;

class function TVoxelSubject.Slab6Patches: string;
begin
  Result := PatchFingerprint(TVoxelSlab6Format.Create, SAMPLE_SLAB6_COUNT, TVoxelSamples.Slab6);
end;

class function TVoxelSubject.Definitions: string;
var
  LFingerprint: TFingerprint;
  LLog: TVoxelFakeLog;
  LLogIntf: ILog;
  LSink: TVoxelFakeSink;
  LSinkIntf: IVoxelDefinitionSink;
  LParser: IVoxelDefinitionParser;
  LIndex: Integer;
begin
  Result := '';
  LFingerprint := TFingerprint.Create;
  try
    for LIndex := 0 to SAMPLE_DEFINITION_COUNT - 1 do
    begin
      LLog := TVoxelFakeLog.Create;
      LLogIntf := LLog;
      LSink := TVoxelFakeSink.Create;
      LSinkIntf := LSink;
      LParser := TVoxelFactory.CreateDefinitionParser(TVoxelFakeLookup.Create, LLog);
      LParser.Parse(TVoxelSamples.Definition(LIndex), LSink);
      TVoxelScenarios.AddLines(LFingerprint, LSink.Lines);
      TVoxelScenarios.AddLines(LFingerprint, LLog.Warnings);
    end;
    Result := LFingerprint.ToHex;
  finally
    LFingerprint.Free;
  end;
end;

end.
