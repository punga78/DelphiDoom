{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom engine library - the options in options.cfg                 }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomEngine.FileOptionsStore;

interface

uses
  System.SysUtils, System.IOUtils, System.Generics.Collections, System.Generics.Defaults, DelphiDoom.Yaml.Types,
  DelphiDoom.Yaml.Intf, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Options, DelphiDoom.XcomEngine.YamlFields,
  DelphiDoom.XcomEngine.AtomicFiles.Intf, DelphiDoom.XcomEngine.OptionsAudit.Intf,
  DelphiDoom.XcomEngine.OptionsStore.Intf;

type
  /// <summary>
  ///   IXcomOptionsStore on the file options.cfg of the user folder. Differences from Options::save of OpenXcom
  ///   (issue 186, all meant): the file is written in one step (a temporary file takes the place of the real one, and
  ///   the last good version stays as options.cfg.bak, which Load uses when options.cfg is empty or cannot be read);
  ///   and only the keys whose value changed since the file was read or written are written, merged into the file as
  ///   it is at that moment: what another instance, a script or a person changed in other keys is not undone, and the
  ///   keys that this class does not know (lists, maps, keys of a newer OpenXcom) stay as they are. Every other
  ///   top-level section (mods, recentlyLoaded...) is kept
  /// </summary>
  TXcomFileOptionsStore = class(TInterfacedObject, IXcomOptionsStore)
  strict private
    FFiles: IXcomFileSystem;
    FParser: IYamlParser;
    FPath: string;
    FAudit: IXcomOptionsAudit;
    /// <summary>The value of every key at the last read or write, as the file has it; the keys the file did not have are not here</summary>
    FBaseline: TDictionary<string, string>;
    FBaselineMods: string;
    function BackupPath: string;
    /// <summary>The first document of a file; false when the file is missing, cannot be read or is not YAML</summary>
    function TryParse(const APath: string; out ADocument: IYamlNode): Boolean;
    procedure Warn(const AMessage: string);
    procedure Trace(const AReason, AMessage: string);
    /// <summary>The blocks of the section "options" (the lines of each key) by key; false when the file has no such section</summary>
    class function ReadBlocks(const AExisting: string; const ABlocks: TDictionary<string, string>;
      out AIndent: Integer): Boolean; static;
    /// <summary>The value on the first line of a block (the key and the quotes taken away)</summary>
    class function ValueOfBlock(const ABlock: string): string; static;
    class function SameValue(const AFile, AMemory: string): Boolean; static;
    class function HasSection(const AExisting, ASection: string): Boolean; static;
    /// <summary>The text of the top-level sections of the file other than "options", in their order, with the place of options</summary>
    function MergeOptions(const AExisting, AOptionsBlock: string; const ASection: string = 'options:'): string;
    /// <summary>The "mods" section of options.cfg for the mods of the options (a list of maps with id and active)</summary>
    function ModsBlock(AOptions: TXcomOptions): string;
    /// <summary>The text of the options section: the file's keys, with the changed ones replaced</summary>
    function BuildOptionsBlock(AEntries: TDictionary<string, string>; const AExisting: string;
      out ASummary: string): string;
    /// <summary>Writes the file in one step when the file system can, keeping the old version as .bak</summary>
    procedure WriteSafely(const AText: string);
    procedure CaptureBaseline(AOptions: TXcomOptions; const ADocument: IYamlNode);
  public
    /// <param name="AAudit">Where the reads and writes are told; nil for nowhere (the default)</param>
    constructor Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser; const AUserFolder: string;
      const AAudit: IXcomOptionsAudit = nil);
    destructor Destroy; override;
    procedure Load(AOptions: TXcomOptions; const AReason: string = '');
    procedure Save(AOptions: TXcomOptions; const AReason: string = '');
  end;

implementation

const
  SOptionsSection = 'options:';
  SModsSection = 'mods:';
  SDefaultIndent = 2;

constructor TXcomFileOptionsStore.Create(const AFiles: IXcomFileSystem; const AParser: IYamlParser;
  const AUserFolder: string; const AAudit: IXcomOptionsAudit);
begin
  inherited Create;
  FFiles := AFiles;
  FParser := AParser;
  FAudit := AAudit;
  FBaseline := TDictionary<string, string>.Create;
  if AUserFolder <> '' then
    FPath := TPath.Combine(AUserFolder, 'options.cfg');
end;

destructor TXcomFileOptionsStore.Destroy;
begin
  FBaseline.Free;
  inherited Destroy;
end;

function TXcomFileOptionsStore.BackupPath: string;
begin
  Result := FPath + '.bak';
