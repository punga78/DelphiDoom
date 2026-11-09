{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - scanning tags                                    }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.ScanTag;

interface

uses
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Stream,
  DelphiDoom.Yaml.Exp;

type
  /// <summary>ScanVerbatimTag, ScanTagHandle and ScanTagSuffix</summary>
  TYamlTagScanner = class
  public
    class function ScanVerbatimTag(AStream: TYamlStream): TYamlText; static;
    class function ScanTagHandle(AStream: TYamlStream; out ACanBeHandle: Boolean): TYamlText; static;
    class function ScanTagSuffix(AStream: TYamlStream): TYamlText; static;
  end;

implementation

class function TYamlTagScanner.ScanVerbatimTag(AStream: TYamlStream): TYamlText;
var
  N: Integer;
begin
  Result := '';
  AStream.Get;
  while AStream.IsOpen do
  begin
    if AStream.Peek = YAML_KEY_VERBATIM_TAG_END then
    begin
      AStream.Get;
      Exit;
    end;
    N := TYamlExp.URI.Match(AStream);
    if N <= 0 then
      Break;
    Result := Result + AStream.Get(N);
  end;
  raise EYamlParserException.Create(AStream.Mark, SYamlEndOfVerbatimTag);
end;

class function TYamlTagScanner.ScanTagHandle(AStream: TYamlStream; out ACanBeHandle: Boolean): TYamlText;
var
  LFirstNonWordChar: TYamlMark;
  N: Integer;
begin
  Result := '';
  ACanBeHandle := True;
  LFirstNonWordChar := TYamlMark.Zero;
  while AStream.IsOpen do
  begin
    if AStream.Peek = YAML_KEY_TAG then
    begin
      if not ACanBeHandle then
        raise EYamlParserException.Create(LFirstNonWordChar, SYamlCharInTagHandle);
      Break;
    end;
    N := 0;
    if ACanBeHandle then
    begin
      N := TYamlExp.Word.Match(AStream);
      if N <= 0 then
      begin
        ACanBeHandle := False;
        LFirstNonWordChar := AStream.Mark;
      end;
    end;
    if not ACanBeHandle then
      N := TYamlExp.Tag.Match(AStream);
    if N <= 0 then
      Break;
    Result := Result + AStream.Get(N);
  end;
end;

class function TYamlTagScanner.ScanTagSuffix(AStream: TYamlStream): TYamlText;
var
  N: Integer;
begin
  Result := '';
  while AStream.IsOpen do
  begin
    N := TYamlExp.Tag.Match(AStream);
    if N <= 0 then
      Break;
    Result := Result + AStream.Get(N);
  end;
  if Result = '' then
    raise EYamlParserException.Create(AStream.Mark, SYamlTagWithNoSuffix);
end;

end.
