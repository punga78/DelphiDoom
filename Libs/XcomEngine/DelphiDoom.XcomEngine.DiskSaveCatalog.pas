{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the saves in a folder of the disk (SavedGame::getList, getSaveInfo))
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}unit DelphiDoom.XcomEngine.DiskSaveCatalog;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections, System.Generics.Defaults,
  Winapi.Windows, DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Language, DelphiDoom.XcomEngine.SaveInfo,
  DelphiDoom.XcomEngine.SaveCatalog.Intf;

type
  /// <summary>
  ///   IXcomSaveCatalog on the folder of the saves (the master user folder): *.sav files, and *.asav when asked. A
  ///   file that is not a valid YAML save is skipped; only the first document (the brief info) is read. The names are
  ///   ordered as the file explorer of Windows does (StrCmpLogicalW)
  /// </summary>
  TXcomDiskSaveCatalog = class(TInterfacedObject, IXcomSaveCatalog)
  strict private
    const
      QUICKSAVE = '_quick_.asav';
      AUTOSAVE_GEOSCAPE = '_autogeo_.asav';
      AUTOSAVE_BATTLESCAPE = '_autobattle_.asav';
    var
      FFolder: string;
      FActiveMaster: string;
      FParser: IYamlParser;
    function ReadInfo(const AFileName: string; ALanguage: TXcomLanguage): TXcomSaveInfo;
    function MatchesMaster(const AInfo: TXcomSaveInfo): Boolean;
    function Details(const ADocument: IYamlNode; ALanguage: TXcomLanguage): string;
  public
    constructor Create(const AFolder, AActiveMaster: string; const AParser: IYamlParser);
    function List(ALanguage: TXcomLanguage; AAutoQuick: Boolean): TArray<TXcomSaveInfo>;
    function DeleteSave(const AFileName: string): Boolean;
    function NameBefore(const AFirst, ASecond: string): Boolean;
  end;

implementation

uses
  DelphiDoom.XcomEngine.YamlFields, DelphiDoom.XcomEngine.LocalizedText, DelphiDoom.XcomEngine.Types;

function StrCmpLogicalW(psz1, psz2: PWideChar): Integer; stdcall; external 'shlwapi.dll';

constructor TXcomDiskSaveCatalog.Create(const AFolder, AActiveMaster: string; const AParser: IYamlParser);
begin
  inherited Create;
  FFolder := IncludeTrailingPathDelimiter(AFolder);
  FActiveMaster := AActiveMaster;
  FParser := AParser;
end;

function TXcomDiskSaveCatalog.NameBefore(const AFirst, ASecond: string): Boolean;
begin
  Result := StrCmpLogicalW(PWideChar(AFirst), PWideChar(ASecond)) < 0;
end;

function TXcomDiskSaveCatalog.DeleteSave(const AFileName: string): Boolean;
begin
  Result := System.SysUtils.DeleteFile(FFolder + AFileName);
end;

function TXcomDiskSaveCatalog.MatchesMaster(const AInfo: TXcomSaveInfo): Boolean;
var
  LMod: string;
  LBreak: Integer;
begin
  // _isCurrentGameType: a save without mods is an old-style one, for xcom1
  if Length(AInfo.Mods) = 0 then
    Exit(FActiveMaster = 'xcom1');
  for LMod in AInfo.Mods do
  begin
    // sanitizeModName: the version is cut off
    LBreak := Pos(' ver: ', LMod);
    if LBreak > 0 then
    begin
      if Copy(LMod, 1, LBreak - 1) = FActiveMaster then
        Exit(True);
    end
    else if LMod = FActiveMaster then
      Exit(True);
  end;
  Result := False;
end;

function TXcomDiskSaveCatalog.Details(const ADocument: IYamlNode; ALanguage: TXcomLanguage): string;
var
  LTime: IYamlNode;
  LDay: Integer;
  LMonth: Integer;
  LYear: Integer;
  LHour: Integer;
  LMinute: Integer;
  LKey: string;
  LIronman: Boolean;
const
  MONTHS: array[1..12] of string = ('STR_JAN', 'STR_FEB', 'STR_MAR', 'STR_APR', 'STR_MAY', 'STR_JUN', 'STR_JUL',
    'STR_AUG', 'STR_SEP', 'STR_OCT', 'STR_NOV', 'STR_DEC');
