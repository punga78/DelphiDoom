{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shader time functions - shader remapping              }
{                                                                              }
{  Port of R_RemapShader of renderer\tr_shader.c of Quake III Arena (id        }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.Calc.Remapper;

{$Q-}
{$R-}

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Q3Shader.Calc.Intf;

type
  /// <summary>
  ///   The remapping of a shader to another one (<c>shader_t::remappedShader</c>) and the time offset the
  ///   renderer adds to the time of the new shader (<c>shader_t::timeOffset</c>), kept by handle in the object
  ///   instead of in the shader table. The two shaders come from an <c>IQ3ShaderCatalog</c>.
  /// </summary>
  TQ3ShaderRemapper = class
  strict private
    FCatalog: IQ3ShaderCatalog;
    FLog: IIdLibLog;
    FRemapped: TDictionary<Integer, Integer>;
    FTimeOffsets: TDictionary<Integer, Single>;
    function ResolveShader(const AName: AnsiString; const AWarning: string): Integer;
  public
    constructor Create(const ACatalog: IQ3ShaderCatalog; const ALog: IIdLibLog);
    destructor Destroy; override;
    /// <summary>
    ///   R_RemapShader: every shader with the name <c>AShaderName</c> (any lightmap) is drawn as
    ///   <c>ANewShaderName</c>; the same name remaps back to the shader itself (no remapping). With
    ///   <c>AHasTimeOffset</c> the new shader gets <c>atof(ATimeOffset)</c> as its time offset (a text that is
    ///   not a number is 0). A shader that is not found is a warning and nothing changes.
    /// </summary>
    procedure Remap(const AShaderName, ANewShaderName: AnsiString; const ATimeOffset: AnsiString;
      const AHasTimeOffset: Boolean); overload;
    /// <summary>R_RemapShader without a time offset (the C <c>NULL</c>)</summary>
    procedure Remap(const AShaderName, ANewShaderName: AnsiString); overload;
    /// <summary>The shader that <c>AShader</c> is drawn as; <c>AShader</c> itself if it is not remapped</summary>
    function RemappedShader(const AShader: Integer): Integer;
    /// <summary>True if <c>AShader</c> has a remapping (<c>remappedShader != NULL</c>)</summary>
    function IsRemapped(const AShader: Integer): Boolean;
    /// <summary>shader_t::timeOffset (0 if none was set)</summary>
    function TimeOffset(const AShader: Integer): Single;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.IdCNumbers;

const
  SShaderNotFound = 'R_RemapShader: shader %s not found';
  SNewShaderNotFound = 'R_RemapShader: new shader %s not found';

function StripExtension(const AName: AnsiString): AnsiString;
var
  LIndex: Integer;
begin
  // COM_StripExtension: up to the first '.'
  LIndex := Pos(AnsiString('.'), AName);
  if LIndex = 0 then
    Result := AName
  else
    Result := Copy(AName, 1, LIndex - 1);
end;

constructor TQ3ShaderRemapper.Create(const ACatalog: IQ3ShaderCatalog; const ALog: IIdLibLog);
begin
  inherited Create;
  FCatalog := ACatalog;
  FLog := ALog;
  FRemapped := TDictionary<Integer, Integer>.Create;
  FTimeOffsets := TDictionary<Integer, Single>.Create;
end;

destructor TQ3ShaderRemapper.Destroy;
begin
  FTimeOffsets.Free;
  FRemapped.Free;
  inherited Destroy;
end;

function TQ3ShaderRemapper.ResolveShader(const AName: AnsiString; const AWarning: string): Integer;
begin
  Result := FCatalog.FindShaderByName(AName);
  if Result = 0 then
    Result := FCatalog.RegisterShader(AName);
  if (Result = 0) and Assigned(FLog) then
    FLog.Warning(Format(AWarning, [string(AName)]));
end;

procedure TQ3ShaderRemapper.Remap(const AShaderName, ANewShaderName: AnsiString; const ATimeOffset: AnsiString;
  const AHasTimeOffset: Boolean);
var
  LOld, LNew, LShader: Integer;
begin
  LOld := ResolveShader(AShaderName, SShaderNotFound);
  if LOld = 0 then
    Exit;
  LNew := ResolveShader(ANewShaderName, SNewShaderNotFound);
  if LNew = 0 then
    Exit;
  // remap all the shaders with the given name, even tho they might have different lightmaps
  for LShader in FCatalog.ShadersNamed(StripExtension(AShaderName)) do
  begin
    if LShader <> LNew then
      FRemapped.AddOrSetValue(LShader, LNew)
    else
      FRemapped.Remove(LShader);
  end;
  if AHasTimeOffset then
    FTimeOffsets.AddOrSetValue(LNew, TIdCNumbers.Atof(ATimeOffset));
end;

procedure TQ3ShaderRemapper.Remap(const AShaderName, ANewShaderName: AnsiString);
begin
  Remap(AShaderName, ANewShaderName, '', False);
end;

function TQ3ShaderRemapper.RemappedShader(const AShader: Integer): Integer;
begin
  if not FRemapped.TryGetValue(AShader, Result) then
    Result := AShader;
end;

function TQ3ShaderRemapper.IsRemapped(const AShader: Integer): Boolean;
begin
  Result := FRemapped.ContainsKey(AShader);
end;

function TQ3ShaderRemapper.TimeOffset(const AShader: Integer): Single;
begin
  if not FTimeOffsets.TryGetValue(AShader, Result) then
    Result := 0;
end;

end.
