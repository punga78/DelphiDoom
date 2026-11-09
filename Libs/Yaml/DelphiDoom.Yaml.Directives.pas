{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the directives of a document and tag handles     }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Directives;

interface

uses
  System.SysUtils,
  System.Generics.Collections,
  DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Token;

type
  /// <summary>Tag::TYPE</summary>
  TYamlTagKind = (tkVerbatim, tkPrimaryHandle, tkSecondaryHandle, tkNamedHandle, tkNonSpecific);

  /// <summary>Directives: the %YAML version and the %TAG prefixes of the document</summary>
  TYamlDirectives = class
  strict private
    type
      TTagPair = record
        Handle: TYamlText;
        Prefix: TYamlText;
      end;
  strict private
    FTags: TList<TTagPair>;
    function IndexOfHandle(const AHandle: TYamlText): Integer;
  public
    VersionIsDefault: Boolean;
    VersionMajor: Integer;
    VersionMinor: Integer;
    constructor Create;
    destructor Destroy; override;
    function TranslateTagHandle(const AHandle: TYamlText): TYamlText;
    function HasTag(const AHandle: TYamlText): Boolean;
    procedure SetTag(const AHandle, APrefix: TYamlText);
  end;

  /// <summary>YAML::Tag: the tag of a tag token and what it means</summary>
  TYamlTag = record
  public
    Kind: TYamlTagKind;
    Handle: TYamlText;
    Value: TYamlText;
    class function FromToken(AToken: TYamlToken): TYamlTag; static;
    function Translate(ADirectives: TYamlDirectives): TYamlText;
  end;

implementation

{ TYamlDirectives }

constructor TYamlDirectives.Create;
begin
  inherited Create;
  FTags := TList<TTagPair>.Create;
  VersionIsDefault := True;
  VersionMajor := 1;
  VersionMinor := 2;
end;

destructor TYamlDirectives.Destroy;
begin
  FTags.Free;
  inherited Destroy;
end;

function TYamlDirectives.IndexOfHandle(const AHandle: TYamlText): Integer;
var
  I: Integer;
begin
  for I := 0 to FTags.Count - 1 do
    if FTags[I].Handle = AHandle then
      Exit(I);
  Result := -1;
end;

function TYamlDirectives.HasTag(const AHandle: TYamlText): Boolean;
begin
  Result := IndexOfHandle(AHandle) >= 0;
end;

procedure TYamlDirectives.SetTag(const AHandle, APrefix: TYamlText);
var
  LPair: TTagPair;
  I: Integer;
begin
  LPair.Handle := AHandle;
  LPair.Prefix := APrefix;
  I := IndexOfHandle(AHandle);
  if I >= 0 then
    FTags[I] := LPair
  else
    FTags.Add(LPair);
end;

function TYamlDirectives.TranslateTagHandle(const AHandle: TYamlText): TYamlText;
var
  I: Integer;
begin
  I := IndexOfHandle(AHandle);
  if I < 0 then
  begin
    if AHandle = '!!' then
      Exit('tag:yaml.org,2002:');
    Exit(AHandle);
  end;
  Result := FTags[I].Prefix;
end;

{ TYamlTag }

class function TYamlTag.FromToken(AToken: TYamlToken): TYamlTag;
begin
  Result.Kind := TYamlTagKind(AToken.Data);
  Result.Handle := '';
  Result.Value := '';
  case Result.Kind of
    tkVerbatim, tkPrimaryHandle, tkSecondaryHandle:
      Result.Value := AToken.Value;
    tkNamedHandle:
      begin
        Result.Handle := AToken.Value;
        Result.Value := AToken.Params[0];
      end;
    tkNonSpecific:
      ;
  end;
end;

function TYamlTag.Translate(ADirectives: TYamlDirectives): TYamlText;
begin
  case Kind of
    tkVerbatim: Result := Value;
    tkPrimaryHandle: Result := ADirectives.TranslateTagHandle('!') + Value;
    tkSecondaryHandle: Result := ADirectives.TranslateTagHandle('!!') + Value;
    tkNamedHandle: Result := ADirectives.TranslateTagHandle('!' + Handle + '!') + Value;
  else
    Result := '!';
  end;
end;

end.
