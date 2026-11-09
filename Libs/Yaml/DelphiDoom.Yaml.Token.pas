{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - the tokens the scanner gives to the parser       }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.Token;

interface

uses
  DelphiDoom.Yaml.Types;

type
  /// <summary>Token::STATUS: a possible simple key is "unverified" until the colon after it is found</summary>
  TYamlTokenStatus = (tsValid, tsInvalid, tsUnverified);

  /// <summary>Token::TYPE</summary>
  TYamlTokenType = (
    ttDirective, ttDocStart, ttDocEnd, ttBlockSeqStart, ttBlockMapStart, ttBlockSeqEnd, ttBlockMapEnd,
    ttBlockEntry, ttFlowSeqStart, ttFlowMapStart, ttFlowSeqEnd, ttFlowMapEnd, ttFlowMapCompact,
    ttFlowEntry, ttKey, ttValue, ttAnchor, ttAlias, ttTag, ttPlainScalar, ttNonPlainScalar);

  /// <summary>
  ///   YAML::Token. A class (not a record) because the scanner keeps references to tokens that are still in its
  ///   queue (the possible simple keys) and changes their status later
  /// </summary>
  TYamlToken = class
  public
    Status: TYamlTokenStatus;
    TokenType: TYamlTokenType;
    Mark: TYamlMark;
    Value: TYamlText;
    Params: TArray<TYamlText>;
    /// <summary>The kind of a tag token (Tag::TYPE)</summary>
    Data: Integer;
    constructor Create(AType: TYamlTokenType; const AMark: TYamlMark);
  end;

implementation

constructor TYamlToken.Create(AType: TYamlTokenType; const AMark: TYamlMark);
begin
  inherited Create;
  Status := tsValid;
  TokenType := AType;
  Mark := AMark;
end;

end.