end;

procedure TXcomFileOptionsStore.Warn(const AMessage: string);
begin
  if Assigned(FAudit) then
    FAudit.Warning(AMessage);
end;

procedure TXcomFileOptionsStore.Trace(const AReason, AMessage: string);
begin
  if Assigned(FAudit) then
    FAudit.Report(AReason, AMessage);
end;

function TXcomFileOptionsStore.TryParse(const APath: string; out ADocument: IYamlNode): Boolean;
begin
  ADocument := nil;
  Result := False;
  if not FFiles.FileExists(APath) then
    Exit;
  try
    ADocument := FParser.Load(FFiles.ReadAll(APath));
    Result := True;
  except
    on E: Exception do
    begin
      ADocument := nil;
      Warn('options: cannot read ' + APath + ' (' + E.Message + ')');
    end;
  end;
end;

procedure TXcomFileOptionsStore.CaptureBaseline(AOptions: TXcomOptions; const ADocument: IYamlNode);
var
  LEntries: TDictionary<string, string>;
  LNode: IYamlNode;
  LPair: TYamlPair;
  LValue: string;
begin
  FBaseline.Clear;
  FBaselineMods := '';
  LNode := TXcomYamlFields.Field(ADocument, 'options');
  if Assigned(LNode) then
  begin
    LEntries := AOptions.Entries;
    try
      for LPair in LNode.Pairs do
        if LPair.Key.IsScalar and LEntries.TryGetValue(LPair.Key.ScalarString, LValue) then
          FBaseline.AddOrSetValue(LPair.Key.ScalarString, LValue);
    finally
      LEntries.Free;
    end;
  end;
  if Assigned(TXcomYamlFields.Field(ADocument, 'mods')) then
    FBaselineMods := ModsBlock(AOptions);
end;

procedure TXcomFileOptionsStore.Load(AOptions: TXcomOptions; const AReason: string);
var
  LDocument: IYamlNode;
  LBackup: IYamlNode;
  LSource: string;
begin
  if FPath = '' then
    Exit;
  FBaseline.Clear;
  FBaselineMods := '';
  if not FFiles.FileExists(FPath) then
  begin
    Trace(AReason + ' load', 'no file, options unchanged');
    Exit;
  end;
  LSource := FPath;
  if not TryParse(FPath, LDocument) or not Assigned(TXcomYamlFields.Field(LDocument, 'options')) then
  begin
    // an empty, cut or unreadable file: the last good version is better than the defaults
    if TryParse(BackupPath, LBackup) and Assigned(TXcomYamlFields.Field(LBackup, 'options')) then
    begin
      Warn('options: ' + FPath + ' is empty or unreadable, the options come from ' + BackupPath);
      LDocument := LBackup;
      LSource := BackupPath;
    end
    else if not Assigned(LDocument) then
    begin
      Warn('options: ' + FPath + ' cannot be read and there is no usable ' + BackupPath + ': defaults are used');
      Exit;
    end
    else
      Warn('options: ' + FPath + ' has no options section and there is no usable ' + BackupPath);
  end;
  AOptions.Load(LDocument);
  CaptureBaseline(AOptions, LDocument);
  Trace(AReason + ' load', 'read ' + LSource);
end;

function TXcomFileOptionsStore.ModsBlock(AOptions: TXcomOptions): string;
var
  LMod: TXcomModSetting;
begin
  Result := 'mods:'#10;
  for LMod in AOptions.Mods do
    // Options::save: a map with id and active for each mod, as the file of OpenXcom has them
    Result := Result + '  - active: ' + LowerCase(BoolToStr(LMod.Active, True)) + #10'    id: ' + LMod.Id + #10;
end;

class function TXcomFileOptionsStore.HasSection(const AExisting, ASection: string): Boolean;
var
  LLine: string;
