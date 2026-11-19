{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III renderer library (phase R1) - the front  }
{  end against the real C                                                      }
{                                                                              }
{  Tests\Data\Q3Render\front.golden.txt is the output of the REAL tr_main.c     }
{  and tr_world.c of Quake III (Tools\Verifica\254\build-front.sh, gcc, 32     }
{  bit SSE) on maps/oa_dm1.bsp of OpenArena 0.8.8 for the views of              }
{  front.views.txt: the frustum, the projection, the bounds of what is         }
{  visible and the sorted list of drawSurfs (sort key and surface). The test   }
{  runs the same views through TQ3FrontEnd with a shader table that makes the  }
{  same made up culling and sort positions as frontgen.c. Ignored when         }
{  OpenArena is not there                                                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Render.Front;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('Q3Render')]
  [Category('OpenArena')]
  TTestQ3Front = class
  public
    [Test]
    procedure DovrebbeDareLeStesseVisteSuperficiEOrdineDelCDiQuake;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Wad.Fs.Intf,
  DelphiDoom.Collision.Q3.Types, DelphiDoom.Collision.Q3.Math, DelphiDoom.Decl.Q3Shader.Types,
  DelphiDoom.Q3Render.Types, DelphiDoom.Q3Render.Scene.Types, DelphiDoom.Q3Render.Intf,
  DelphiDoom.Q3Render.Factory, DelphiDoom.Q3Render.Scene.FrontEnd, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Golden, DelphiDoom.Tests.Q3Render.Support;

type
  /// <summary>
  ///   The shaders of frontgen.c: shader k of the file has cullType k mod 3, sort SS_OPAQUE and the sorted index
  ///   (k * 3) mod 8 + 1; a name is the first shader of the file that has it. The table index is k + 1
  /// </summary>
  TFrontFakeShaders = class(TInterfacedObject, IQ3ShaderTable)
  strict private
    FNames: TArray<AnsiString>;
    FLightmaps: Integer;
  public
    constructor Create(const ANames: TArray<AnsiString>);
    function FindShader(const AName: AnsiString; ALightmapIndex: Integer): Integer;
    function GetEntry(AIndex: Integer): TQ3ShaderEntry;
    function SortedIndexOf(AIndex: Integer): Integer;
    function GetSortedEntry(ASortedIndex: Integer): TQ3ShaderEntry;
    function GetSortedShader(ASortedIndex: Integer): Integer;
    function Count: Integer;
    procedure SetLightmapCount(ACount: Integer);
    function GetLightmapCount: Integer;
  end;

constructor TFrontFakeShaders.Create(const ANames: TArray<AnsiString>);
begin
  inherited Create;
  FNames := ANames;
end;

function TFrontFakeShaders.FindShader(const AName: AnsiString; ALightmapIndex: Integer): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(FNames) do
    if FNames[LIndex] = AName then
      Exit(LIndex + 1);
  Result := 0;
end;

function TFrontFakeShaders.GetEntry(AIndex: Integer): TQ3ShaderEntry;
begin
  Result := Default(TQ3ShaderEntry);
  Result.Data.Sort := SS_OPAQUE;
  if AIndex >= 1 then
  begin
    Result.Data.CullType := TQ3CullType((AIndex - 1) mod 3);
    Result.SortedIndex := ((AIndex - 1) * 3) mod 8 + 1;
  end;
end;

function TFrontFakeShaders.SortedIndexOf(AIndex: Integer): Integer;
begin
  Result := GetEntry(AIndex).SortedIndex;
end;

function TFrontFakeShaders.GetSortedEntry(ASortedIndex: Integer): TQ3ShaderEntry;
begin
  Result := GetEntry(0);
end;

function TFrontFakeShaders.GetSortedShader(ASortedIndex: Integer): Integer;
begin
  Result := 0;
end;

function TFrontFakeShaders.Count: Integer;
begin
  Result := Length(FNames) + 1;
end;

procedure TFrontFakeShaders.SetLightmapCount(ACount: Integer);
begin
  FLightmaps := ACount;
end;

function TFrontFakeShaders.GetLightmapCount: Integer;
begin
  Result := FLightmaps;
end;

function Bits(const AValue: Single): string;
var
  LCopy: Single;
begin
  LCopy := AValue;
  Result := LowerCase(IntToHex(PCardinal(@LCopy)^, 8));
end;

function Numbers(const AValues: array of Single): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to High(AValues) do
    Result := Result + ' ' + Bits(AValues[LIndex]);
end;

procedure RunView(const AFront: TQ3FrontEnd; const ALine: string; ANumber: Integer; ALines: TStrings);
var
  LWords: TArray<string>;
  LIndex, LSurface: Integer;
  LAngles: TQ3Vec3;
  LRefDef: TQ3RefDef;
  LResult: TQ3ViewResult;
  LOrigin: TQ3Vec3;
  LDrawSurf: TQ3DrawSurf;
  LInvariant: TFormatSettings;
