{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - Language of OpenXcom                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.Language;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Yaml.Types, DelphiDoom.Yaml.Intf,
  DelphiDoom.XcomEngine.Types, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.LocalizedText,
  DelphiDoom.XcomEngine.LanguagePlurality;

type
  /// <summary>Direction of the text of a language (TextDirection)</summary>
  TXcomTextDirection = (tdLeftToRight, tdRightToLeft);

  /// <summary>How a long line breaks (TextWrapping): at the words or at any letter; wwAuto only in the options</summary>
  TXcomTextWrapping = (twAuto, twWords, twLetters);

  /// <summary>
  ///   The strings of a language, read from .yml files in layers (the later files override the earlier ones). The
  ///   plural rule, the direction and the wrapping depend on the language id that is given at the start
  /// </summary>
  TXcomLanguage = class
  strict private
    FStrings: TDictionary<string, string>;
    FPlurality: TXcomLanguagePlurality;
    FDirection: TXcomTextDirection;
    FWrap: TXcomTextWrapping;
    FLanguageId: string;
    FParser: IYamlParser;
    FFiles: IXcomFileSystem;
    FLog: IXcomLog;
    FNotFound: TDictionary<string, Boolean>;
    function LoadString(const AValue: string): string;
    procedure ReportOnce(const AId, AMessage: string);
  public
    /// <param name="ALanguageId">Options::language (en-US, it...)</param>
    /// <param name="AWordwrap">Options::wordwrap; twAuto chooses letters for the CJK languages</param>
    constructor Create(const ALanguageId: string; AWordwrap: TXcomTextWrapping; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser; const ALog: IXcomLog = nil);
    destructor Destroy; override;
    /// <summary>Language::load of a file that exists: a missing file is ignored (Language::loadFile)</summary>
    procedure LoadFile(const APath: string);
    /// <summary>Language::loadRule: strings of the ExtraStrings of a mod for this language</summary>
    procedure AddStrings(const AStrings: TDictionary<string, string>);
    /// <summary>Language::getString(id): the id itself when missing; a plural string asks for the singular</summary>
    function GetString(const AId: string): TXcomLocalizedText; overload;
    /// <summary>Language::getString(id, n): the plural suffix of the language and {N} replaced</summary>
    function GetString(const AId: string; ANumber: Cardinal): TXcomLocalizedText; overload;
    function TextDirection: TXcomTextDirection;
    function TextWrapping: TXcomTextWrapping;
    function Count: Integer;
    property LanguageId: string read FLanguageId;
    /// <summary>Language::getName: the native name of a language id (a few that the menus show)</summary>
    class function NameOf(const ALanguageId: string): string; static;
  end;

implementation

const
  UNSIGNED_MAX = High(Cardinal);

constructor TXcomLanguage.Create(const ALanguageId: string; AWordwrap: TXcomTextWrapping;
  const AFiles: IXcomFileSystem; const AParser: IYamlParser; const ALog: IXcomLog);
begin
  inherited Create;
  FStrings := TDictionary<string, string>.Create;
  FNotFound := TDictionary<string, Boolean>.Create;
  FLanguageId := ALanguageId;
  FFiles := AFiles;
  FParser := AParser;
  FLog := ALog;
  FPlurality := TXcomLanguagePlurality.ForLanguage(ALanguageId);
  FDirection := tdLeftToRight;
  if AWordwrap = twAuto then
  begin
    if (ALanguageId = 'ja') or (ALanguageId = 'ko') or (ALanguageId = 'zh-CN') or (ALanguageId = 'zh-TW') then
      FWrap := twLetters
    else
      FWrap := twWords;
  end
  else
    FWrap := AWordwrap;
end;

destructor TXcomLanguage.Destroy;
begin
  FPlurality.Free;
  FNotFound.Free;
  FStrings.Free;
  inherited Destroy;
end;

function TXcomLanguage.LoadString(const AValue: string): string;
begin
  Result := StringReplace(AValue, '{NEWLINE}', #10, [rfReplaceAll]);
  Result := StringReplace(Result, '{SMALLLINE}', #2, [rfReplaceAll]);
  Result := StringReplace(Result, '{ALT}', #1, [rfReplaceAll]);
end;

procedure TXcomLanguage.LoadFile(const APath: string);
var
  LDocument: IYamlNode;
  LLanguage: IYamlNode;
  LPairs: TArray<TYamlPair>;
  LInner: TArray<TYamlPair>;
  LPair: TYamlPair;
  LInnerPair: TYamlPair;
  LValue: string;
begin
  if not FFiles.FileExists(APath) then
    Exit;
  try
    LDocument := FParser.Load(FFiles.ReadAll(APath));
    LLanguage := LDocument;
    LPairs := LDocument.Pairs;
    if (Length(LPairs) > 0) and LPairs[0].Value.IsMap then
      LLanguage := LPairs[0].Value;
    for LPair in LLanguage.Pairs do
    begin
      if LPair.Value.IsScalar then
      begin
        LValue := LPair.Value.ScalarString;
        if LValue <> '' then
          FStrings.AddOrSetValue(LPair.Key.ScalarString, LoadString(LValue));
      end
      else if LPair.Value.IsMap then
      begin
        LInner := LPair.Value.Pairs;
        for LInnerPair in LInner do
        begin
          LValue := LInnerPair.Value.ScalarString;
          if LValue <> '' then
            FStrings.AddOrSetValue(LPair.Key.ScalarString + '_' + LInnerPair.Key.ScalarString, LoadString(LValue));
        end;
      end;
    end;
  except
    on E: EYamlException do
      raise EXcomEngineException.Create(APath + ': ' + E.Message);
  end;
end;

procedure TXcomLanguage.AddStrings(const AStrings: TDictionary<string, string>);
var
  LPair: TPair<string, string>;
begin
  for LPair in AStrings do
    FStrings.AddOrSetValue(LPair.Key, LoadString(LPair.Value));
end;

procedure TXcomLanguage.ReportOnce(const AId, AMessage: string);
begin
  if FNotFound.ContainsKey(AId) then
    Exit;
  FNotFound.Add(AId, True);
  if Assigned(FLog) then
    FLog.Write('WARNING', AMessage);
end;

function TXcomLanguage.GetString(const AId: string): TXcomLocalizedText;
var
  LValue: string;
begin
  if AId = '' then
    Exit(TXcomLocalizedText.Create(''));
  if FStrings.TryGetValue(AId, LValue) then
    Exit(TXcomLocalizedText.Create(LValue));
  Result := GetString(AId, UNSIGNED_MAX);
end;

function TXcomLanguage.GetString(const AId: string; ANumber: Cardinal): TXcomLocalizedText;
var
  LFound: Boolean;
  LValue: string;
begin
  LFound := False;
  if ANumber = 0 then
    LFound := FStrings.TryGetValue(AId + '_zero', LValue);
  if not LFound then
    LFound := FStrings.TryGetValue(AId + FPlurality.Suffix(ANumber), LValue);
  if not LFound then
    LFound := FStrings.TryGetValue(AId + '_other', LValue);
  if not LFound then
  begin
    ReportOnce(AId, AId + ' not found in ' + FLanguageId);
    Exit(TXcomLocalizedText.Create(AId));
  end;
  if ANumber = UNSIGNED_MAX then
  begin
    ReportOnce(AId, AId + ' has plural format in ' + FLanguageId + '. Code assumes singular format.');
    Exit(TXcomLocalizedText.Create(LValue));
  end;
  Result := TXcomLocalizedText.Create(StringReplace(LValue, '{N}', UIntToStr(ANumber), [rfReplaceAll]));
end;

function TXcomLanguage.TextDirection: TXcomTextDirection;
begin
  Result := FDirection;
end;

function TXcomLanguage.TextWrapping: TXcomTextWrapping;
begin
  Result := FWrap;
end;

function TXcomLanguage.Count: Integer;
begin
  Result := FStrings.Count;
end;

class function TXcomLanguage.NameOf(const ALanguageId: string): string;
begin
  if ALanguageId = 'en-US' then
    Result := 'English (US)'
  else
  if ALanguageId = 'en-GB' then
    Result := 'English (UK)'
  else
  if ALanguageId = 'bg' then
    Result := #$0411 + #$044A + #$043B + #$0433 + #$0430 + #$0440 + #$0441 + #$043A + #$0438
  else
  if ALanguageId = 'ca-ES' then
    Result := 'Catal' + #$00E0
  else
  if ALanguageId = 'cs' then
    Result := #$010C + 'esky'
  else
  if ALanguageId = 'cy' then
    Result := 'Cymraeg'
  else
  if ALanguageId = 'da' then
    Result := 'Dansk'
  else
  if ALanguageId = 'de' then
    Result := 'Deutsch'
  else
  if ALanguageId = 'el' then
    Result := #$0395 + #$03BB + #$03BB + #$03B7 + #$03BD + #$03B9 + #$03BA + #$03AC
  else
  if ALanguageId = 'et' then
    Result := 'Eesti'
  else
  if ALanguageId = 'es-ES' then
    Result := 'Espa' + #$00F1 + 'ol (ES)'
  else
  if ALanguageId = 'es-419' then
    Result := 'Espa' + #$00F1 + 'ol (AL)'
  else
  if ALanguageId = 'fr' then
    Result := 'Fran' + #$00E7 + 'ais (FR)'
  else
  if ALanguageId = 'fr-CA' then
    Result := 'Fran' + #$00E7 + 'ais (CA)'
  else
  if ALanguageId = 'fi' then
    Result := 'Suomi'
  else
  if ALanguageId = 'ga' then
    Result := 'Gaeilge'
  else
  if ALanguageId = 'hr' then
    Result := 'Hrvatski'
  else
  if ALanguageId = 'hu' then
    Result := 'Magyar'
  else
  if ALanguageId = 'it' then
    Result := 'Italiano'
  else
  if ALanguageId = 'is' then
    Result := #$00CD + 'slenska'
  else
  if ALanguageId = 'ja' then
    Result := #$65E5 + #$672C + #$8A9E
  else
  if ALanguageId = 'ko' then
    Result := #$D55C + #$AD6D + #$C5B4
  else
  if ALanguageId = 'lb' then
    Result := 'L' + #$00EB + 'tzebuergesch'
  else
  if ALanguageId = 'lv' then
    Result := 'Latvie' + #$0161 + 'u'
  else
  if ALanguageId = 'nl' then
    Result := 'Nederlands'
  else
  if ALanguageId = 'no' then
    Result := 'Norsk'
  else
  if ALanguageId = 'pl' then
    Result := 'Polski'
  else
  if ALanguageId = 'pt-BR' then
    Result := 'Portugu' + #$00EA + 's (BR)'
  else
  if ALanguageId = 'pt-PT' then
    Result := 'Portugu' + #$00EA + 's (PT)'
  else
  if ALanguageId = 'ro' then
    Result := 'Rom' + #$00E2 + 'n' + #$0103
  else
  if ALanguageId = 'ru' then
    Result := #$0420 + #$0443 + #$0441 + #$0441 + #$043A + #$0438 + #$0439
  else
  if ALanguageId = 'sk' then
    Result := 'Sloven' + #$010D + 'ina'
  else
  if ALanguageId = 'sl' then
    Result := 'Sloven' + #$0161 + #$010D + 'ina'
  else
  if ALanguageId = 'sv' then
    Result := 'Svenska'
  else
  if ALanguageId = 'tr' then
    Result := 'T' + #$00FC + 'rk' + #$00E7 + 'e'
  else
  if ALanguageId = 'uk' then
    Result := #$0423 + #$043A + #$0440 + #$0430 + #$0457 + #$043D + #$0441 + #$044C + #$043A + #$0430
  else
  if ALanguageId = 'vi' then
    Result := 'Ti' + #$1EBF + 'ng Vi' + #$1EC7 + 't'
  else
  if ALanguageId = 'zh-CN' then
    Result := #$4E2D + #$6587
  else
  if ALanguageId = 'zh-TW' then
    Result := #$6587 + #$8A00
  else
    Result := ALanguageId;
end;

end.
