{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the languages of common\Language           }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FolderLanguageProvider;

interface

uses
  System.SysUtils, System.Generics.Collections, System.IOUtils, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf,
  DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.Resources.Intf, DelphiDoom.XcomEngine.ModResources,
  DelphiDoom.XcomEngine.LanguageProvider.Intf;

type
  /// <summary>
  ///   IXcomLanguageProvider on the data folder: the languages are the .yml files of common\Language, loaded over
  ///   the en-US ones, with the files of the mod and the extra strings of its rulesets
  /// </summary>
  TXcomFolderLanguageProvider = class(TInterfacedObject, IXcomLanguageProvider)
  strict private
    const
      DEFAULT_LANGUAGE = 'en-US';
    var
      FDataFolder: string;
      FModFolder: string;
      FFiles: IXcomFileSystem;
      FParser: IYamlParser;
      FLog: IXcomLog;
    function LanguageFolder: string;
  public
    constructor Create(const ADataFolder, AModFolder: string; const AFiles: IXcomFileSystem;
      const AParser: IYamlParser; const ALog: IXcomLog = nil);
    procedure List(out ACodes, ANames: TArray<string>);
    function Load(const ALanguageId: string; AWordwrap: TXcomTextWrapping;
      const AResources: IXcomResources): TXcomLanguage;
  end;

implementation

constructor TXcomFolderLanguageProvider.Create(const ADataFolder, AModFolder: string; const AFiles: IXcomFileSystem;
  const AParser: IYamlParser; const ALog: IXcomLog);
begin
  inherited Create;
  FDataFolder := ADataFolder;
  FModFolder := AModFolder;
  FFiles := AFiles;
  FParser := AParser;
  FLog := ALog;
end;

function TXcomFolderLanguageProvider.LanguageFolder: string;
begin
  Result := TPath.Combine(TPath.Combine(FDataFolder, 'common'), 'Language');
end;

procedure TXcomFolderLanguageProvider.List(out ACodes, ANames: TArray<string>);
var
  LIndex: Integer;
begin
  ACodes := FFiles.FolderContents(LanguageFolder, 'yml');
  SetLength(ANames, Length(ACodes));
  for LIndex := 0 to High(ACodes) do
    ANames[LIndex] := TXcomLanguage.NameOf(ACodes[LIndex]);
end;

function TXcomFolderLanguageProvider.Load(const ALanguageId: string; AWordwrap: TXcomTextWrapping;
  const AResources: IXcomResources): TXcomLanguage;
var
  LId: string;
  LStrings: TDictionary<string, string>;
  LResources: TXcomModResources;
begin
  LId := ALanguageId;
  if (LId = '') or (not FFiles.FileExists(TPath.Combine(LanguageFolder, LId + '.yml'))) then
    LId := DEFAULT_LANGUAGE;
  Result := TXcomLanguage.Create(LId, AWordwrap, FFiles, FParser, FLog);
  try
    Result.LoadFile(TPath.Combine(LanguageFolder, DEFAULT_LANGUAGE + '.yml'));
    if LId <> DEFAULT_LANGUAGE then
      Result.LoadFile(TPath.Combine(LanguageFolder, LId + '.yml'));
    Result.LoadFile(TPath.Combine(TPath.Combine(FModFolder, 'Language'), DEFAULT_LANGUAGE + '.yml'));
    if LId <> DEFAULT_LANGUAGE then
      Result.LoadFile(TPath.Combine(TPath.Combine(FModFolder, 'Language'), LId + '.yml'));
    if Assigned(AResources) and (AResources is TXcomModResources) then
    begin
      LResources := AResources as TXcomModResources;
      LStrings := LResources.ExtraStrings(DEFAULT_LANGUAGE);
      if Assigned(LStrings) then
        Result.AddStrings(LStrings);
      if LId <> DEFAULT_LANGUAGE then
      begin
        LStrings := LResources.ExtraStrings(LId);
        if Assigned(LStrings) then
          Result.AddStrings(LStrings);
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
