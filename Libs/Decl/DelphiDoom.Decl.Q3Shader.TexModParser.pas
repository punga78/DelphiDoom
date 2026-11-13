{******************************************************************************}
{                                                                              }
{  DelphiDoom: Quake III shaders - tcMod                                       }
{                                                                              }
{  Port of ParseTexMod of renderer\tr_shader.c of Quake III Arena (id          }
{  Software, GPL v2 or later). Based on the Quake III Arena GPL Source Code    }
{  (id Software).                                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Q3Shader.TexModParser;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.Decl.Q3Shader.Types, DelphiDoom.Decl.Q3Shader.Context,
  DelphiDoom.Decl.Q3Shader.Tokenizer;

type
  /// <summary>The line of a <c>tcMod</c> of a stage</summary>
  TQ3ShaderTexModParser = class sealed
  strict private
    class function ReadNumber(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer;
      const AMessage: string; var AValue: Single): Boolean; static;
    class function ReadWave(const AContext: TQ3ShaderContext; const ATokenizer: TQ3ShaderTokenizer;
      const AMessage: string; const AWithFunc: Boolean; var AWave: TQ3WaveForm): Boolean; static;
  public
    /// <summary>
    ///   ParseTexMod: <c>ALine</c> is the words of the line joined by a blank, as ParseStage builds it. The new
    ///   texMod is counted before its words are read, so a line that is cut short leaves a texMod of type none.
    ///   More than <c>Q3_MAX_TEXMODS</c> of them raise <c>EDeclQ3ShaderException</c> (the ERR_DROP of the original).
    /// </summary>
    class procedure ParseTexMod(const AContext: TQ3ShaderContext; const AStage: PQ3ShaderStage;
      const ALine: AnsiString); static;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.Scanner.IdCNumbers, DelphiDoom.Decl.Q3Shader.Names;

const
  STooManyTexMods = 'too many tcMod stages in shader ''%s''';
  SMissingTurb = 'missing tcMod turb parms in shader ''%s''';
  SMissingTurbOther = 'missing tcMod turb in shader ''%s''';
  SMissingScale = 'missing scale parms in shader ''%s''';
  SMissingScroll = 'missing scale scroll parms in shader ''%s''';
  SMissingStretch = 'missing stretch parms in shader ''%s''';
  SMissingTransform = 'missing transform parms in shader ''%s''';
  SMissingRotate = 'missing tcMod rotate parms in shader ''%s''';
  SUnknownTcMod = 'unknown tcMod ''%s'' in shader ''%s''';

{ TQ3ShaderTexModParser }

class function TQ3ShaderTexModParser.ReadNumber(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer; const AMessage: string; var AValue: Single): Boolean;
var
  LToken: AnsiString;
begin
  LToken := ATokenizer.ParseExt(False);
  if LToken = '' then
  begin
    AContext.Warn(AMessage, [AContext.Data.Name]);
    Exit(False);
  end;
  AValue := TIdCNumbers.Atof(LToken);
  Result := True;
end;

// base, amplitude, phase, frequency (turb) or func, base, amplitude, phase, frequency (stretch)
class function TQ3ShaderTexModParser.ReadWave(const AContext: TQ3ShaderContext;
  const ATokenizer: TQ3ShaderTokenizer; const AMessage: string; const AWithFunc: Boolean;
  var AWave: TQ3WaveForm): Boolean;
var
  LToken: AnsiString;
begin
  Result := False;
  if AWithFunc then
  begin
    LToken := ATokenizer.ParseExt(False);
    if LToken = '' then
    begin
      AContext.Warn(AMessage, [AContext.Data.Name]);
      Exit;
    end;
    AWave.Func := TQ3ShaderNames.GenFunc(AContext, LToken);
  end;
  if not ReadNumber(AContext, ATokenizer, AMessage, AWave.Base) then
    Exit;
  if not ReadNumber(AContext, ATokenizer, AMessage, AWave.Amplitude) then
    Exit;
  if not ReadNumber(AContext, ATokenizer, AMessage, AWave.Phase) then
    Exit;
  Result := ReadNumber(AContext, ATokenizer, AMessage, AWave.Frequency);
end;

class procedure TQ3ShaderTexModParser.ParseTexMod(const AContext: TQ3ShaderContext; const AStage: PQ3ShaderStage;
  const ALine: AnsiString);
var
  LTokenizer: TQ3ShaderTokenizer;
  LTexMod: ^TQ3TexMod;
  LToken: AnsiString;
begin
  if AStage.Bundle.NumTexMods = Q3_MAX_TEXMODS then
    raise EDeclQ3ShaderException.CreateFmt(STooManyTexMods, [string(AContext.Data.Name)]);
  LTexMod := @AStage.Bundle.TexMods[AStage.Bundle.NumTexMods];
  Inc(AStage.Bundle.NumTexMods);
  LTokenizer := TQ3ShaderTokenizer.Create(ALine);
  try
    LToken := LTokenizer.ParseExt(False);
    if TIdStrings.Icmp(LToken, 'turb') = 0 then
    begin
      // the first of the four words has its own message
      if not ReadNumber(AContext, LTokenizer, SMissingTurb, LTexMod.Wave.Base) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTurbOther, LTexMod.Wave.Amplitude) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTurbOther, LTexMod.Wave.Phase) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTurbOther, LTexMod.Wave.Frequency) then
        Exit;
      LTexMod.ModType := tmTurbulent;
    end
    else if TIdStrings.Icmp(LToken, 'scale') = 0 then
    begin
      if not ReadNumber(AContext, LTokenizer, SMissingScale, LTexMod.Scale[0]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingScale, LTexMod.Scale[1]) then
        Exit;
      LTexMod.ModType := tmScale;
    end
    else if TIdStrings.Icmp(LToken, 'scroll') = 0 then
    begin
      if not ReadNumber(AContext, LTokenizer, SMissingScroll, LTexMod.Scroll[0]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingScroll, LTexMod.Scroll[1]) then
        Exit;
      LTexMod.ModType := tmScroll;
    end
    else if TIdStrings.Icmp(LToken, 'stretch') = 0 then
    begin
      if not ReadWave(AContext, LTokenizer, SMissingStretch, True, LTexMod.Wave) then
        Exit;
      LTexMod.ModType := tmStretch;
    end
    else if TIdStrings.Icmp(LToken, 'transform') = 0 then
    begin
      if not ReadNumber(AContext, LTokenizer, SMissingTransform, LTexMod.Matrix[0, 0]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTransform, LTexMod.Matrix[0, 1]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTransform, LTexMod.Matrix[1, 0]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTransform, LTexMod.Matrix[1, 1]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTransform, LTexMod.Translate[0]) then
        Exit;
      if not ReadNumber(AContext, LTokenizer, SMissingTransform, LTexMod.Translate[1]) then
        Exit;
      LTexMod.ModType := tmTransform;
    end
    else if TIdStrings.Icmp(LToken, 'rotate') = 0 then
    begin
      if not ReadNumber(AContext, LTokenizer, SMissingRotate, LTexMod.RotateSpeed) then
        Exit;
      LTexMod.ModType := tmRotate;
    end
    else if TIdStrings.Icmp(LToken, 'entityTranslate') = 0 then
      LTexMod.ModType := tmEntityTranslate
    else
      AContext.Warn(SUnknownTcMod, [LToken, AContext.Data.Name]);
  finally
    LTokenizer.Free;
  end;
end;

end.