begin
  if TXcomYamlFields.Exists(ADocument, 'turn') then
    Result := ALanguage.GetString('STR_BATTLESCAPE').Text + ': ' +
      ALanguage.GetString(TXcomYamlFields.ReadString(ADocument, 'mission', '')).Text + ', ' +
      ALanguage.GetString('STR_TURN').Arg(TXcomYamlFields.ReadInteger(ADocument, 'turn', 0)).Text
  else
  begin
    // GameTime(6, 1, 1, 1999, 12, 0, 0).load: what the save does not have stays the default
    LTime := TXcomYamlFields.Field(ADocument, 'time');
    LDay := TXcomYamlFields.ReadInteger(LTime, 'day', 1);
    LMonth := TXcomYamlFields.ReadInteger(LTime, 'month', 1);
    LYear := TXcomYamlFields.ReadInteger(LTime, 'year', 1999);
    LHour := TXcomYamlFields.ReadInteger(LTime, 'hour', 12);
    LMinute := TXcomYamlFields.ReadInteger(LTime, 'minute', 0);
    case LDay of
      1, 21, 31:
        LKey := 'STR_DATE_FIRST';
      2, 22:
        LKey := 'STR_DATE_SECOND';
      3, 23:
        LKey := 'STR_DATE_THIRD';
    else
      LKey := 'STR_DATE_FOURTH';
    end;
    if (LMonth < 1) or (LMonth > 12) then
      raise EXcomEngineException.CreateFmt('the month %d is not between 1 and 12', [LMonth]);
    Result := ALanguage.GetString('STR_GEOSCAPE').Text + ': ' + ALanguage.GetString(LKey).Arg(LDay).Text + ' ' +
      ALanguage.GetString(MONTHS[LMonth]).Text + ' ' + IntToStr(LYear) + ', ' + IntToStr(LHour) + ':' +
      Format('%.2d', [LMinute]);
  end;
  LIronman := TXcomYamlFields.ReadBoolean(ADocument, 'ironman', False);
  if LIronman then
    Result := Result + ' (' + ALanguage.GetString('STR_IRONMAN').Text + ')';
end;

function TXcomDiskSaveCatalog.ReadInfo(const AFileName: string; ALanguage: TXcomLanguage): TXcomSaveInfo;
var
  LDocument: IYamlNode;
  LFull: string;
  LMods: TList<string>;
  LNode: IYamlNode;
begin
  LFull := FFolder + AFileName;
  LDocument := FParser.Load(TFile.ReadAllBytes(LFull));
  Result := Default(TXcomSaveInfo);
  Result.FileName := AFileName;
  if SameText(AFileName, QUICKSAVE) then
  begin
    Result.DisplayName := ALanguage.GetString('STR_QUICK_SAVE_SLOT').Text;
    Result.Reserved := True;
  end
  else if SameText(AFileName, AUTOSAVE_GEOSCAPE) then
  begin
    Result.DisplayName := ALanguage.GetString('STR_AUTO_SAVE_GEOSCAPE_SLOT').Text;
    Result.Reserved := True;
  end
  else if SameText(AFileName, AUTOSAVE_BATTLESCAPE) then
  begin
    Result.DisplayName := ALanguage.GetString('STR_AUTO_SAVE_BATTLESCAPE_SLOT').Text;
    Result.Reserved := True;
  end
  else
  begin
    if TXcomYamlFields.Exists(LDocument, 'name') then
      Result.DisplayName := TXcomYamlFields.ReadString(LDocument, 'name', '')
    else
      Result.DisplayName := ChangeFileExt(AFileName, '');
    Result.Reserved := False;
  end;
  Result.Timestamp := TFile.GetLastWriteTime(LFull);
  Result.IsoDate := FormatDateTime('yyyy-mm-dd', Result.Timestamp);
  Result.IsoTime := FormatDateTime('hh:nn', Result.Timestamp);
  LMods := TList<string>.Create;
  try
    for LNode in TXcomYamlFields.Sequence(LDocument, 'mods') do
      if LNode.IsScalar then
        LMods.Add(LNode.ScalarString);
    Result.Mods := LMods.ToArray;
  finally
    LMods.Free;
  end;
  Result.Details := Details(LDocument, ALanguage);
end;

function TXcomDiskSaveCatalog.List(ALanguage: TXcomLanguage; AAutoQuick: Boolean): TArray<TXcomSaveInfo>;
var
  LFiles: TList<string>;
  LResult: TList<TXcomSaveInfo>;
  LFile: string;
  LInfo: TXcomSaveInfo;
  LNames: TArray<string>;
begin
  LResult := TList<TXcomSaveInfo>.Create;
  LFiles := TList<string>.Create;
  try
    if not TDirectory.Exists(FFolder) then
      Exit(nil);
    // getFolderContents: the files of an extension in the order of the sort of the names, no hidden ones
    if AAutoQuick then
    begin
      LNames := TDirectory.GetFiles(FFolder, '*.asav');
      TArray.Sort<string>(LNames);
      for LFile in LNames do
        if SameText(ExtractFileExt(LFile), '.asav') then
          LFiles.Add(ExtractFileName(LFile));
    end;
    LNames := TDirectory.GetFiles(FFolder, '*.sav');
    TArray.Sort<string>(LNames);
    for LFile in LNames do
      // the filter of Windows also lets longer extensions through (.saved)
      if SameText(ExtractFileExt(LFile), '.sav') then
        LFiles.Add(ExtractFileName(LFile));
    for LFile in LFiles do
    begin
      if (LFile = '') or (LFile[1] = '.') then
        Continue;
      try
        LInfo := ReadInfo(LFile, ALanguage);
      except
        // a file that is not a save is skipped, as the C++ logs the error and goes on
        on E: Exception do
          Continue;
      end;
      if MatchesMaster(LInfo) then
        LResult.Add(LInfo);
    end;
    Result := LResult.ToArray;
  finally
    LFiles.Free;
    LResult.Free;
  end;
end;

end.