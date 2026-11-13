{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III shader time functions - support          }
{                                                                              }
{  The interpreters of the scenarios of Tools\Verifica\119 (q3calc.c and the   }
{  remap commands of q3shader.c): the same commands and the same lines as the  }
{  C drivers, with the classes of Libs\Decl, and a shader catalog in memory    }
{  that behaves as the table of shaders of tr_shader.c.                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.Q3ShaderCalcSupport;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Calc.Types, DelphiDoom.Decl.Q3Shader.Calc.Intf,
  DelphiDoom.Decl.Q3Shader.Calc.Kit;

type
  TFakeShaderEntry = record
    Name: AnsiString;
    Lightmap: Integer;
    Failed: Boolean;
  end;

  /// <summary>
  ///   The shaders of the renderer as <c>tr_shader.c</c> keeps them: the default shader (0) and the stencil
  ///   shadow (1) come first, a name that begins with "nofile" has no image (a failed shader that matches any
  ///   lightmap), a lightmap index above the lightmaps of the map (there are none) is the vertex lighting (-3)
  /// </summary>
  TFakeShaderCatalog = class(TInterfacedObject, IQ3ShaderCatalog)
  strict private
    FEntries: TList<TFakeShaderEntry>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>R_FindShader( name, lightmapIndex ) as RE_RegisterShaderLightMap: the handle, 0 if it failed</summary>
    function Register(const AName: AnsiString; const ALightmap: Integer): Integer;
    function FindShaderByName(const AName: AnsiString): Integer;
    function RegisterShader(const AName: AnsiString): Integer;
    function ShadersNamed(const AStrippedName: AnsiString): TArray<Integer>;
    property Entries: TList<TFakeShaderEntry> read FEntries;
  end;

  /// <summary>q3calc.c: the shader time functions on the buffers of <c>tess</c></summary>
  TQ3CalcGoldenRunner = class
  strict private
    FKit: TQ3ShaderCalc;
    FOutput: TStringList;
    FTess: TQ3ShaderTess;
    FIdentityLight: Single;
    FBundle: TQ3TextureBundle;
    FSeed: Cardinal;
    function NextRandom: Integer;
    procedure GenerateVertexes(const ACount: Integer; const ASeed: Cardinal);
    class function Bits(const AValue: Single): string; static;
    class function Number(const AText: string): Single; static;
    class function Wave(const ATokens: TArray<string>; const AStart: Integer): TQ3WaveForm; static;
    procedure DumpPositions;
    procedure DumpColors(const AColors: TBytes; const ABytes: Integer);
    procedure DumpTexCoords(const ATexCoords: TArray<Single>);
    procedure Command(const ALine: string);
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Runs the scenario and returns the lines</summary>
    function Run(const AScenario: TStrings): TStringList;
  end;

  /// <summary>The remap commands of q3shader.c (internal, scan, reg, remap, remapdump)</summary>
  TQ3RemapGoldenRunner = class
  strict private
    FOutput: TStringList;
    FCatalog: TFakeShaderCatalog;
    FCatalogIntf: IQ3ShaderCatalog;
    class function Bits(const AValue: Single): string; static;
  public
    constructor Create;
    destructor Destroy; override;
    function Run(const AScenario: TStrings): TStringList;
  end;

implementation

uses
  System.Math, DelphiDoom.Decl.Q3Shader.Calc.Remapper, DelphiDoom.Decl.Q3Shader.Calc.ColorCalc;

type
  /// <summary>ri.Printf(PRINT_WARNING): the line goes to the output as the C driver prints it</summary>
  TOutputLog = class(TInterfacedObject, IIdLibLog)
  strict private
    FOutput: TStrings;
  public
    constructor Create(const AOutput: TStrings);
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

function Strip(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  LIndex := Pos(AnsiString('.'), AName);
  if LIndex = 0 then
    Result := AName
  else
    Result := Copy(AName, 1, LIndex - 1);
end;

function SplitLine(const ALine: string): TArray<string>;
var
  LList: TStringList;
begin
  LList := TStringList.Create;
  try
    LList.Delimiter := ' ';
    LList.StrictDelimiter := True;
    LList.DelimitedText := Trim(ALine);
    Result := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

{ TOutputLog }

constructor TOutputLog.Create(const AOutput: TStrings);
begin
  inherited Create;
  FOutput := AOutput;
end;

procedure TOutputLog.Printf(const AMessage: string);
begin
end;

procedure TOutputLog.Warning(const AMessage: string);
begin
  FOutput.Add('log ' + AMessage);
end;

{ TFakeShaderCatalog }

constructor TFakeShaderCatalog.Create;
var
  LEntry: TFakeShaderEntry;
begin
  inherited Create;
  FEntries := TList<TFakeShaderEntry>.Create;
  LEntry.Name := '<default>';
  LEntry.Lightmap := -1;
  LEntry.Failed := False;
  FEntries.Add(LEntry);
  LEntry.Name := '<stencil shadow>';
  FEntries.Add(LEntry);
end;

destructor TFakeShaderCatalog.Destroy;
begin
  FEntries.Free;
  inherited Destroy;
end;

function TFakeShaderCatalog.Register(const AName: AnsiString; const ALightmap: Integer): Integer;
var
  LIndex, LLightmap: Integer;
  LEntry: TFakeShaderEntry;
  LStripped: AnsiString;
begin
  LStripped := Strip(AName);
  LLightmap := ALightmap;
  if LLightmap >= 0 then
    LLightmap := -3;
  for LIndex := FEntries.Count - 1 downto 0 do
  begin
    LEntry := FEntries[LIndex];
    if SameText(string(LEntry.Name), string(LStripped)) and ((LEntry.Lightmap = LLightmap) or LEntry.Failed) then
    begin
      if LEntry.Failed then
        Exit(0);
      Exit(LIndex);
    end;
  end;
  LEntry.Name := LStripped;
  LEntry.Lightmap := LLightmap;
  LEntry.Failed := Copy(string(LStripped), 1, 6) = 'nofile';
  FEntries.Add(LEntry);
  if LEntry.Failed then
    Result := 0
  else
    Result := FEntries.Count - 1;
end;

function TFakeShaderCatalog.FindShaderByName(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  if AName = '' then
    Exit(0);
  for LIndex := FEntries.Count - 1 downto 0 do
    if SameText(string(FEntries[LIndex].Name), string(Strip(AName))) then
      Exit(LIndex);
  Result := 0;
end;

function TFakeShaderCatalog.RegisterShader(const AName: AnsiString): Integer;
begin
  Result := Register(AName, 0);
end;

function TFakeShaderCatalog.ShadersNamed(const AStrippedName: AnsiString): TArray<Integer>;
var
  LIndex: Integer;
begin
  Result := nil;
  // the chain of the hash table: the newest first
  for LIndex := FEntries.Count - 1 downto 0 do
    if SameText(string(FEntries[LIndex].Name), string(AStrippedName)) then
      Result := Result + [LIndex];
end;

{ TQ3CalcGoldenRunner }

constructor TQ3CalcGoldenRunner.Create;
begin
  inherited Create;
  FKit := TQ3ShaderCalc.Create;
  FOutput := TStringList.Create;
  FIdentityLight := 1;
  FBundle.TcGen := tgTexture;
end;

destructor TQ3CalcGoldenRunner.Destroy;
begin
  FOutput.Free;
  FKit.Free;
  inherited Destroy;
end;

class function TQ3CalcGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := ' ' + LowerCase(IntToHex(PCardinal(@LValue)^, 8));
end;

class function TQ3CalcGoldenRunner.Number(const AText: string): Single;
var
  LValue: Double;
begin
  LValue := StrToFloat(AText, TFormatSettings.Invariant);
  Result := LValue;
end;

class function TQ3CalcGoldenRunner.Wave(const ATokens: TArray<string>; const AStart: Integer): TQ3WaveForm;
begin
  Result.Func := TQ3GenFunc(StrToInt(ATokens[AStart]));
  Result.Base := Number(ATokens[AStart + 1]);
  Result.Amplitude := Number(ATokens[AStart + 2]);
  Result.Phase := Number(ATokens[AStart + 3]);
  Result.Frequency := Number(ATokens[AStart + 4]);
end;

function TQ3CalcGoldenRunner.NextRandom: Integer;
begin
  FSeed := FSeed * 1103515245 + 12345;
  Result := Integer((FSeed shr 16) and $7FFF);
end;

procedure TQ3CalcGoldenRunner.GenerateVertexes(const ACount: Integer; const ASeed: Cardinal);
var
  LIndex, LAxis: Integer;
begin
  FSeed := ASeed;
  FTess.NumVertexes := ACount;
  SetLength(FTess.Xyz, ACount * 4);
  SetLength(FTess.Normal, ACount * 4);
  SetLength(FTess.TexCoords, ACount * 4);
  for LIndex := 0 to ACount - 1 do
  begin
    for LAxis := 0 to 2 do
      FTess.Xyz[LIndex * 4 + LAxis] := (NextRandom - 16384) / 256.0;
    FTess.Xyz[LIndex * 4 + 3] := 1.0;
    for LAxis := 0 to 2 do
      FTess.Normal[LIndex * 4 + LAxis] := (NextRandom - 16384) / 16384.0;
    FTess.Normal[LIndex * 4 + 3] := 0.0;
    for LAxis := 0 to 3 do
      FTess.TexCoords[LIndex * 4 + LAxis] := (NextRandom - 16384) / 8192.0;
  end;
end;

procedure TQ3CalcGoldenRunner.DumpPositions;
var
  LIndex, LAxis: Integer;
  LLine: string;
begin
  FOutput.Add(' result');
  for LIndex := 0 to FTess.NumVertexes - 1 do
  begin
    LLine := ' v' + IntToStr(LIndex);
    for LAxis := 0 to 2 do
      LLine := LLine + Bits(FTess.Xyz[LIndex * 4 + LAxis]);
    for LAxis := 0 to 2 do
      LLine := LLine + Bits(FTess.Normal[LIndex * 4 + LAxis]);
    FOutput.Add(LLine);
  end;
end;

procedure TQ3CalcGoldenRunner.DumpColors(const AColors: TBytes; const ABytes: Integer);
var
  LIndex, LByte: Integer;
  LLine: string;
begin
  FOutput.Add(' result');
  for LIndex := 0 to FTess.NumVertexes - 1 do
  begin
    LLine := ' c' + IntToStr(LIndex);
    for LByte := 0 to ABytes - 1 do
      LLine := LLine + ' ' + IntToStr(AColors[LIndex * 4 + LByte]);
    FOutput.Add(LLine);
  end;
end;

procedure TQ3CalcGoldenRunner.DumpTexCoords(const ATexCoords: TArray<Single>);
var
  LIndex: Integer;
begin
  FOutput.Add(' result');
  for LIndex := 0 to FTess.NumVertexes - 1 do
    FOutput.Add(' t' + IntToStr(LIndex) + Bits(ATexCoords[LIndex * 2]) + Bits(ATexCoords[LIndex * 2 + 1]));
end;

procedure TQ3CalcGoldenRunner.Command(const ALine: string);
var
  LTokens: TArray<string>;
  LName: string;
  LIndex: Integer;
  LWave: TQ3WaveForm;
  LColors: TBytes;
  LDeform: TQ3DeformStage;
  LTexCoords: TArray<Single>;
  LMod: TQ3TexMod;
  LValue, LClamped: Single;
begin
  LTokens := SplitLine(ALine);
  if Length(LTokens) = 0 then
    Exit;
  LName := LTokens[0];
  FOutput.Add('> ' + Trim(ALine));
  if LName = 'shadertime' then
    FTess.ShaderTime := Number(LTokens[1])
  else if LName = 'time' then
    FTess.RefDefTime := StrToInt(LTokens[1])
  else if LName = 'identity' then
    FIdentityLight := Number(LTokens[1])
  else if LName = 'view' then
  begin
    FTess.ViewOrigin[0] := Number(LTokens[1]);
    FTess.ViewOrigin[1] := Number(LTokens[2]);
    FTess.ViewOrigin[2] := Number(LTokens[3]);
  end
  else if LName = 'entity' then
  begin
    if LTokens[1] = 'none' then
      FTess.Entity.Present := False
    else
    begin
      FTess.Entity.Present := True;
      for LIndex := 0 to 3 do
        FTess.Entity.ShaderRGBA[LIndex] := Byte(StrToInt(LTokens[1 + LIndex]));
      FTess.Entity.ShaderTexCoord[0] := Number(LTokens[5]);
      FTess.Entity.ShaderTexCoord[1] := Number(LTokens[6]);
    end;
  end
  else if LName = 'verts' then
    GenerateVertexes(StrToInt(LTokens[1]), Cardinal(StrToInt64(LTokens[2])))
  else if LName = 'evalwave' then
  begin
    LWave := Wave(LTokens, 1);
    try
      LValue := FKit.Waves.EvalWaveForm(LWave, FTess.ShaderTime);
      LClamped := FKit.Waves.EvalWaveFormClamped(LWave, FTess.ShaderTime);
      FOutput.Add(' eval' + Bits(LValue) + ' clamped' + Bits(LClamped));
    except
      on EDeclQ3ShaderCalcException do
        FOutput.Add(' error');
    end;
  end
  else if (LName = 'wavecolor') or (LName = 'wavealpha') then
  begin
    LWave := Wave(LTokens, 1);
    SetLength(LColors, FTess.NumVertexes * 4);
    FillChar(LColors[0], Length(LColors), 7);
    try
      if LName = 'wavecolor' then
        FKit.Colors.CalcWaveColor(LWave, FTess.ShaderTime, FIdentityLight, FTess.NumVertexes, LColors)
      else
        FKit.Colors.CalcWaveAlpha(LWave, FTess.ShaderTime, FTess.NumVertexes, LColors);
      DumpColors(LColors, 4);
    except
      on EDeclQ3ShaderCalcException do
        FOutput.Add(' error');
    end;
  end
  else if (LName = 'entcolor') or (LName = 'entonecolor') or (LName = 'entalpha') or (LName = 'entonealpha') then
  begin
    SetLength(LColors, FTess.NumVertexes * 4);
    FillChar(LColors[0], Length(LColors), 7);
    if LName = 'entcolor' then
      TQ3ColorCalc.CalcColorFromEntity(FTess.Entity, FTess.NumVertexes, LColors)
    else if LName = 'entonecolor' then
      TQ3ColorCalc.CalcColorFromOneMinusEntity(FTess.Entity, FTess.NumVertexes, LColors)
    else if LName = 'entalpha' then
      TQ3ColorCalc.CalcAlphaFromEntity(FTess.Entity, FTess.NumVertexes, LColors)
    else
      TQ3ColorCalc.CalcAlphaFromOneMinusEntity(FTess.Entity, FTess.NumVertexes, LColors);
    // the alpha of "one minus entity" is not defined in the C (see TQ3ColorCalc): only three bytes are compared
    if LName = 'entonecolor' then
      DumpColors(LColors, 3)
    else
      DumpColors(LColors, 4);
  end
  else if LName = 'deform' then
  begin
    FillChar(LDeform, SizeOf(LDeform), 0);
    LDeform.Deformation := TQ3Deform(StrToInt(LTokens[1]));
    LDeform.DeformationWave := Wave(LTokens, 2);
    LDeform.DeformationSpread := Number(LTokens[7]);
    LDeform.BulgeWidth := Number(LTokens[8]);
    LDeform.BulgeHeight := Number(LTokens[9]);
    LDeform.BulgeSpeed := Number(LTokens[10]);
    LDeform.MoveVector[0] := Number(LTokens[11]);
    LDeform.MoveVector[1] := Number(LTokens[12]);
    LDeform.MoveVector[2] := Number(LTokens[13]);
    try
      FKit.Deforms.Apply(LDeform, FTess);
      DumpPositions;
    except
      on EDeclQ3ShaderCalcException do
        FOutput.Add(' error');
    end;
  end
  else if LName = 'tcgen' then
  begin
    if LTokens[1] = 'identity' then
      FBundle.TcGen := tgIdentity
    else if LTokens[1] = 'texture' then
      FBundle.TcGen := tgTexture
    else if LTokens[1] = 'lightmap' then
      FBundle.TcGen := tgLightmap
    else if LTokens[1] = 'vector' then
      FBundle.TcGen := tgVector
    else
      FBundle.TcGen := tgEnvironmentMapped;
  end
  else if LName = 'tcvec' then
  begin
    for LIndex := 0 to 5 do
      FBundle.TcGenVectors[LIndex div 3][LIndex mod 3] := Number(LTokens[1 + LIndex]);
  end
  else if LName = 'clearmods' then
    FBundle.NumTexMods := 0
  else if LName = 'texmod' then
  begin
    FillChar(LMod, SizeOf(LMod), 0);
    if LTokens[1] = 'turb' then
    begin
      LMod.ModType := tmTurbulent;
      LMod.Wave := Wave(LTokens, 2);
    end
    else if LTokens[1] = 'stretch' then
    begin
      LMod.ModType := tmStretch;
      LMod.Wave := Wave(LTokens, 2);
    end
    else if LTokens[1] = 'scroll' then
    begin
      LMod.ModType := tmScroll;
      LMod.Scroll[0] := Number(LTokens[2]);
      LMod.Scroll[1] := Number(LTokens[3]);
    end
    else if LTokens[1] = 'scale' then
    begin
      LMod.ModType := tmScale;
      LMod.Scale[0] := Number(LTokens[2]);
      LMod.Scale[1] := Number(LTokens[3]);
    end
    else if LTokens[1] = 'rotate' then
    begin
      LMod.ModType := tmRotate;
      LMod.RotateSpeed := Number(LTokens[2]);
    end
    else if LTokens[1] = 'transform' then
    begin
      LMod.ModType := tmTransform;
      LMod.Matrix[0][0] := Number(LTokens[2]);
      LMod.Matrix[0][1] := Number(LTokens[3]);
      LMod.Matrix[1][0] := Number(LTokens[4]);
      LMod.Matrix[1][1] := Number(LTokens[5]);
      LMod.Translate[0] := Number(LTokens[6]);
      LMod.Translate[1] := Number(LTokens[7]);
    end
    else if LTokens[1] = 'entity' then
      LMod.ModType := tmEntityTranslate;
    FBundle.TexMods[FBundle.NumTexMods] := LMod;
    Inc(FBundle.NumTexMods);
  end
  else if LName = 'compute' then
  begin
    SetLength(LTexCoords, FTess.NumVertexes * 2);
    for LIndex := 0 to High(LTexCoords) do
      LTexCoords[LIndex] := 0;
    try
      FKit.TexCoords.Compute(FBundle, FTess, LTexCoords);
      DumpTexCoords(LTexCoords);
    except
      on EDeclQ3ShaderCalcException do
        FOutput.Add(' error');
    end;
  end;
end;

function TQ3CalcGoldenRunner.Run(const AScenario: TStrings): TStringList;
var
  LIndex: Integer;
  LLine: string;
begin
  FOutput.Clear;
  for LIndex := 0 to AScenario.Count - 1 do
  begin
    LLine := AScenario[LIndex];
    if (LLine <> '') and (LLine[1] <> '#') then
      Command(LLine);
  end;
  Result := FOutput;
end;

{ TQ3RemapGoldenRunner }

constructor TQ3RemapGoldenRunner.Create;
begin
  inherited Create;
  FOutput := TStringList.Create;
end;

destructor TQ3RemapGoldenRunner.Destroy;
begin
  FCatalogIntf := nil;
  FOutput.Free;
  inherited Destroy;
end;

class function TQ3RemapGoldenRunner.Bits(const AValue: Single): string;
var
  LValue: Single;
begin
  LValue := AValue;
  Result := ' ' + LowerCase(IntToHex(PCardinal(@LValue)^, 8));
end;

function TQ3RemapGoldenRunner.Run(const AScenario: TStrings): TStringList;
var
  LRemapper: TQ3ShaderRemapper;
  LTokens: TArray<string>;
  LLine, LName: string;
  LIndex: Integer;
  LEntry: TFakeShaderEntry;
  LRemapped: string;
begin
  FOutput.Clear;
  FCatalog := TFakeShaderCatalog.Create;
  FCatalogIntf := FCatalog;
  LRemapper := TQ3ShaderRemapper.Create(FCatalogIntf, TOutputLog.Create(FOutput));
  try
    for LLine in AScenario do
    begin
      LTokens := SplitLine(LLine);
      if Length(LTokens) = 0 then
        Continue;
      LName := LTokens[0];
      if LName = 'reg' then
        FOutput.Add(Format('reg %s %s -> %d', [LTokens[1], LTokens[2],
          FCatalog.Register(AnsiString(LTokens[1]), StrToInt(LTokens[2]))]))
      else if LName = 'remap' then
      begin
        if Length(LTokens) >= 4 then
          FOutput.Add(Format('remap %s %s %s', [LTokens[1], LTokens[2], LTokens[3]]))
        else
          FOutput.Add(Format('remap %s %s -', [LTokens[1], LTokens[2]]));
        if (Length(LTokens) >= 4) and (LTokens[3] <> '-') then
          LRemapper.Remap(AnsiString(LTokens[1]), AnsiString(LTokens[2]), AnsiString(LTokens[3]), True)
        else
          LRemapper.Remap(AnsiString(LTokens[1]), AnsiString(LTokens[2]));
      end
      else if LName = 'remapdump' then
      begin
        for LIndex := 0 to FCatalog.Entries.Count - 1 do
        begin
          LEntry := FCatalog.Entries[LIndex];
          if LRemapper.IsRemapped(LIndex) then
            LRemapped := IntToStr(LRemapper.RemappedShader(LIndex))
          else
            LRemapped := '-1';
          FOutput.Add(Format('shader %d %s lm=%d default=%d remap=%s%s', [LIndex, string(LEntry.Name),
            LEntry.Lightmap, Ord(LEntry.Failed), LRemapped, Bits(LRemapper.TimeOffset(LIndex))]));
        end;
      end;
    end;
  finally
    LRemapper.Free;
  end;
  Result := FOutput;
end;

end.