begin
  LInvariant := TFormatSettings.Invariant;
  LWords := ALine.Split([' ']);
  LRefDef := Default(TQ3RefDef);
  LRefDef.Width := 640;
  LRefDef.Height := 480;
  LRefDef.ViewOrigin[0] := StrToFloat(LWords[1], LInvariant);
  LRefDef.ViewOrigin[1] := StrToFloat(LWords[2], LInvariant);
  LRefDef.ViewOrigin[2] := StrToFloat(LWords[3], LInvariant);
  // angles are pitch, yaw, roll
  LAngles[0] := StrToFloat(LWords[5], LInvariant);
  LAngles[1] := StrToFloat(LWords[4], LInvariant);
  LAngles[2] := StrToFloat(LWords[6], LInvariant);
  LRefDef.FovX := StrToFloat(LWords[7], LInvariant);
  LRefDef.FovY := StrToFloat(LWords[8], LInvariant);
  TQ3Math.AngleVectors(LAngles, LRefDef.ViewAxis[0], LRefDef.ViewAxis[1], LRefDef.ViewAxis[2]);
  AFront.ClearScene;
  LIndex := 9;
  while LIndex + 4 <= High(LWords) do
  begin
    if LWords[LIndex] = 'dlight' then
    begin
      LOrigin[0] := StrToFloat(LWords[LIndex + 1], LInvariant);
      LOrigin[1] := StrToFloat(LWords[LIndex + 2], LInvariant);
      LOrigin[2] := StrToFloat(LWords[LIndex + 3], LInvariant);
      AFront.AddLight(LOrigin, StrToFloat(LWords[LIndex + 4], LInvariant), 1, 1, 1, False);
    end;
    Inc(LIndex, 5);
  end;
  AFront.RenderScene(LRefDef);
  LResult := AFront.LastResult;
  ALines.Add(Format('view %d axis', [ANumber]) + Numbers([LRefDef.ViewAxis[0][0], LRefDef.ViewAxis[0][1],
    LRefDef.ViewAxis[0][2], LRefDef.ViewAxis[1][0], LRefDef.ViewAxis[1][1], LRefDef.ViewAxis[1][2],
    LRefDef.ViewAxis[2][0], LRefDef.ViewAxis[2][1], LRefDef.ViewAxis[2][2]]));
  for LIndex := 0 to 3 do
    ALines.Add(Format('frustum %d', [LIndex]) + Numbers([LResult.View.Frustum[LIndex].Normal[0],
      LResult.View.Frustum[LIndex].Normal[1], LResult.View.Frustum[LIndex].Normal[2],
      LResult.View.Frustum[LIndex].Dist]));
  ALines.Add('proj' + Numbers(LResult.View.ProjectionMatrix));
  ALines.Add('zfar' + Numbers([LResult.View.ZFar]));
  ALines.Add('visbounds' + Numbers([LResult.View.VisBounds[0][0], LResult.View.VisBounds[0][1],
    LResult.View.VisBounds[0][2], LResult.View.VisBounds[1][0], LResult.View.VisBounds[1][1],
    LResult.View.VisBounds[1][2]]));
  ALines.Add(Format('count %d', [LResult.NumDrawSurfs]));
  for LSurface := LResult.FirstDrawSurf to LResult.FirstDrawSurf + LResult.NumDrawSurfs - 1 do
  begin
    LDrawSurf := AFront.DrawList.Item(LSurface);
    ALines.Add(Format('d %s %d', [LowerCase(IntToHex(LDrawSurf.Sort, 8)), LDrawSurf.Surface.Index]));
  end;
  AFront.EndFrame;
end;

procedure TTestQ3Front.DovrebbeDareLeStesseVisteSuperficiEOrdineDelCDiQuake;
var
  LFolder, LGoldenFile, LViewsFile: string;
  LFiles: IGameFileSystem;
  LSystem: IQ3RenderSystem;
  LWorld: IQ3RenderWorld;
  LFront: TQ3FrontEnd;
  LViews, LActual, LGolden: TStringList;
  LLine: string;
  LNumber: Integer;
  LIdentity: TQ3HandleMapper;
begin
  LFolder := TTestSupport.OpenArenaFolder;
  LViewsFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\front.views.txt');
  LGoldenFile := TTestFiles.FindFileUp('Tests\Data\Q3Render\front.golden.txt');
  Assert.IsTrue((LViewsFile <> '') and (LGoldenFile <> ''), 'front.views.txt and front.golden.txt must be there');
  LFiles := TTestSupport.OpenArenaFiles(LFolder, 'baseoa');
  LViews := TStringList.Create;
  LActual := TStringList.Create;
  try
    LSystem := TQ3RenderFactory.CreateSystem(LFiles);
    LWorld := LSystem.WorldLoader.Load('maps/oa_dm1.bsp');
    Assert.IsTrue(Assigned(LWorld), 'oa_dm1 must load');
    LIdentity :=
      function(AHandle: Integer): Integer
      begin
        Result := AHandle;
      end;
    LFront := TQ3FrontEnd.Create(TFrontFakeShaders.Create(LWorld.ShaderNames) as IQ3ShaderTable, LSystem.Models,
      LIdentity, LIdentity, TQ3RenderSettings.Defaults);
    try
      LFront.SetWorld(LWorld);
      LViews.LoadFromFile(LViewsFile);
      LNumber := 0;
      for LLine in LViews do
        if (LLine <> '') and (LLine[1] <> '#') then
        begin
          RunView(LFront, LLine, LNumber, LActual);
          Inc(LNumber);
        end;
    finally
      LFront.Free;
    end;
    if GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_FRONT_OUT') <> '' then
      LActual.SaveToFile(GetEnvironmentVariable('DELPHIDOOM_Q3RENDER_FRONT_OUT'));
    LGolden := TTestFiles.Lines(LGoldenFile);
    try
      TTestGolden.AssertSameLines(LGolden, LActual);
    finally
      LGolden.Free;
    end;
  finally
    LViews.Free;
    LActual.Free;
    LFiles.Shutdown;
  end;
end;

end.
