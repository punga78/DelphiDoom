{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - vectors and waveforms                       }
{                                                                              }
{  Port of ParseVector and ParseWaveForm of renderer\tr_shader.c of Quake III  }
{  Arena (id Software, GPL v2 or later). Based on the Quake III Arena GPL      }
{  Source Code (id Software).                                                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.ValueParser;

{$Q-}
{$R-}

interface

uses
  DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context, DelphiDoom.Decl.Q3Shader.Tokenizer;

type
  /// <summary>The values that several keywords share: "( x y z )" and "func base amplitude phase frequency"</summary>
  TQ3ShaderValueParser = class sealed
  public
    /// <summary>
    ///   ParseVector: "( v0 .. vn )" on the current line, the spaces after the parentheses are required. The
    ///   elements read before an error are kept; false with a warning on an error.
    /// </summary>
    class function ParseVector(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer;
      const ACount: Integer; var AValues: array of Single): Boolean; static;
    /// <summary>
    ///   ParseWaveForm: the function name and four numbers on the current line; what is read before a
    ///   missing word is kept (a warning, no error)
    /// </summary>
    class procedure ParseWaveForm(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer;
      var AWave: TQ3WaveForm); static;
  end;

implementation

uses
  DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Decl.Q3Shader.Names;

const
  SMissingParenthesis = 'missing parenthesis in shader ''%s''';
  SMissingVectorElement = 'missing vector element in shader ''%s''';
  SMissingWaveformParm = 'missing waveform parm in shader ''%s''';

{ TQ3ShaderValueParser }

class function TQ3ShaderValueParser.ParseVector(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer; const ACount: Integer; var AValues: array of Single): Boolean;
var
  LToken: AnsiString;
  LIndex: Integer;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken <> '(' then
  begin
    AContext.Warn(SMissingParenthesis, [AContext.Data.Name]);
    Exit(False);
  end;
  for LIndex := 0 to ACount - 1 do
  begin
    LToken := ATokenizer.ParseExt(False);
    if LToken = '' then
    begin
      AContext.Warn(SMissingVectorElement, [AContext.Data.Name]);
      Exit(False);
    end;
    AValues[LIndex] := TIdCNumbers.Atof(LToken);
  end;
  LToken := ATokenizer.ParseExt(False);
  if LToken <> ')' then
  begin
    AContext.Warn(SMissingParenthesis, [AContext.Data.Name]);
    Exit(False);
  end;
  Result := True;
end;

class procedure TQ3ShaderValueParser.ParseWaveForm(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer; var AWave: TQ3WaveForm);
var
  LToken: AnsiString;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SMissingWaveformParm, [AContext.Data.Name]);
    Exit;
  end;
  AWave.Func := TQ3ShaderNames.GenFunc(AContext, LToken);
  // BASE, AMP, PHASE, FREQ
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SMissingWaveformParm, [AContext.Data.Name]);
    Exit;
  end;
  AWave.Base := TIdCNumbers.Atof(LToken);
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SMissingWaveformParm, [AContext.Data.Name]);
    Exit;
  end;
  AWave.Amplitude := TIdCNumbers.Atof(LToken);
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SMissingWaveformParm, [AContext.Data.Name]);
    Exit;
  end;
  AWave.Phase := TIdCNumbers.Atof(LToken);
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(SMissingWaveformParm, [AContext.Data.Name]);
    Exit;
  end;
  AWave.Frequency := TIdCNumbers.Atof(LToken);
end;

end.