begin
  for LLine in AExisting.Replace(#13#10, #10).Split([#10]) do
    if (LLine <> '') and (LLine[1] <> ' ') and (LLine[1] <> '#') and (LLine[1] <> '-') and (LLine[1] <> #9) and
      LLine.StartsWith(ASection) then
      Exit(True);
  Result := False;
end;

class function TXcomFileOptionsStore.ReadBlocks(const AExisting: string; const ABlocks: TDictionary<string, string>;
  out AIndent: Integer): Boolean;
var
  LLine: string;
  LTrimmed: string;
  LLeading: Integer;
  LInside: Boolean;
  LKey: string;
  LColon: Integer;
begin
  Result := False;
  AIndent := 0;
  LInside := False;
  LKey := '';
  for LLine in AExisting.Replace(#13#10, #10).Split([#10]) do
  begin
    if (LLine <> '') and (LLine[1] <> ' ') and (LLine[1] <> '#') and (LLine[1] <> '-') and (LLine[1] <> #9) then
    begin
      LInside := LLine.TrimRight = SOptionsSection;
      Result := Result or LInside;
      LKey := '';
      Continue;
    end;
    if not LInside then
      Continue;
    LTrimmed := LLine.TrimLeft;
    if (LTrimmed = '') or LTrimmed.StartsWith('#') then
      Continue;
    LLeading := Length(LLine) - Length(LTrimmed);
    if AIndent = 0 then
      AIndent := LLeading;
    LColon := Pos(':', LTrimmed);
    // a key is at the indentation of the first one and is not an item of a list
    if (LLeading = AIndent) and not LTrimmed.StartsWith('-') and (LColon > 1) then
    begin
      LKey := Copy(LTrimmed, 1, LColon - 1).Trim([' ', '''', '"']);
      ABlocks.AddOrSetValue(LKey, LLine + #10);
    end
    else if LKey <> '' then
      ABlocks[LKey] := ABlocks[LKey] + LLine + #10;
  end;
end;

class function TXcomFileOptionsStore.ValueOfBlock(const ABlock: string): string;
var
  LFirst: string;
begin
  LFirst := ABlock.Split([#10])[0].TrimLeft;
  Result := Copy(LFirst, Pos(':', LFirst) + 1, MaxInt).Trim;
  if (Length(Result) >= 2) and (Result[1] = '"') and (Result[Length(Result)] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2).Replace('\"', '"').Replace('\\', '\');
end;

class function TXcomFileOptionsStore.SameValue(const AFile, AMemory: string): Boolean;
var
  LMemory: string;
begin
  LMemory := AMemory;
  // a string that needed quotes is compared without them
  if (Length(LMemory) >= 2) and (LMemory[1] = '"') and (LMemory[Length(LMemory)] = '"') then
    LMemory := Copy(LMemory, 2, Length(LMemory) - 2).Replace('\"', '"').Replace('\\', '\');
  Result := SameText(AFile, LMemory);
end;

function TXcomFileOptionsStore.BuildOptionsBlock(AEntries: TDictionary<string, string>; const AExisting: string;
  out ASummary: string): string;
var
  LBlocks: TDictionary<string, string>;
  LIndent: Integer;
  LWriteAll: Boolean;
  LKeys: TArray<string>;
  LKey: string;
  LOld: string;
  LBase: string;
  LWritten: TStringBuilder;
  LOutside: TStringBuilder;
  LBuilder: TStringBuilder;
  LWrittenCount: Integer;
  LNewCount: Integer;
begin
  LNewCount := 0;
  LBlocks := TDictionary<string, string>.Create;
  LWritten := TStringBuilder.Create;
  LOutside := TStringBuilder.Create;
  LBuilder := TStringBuilder.Create;
  try
    ReadBlocks(AExisting, LBlocks, LIndent);
    if LIndent = 0 then
      LIndent := SDefaultIndent;
    // without a section to merge into (no file, no options, a file emptied from outside) everything is written
    LWriteAll := LBlocks.Count = 0;
    LWrittenCount := 0;
    LKeys := AEntries.Keys.ToArray;
    TArray.Sort<string>(LKeys, TStringComparer.Ordinal);
    for LKey in LKeys do
    begin
      if LBlocks.TryGetValue(LKey, LOld) then
        LOld := ValueOfBlock(LOld)
      else
        LOld := '(absent)';
      if LWriteAll or not FBaseline.TryGetValue(LKey, LBase) or (LBase <> AEntries[LKey]) then
      begin
        if LOld = '(absent)' then
          Inc(LNewCount)
        else if not SameValue(LOld, AEntries[LKey]) then
          LWritten.Append(LKey).Append(': ').Append(LOld).Append(' -> ').Append(AEntries[LKey]).Append('; ');
        Inc(LWrittenCount);
        LBlocks.AddOrSetValue(LKey, StringOfChar(' ', LIndent) + LKey + ': ' + AEntries[LKey] + #10);
      end
      else if LBlocks.ContainsKey(LKey) and not SameValue(LOld, AEntries[LKey]) then
        // not ours to write: the file changed since it was read, and what is there stays
        LOutside.Append(LKey).Append(': memory ').Append(AEntries[LKey]).Append(', file ').Append(LOld).Append('; ');
    end;
    LKeys := LBlocks.Keys.ToArray;
    TArray.Sort<string>(LKeys, TStringComparer.Ordinal);
    LBuilder.Append(SOptionsSection).Append(#10);
    for LKey in LKeys do
      LBuilder.Append(LBlocks[LKey]);
    ASummary := Format('%d key(s) written (%d the file did not have)', [LWrittenCount, LNewCount]);
    if LWritten.Length > 0 then
      ASummary := ASummary + ', changed: ' + LWritten.ToString.TrimRight;
    if LOutside.Length > 0 then
      ASummary := ASummary + ' | changed in the file by someone else, kept: ' + LOutside.ToString.TrimRight;
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
    LOutside.Free;
    LWritten.Free;
    LBlocks.Free;
  end;
end;

function TXcomFileOptionsStore.MergeOptions(const AExisting, AOptionsBlock: string; const ASection: string): string;
var
  LLines: TArray<string>;
  LLine: string;
  LBuilder: TStringBuilder;
  LInOptions: Boolean;
  LWritten: Boolean;
  LTopLevel: Boolean;
begin
  LBuilder := TStringBuilder.Create;
  try
    LInOptions := False;
    LWritten := False;
    LLines := AExisting.Replace(#13#10, #10).Split([#10]);
    for LLine in LLines do
    begin
      // a top-level key starts at the first column with a letter (comments, sequences and blanks do not)
      LTopLevel := (LLine <> '') and (LLine[1] <> ' ') and (LLine[1] <> '#') and (LLine[1] <> '-') and
        (LLine[1] <> #9);
      if LTopLevel then
      begin
        LInOptions := LLine.StartsWith(ASection);
        if LInOptions then
        begin
          LBuilder.Append(AOptionsBlock);
          LWritten := True;
          Continue;
        end;
      end;
      if LInOptions then
        Continue;
      if (LLine = '') and (LLine = LLines[High(LLines)]) then
        Continue;
      LBuilder.Append(LLine).Append(#10);
    end;
    if not LWritten then
      LBuilder.Append(AOptionsBlock);
    Result := LBuilder.ToString;
  finally
    LBuilder.Free;
  end;
end;

procedure TXcomFileOptionsStore.WriteSafely(const AText: string);
var
  LAtomic: IXcomAtomicFiles;
  LTemporary: string;
  LOld: TBytes;
begin
  if not Supports(FFiles, IXcomAtomicFiles, LAtomic) then
  begin
    FFiles.WriteAll(FPath, TEncoding.UTF8.GetBytes(AText));
    Exit;
  end;
  // the new text is complete in a file of its own before the real file is touched: a write that fails or is cut
  // leaves options.cfg as it was
  LTemporary := FPath + '.tmp';
  try
    FFiles.WriteAll(LTemporary, TEncoding.UTF8.GetBytes(AText));
  except
    LAtomic.DeleteFile(LTemporary);
    raise;
  end;
  if FFiles.FileExists(FPath) then
  begin
    LOld := FFiles.ReadAll(FPath);
    // the last version that has options is the one to come back to
    if (Length(LOld) > 0) and (Pos(SOptionsSection, TEncoding.UTF8.GetString(LOld)) > 0) then
      LAtomic.CopyFile(FPath, BackupPath);
  end;
  LAtomic.ReplaceFile(LTemporary, FPath);
end;

procedure TXcomFileOptionsStore.Save(AOptions: TXcomOptions; const AReason: string);
var
  LEntries: TDictionary<string, string>;
  LExisting: string;
  LText: string;
  LSummary: string;
  LMods: string;
  LKey: string;
begin
  if FPath = '' then
    Exit;
  LExisting := '';
  if FFiles.FileExists(FPath) then
    LExisting := TEncoding.UTF8.GetString(FFiles.ReadAll(FPath));
  LEntries := AOptions.Entries;
  try
    LText := MergeOptions(LExisting, BuildOptionsBlock(LEntries, LExisting, LSummary));
    // the mods the user has chosen (the file keeps its own list when the options have none or have not changed them)
    LMods := '';
    if Length(AOptions.Mods) > 0 then
    begin
      LMods := ModsBlock(AOptions);
      if (LMods <> FBaselineMods) or not HasSection(LText, SModsSection) then
      begin
        LText := MergeOptions(LText, LMods, SModsSection);
        LSummary := LSummary + ' | mods written';
      end;
    end;
    WriteSafely(LText);
    Trace(AReason + ' save', LSummary);
    // what was written is what the next write compares with
    FBaseline.Clear;
    for LKey in LEntries.Keys do
      FBaseline.Add(LKey, LEntries[LKey]);
    if LMods <> '' then
      FBaselineMods := LMods;
  finally
    LEntries.Free;
  end;
end;

end.
