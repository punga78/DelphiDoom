{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclManager                              }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.cpp (idDeclManagerLocal). Copyright (C) 1999-2011     }
{  id Software LLC, a ZeniMax Media company.                                   }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Manager;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Containers.HashIndex,
  DelphiDoom.Decl.Types, DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Intf, DelphiDoom.Decl.Statistics.Intf,
  DelphiDoom.Decl.Entry;

type
  /// <summary>
  ///   The declaration manager (idDeclManagerLocal), an object and not a singleton: the source of the files and
  ///   the log come from the constructor. It owns the entries, the files and the objects of the types; a decl
  ///   handed out is valid while the manager lives ("a decl will never go away once it is created").
  ///   Hold it through <c>IDeclManager</c>; build it with <c>TDeclManagerFactory</c>.
  ///   <para>Not ported: the huffman compression of the decl text (a memory saving; the text is kept as it is),
  ///   the console commands and cvar (<c>decl_show</c> is <c>SetShowLevel</c>), the convenience
  ///   <c>FindMaterial/FindSkin/FindSound</c> (they return the types of other issues), <c>Init</c>
  ///   (the standard types and folders are registered by <c>TDeclStandardTypes</c>).</para>
  /// </summary>
  TDeclManager = class(TInterfacedObject, IDeclManager, IDeclFinder, IDeclRegistry, IDeclHost, IDeclStatistics)
  strict private
    FSource: IDeclSource;
    FLog: IIdLibLog;
    FTypes: TList<IDeclType>;
    FFolders: TList<TPair<AnsiString, AnsiString>>;
    FFiles: TObjectList<TDeclFile>;
    FHashTables: array[0..DECL_MAX_TYPES - 1] of TIdHashIndex;
    FLinearLists: array[0..DECL_MAX_TYPES - 1] of TObjectList<TDeclEntry>;
    FImplicitFile: TDeclFile;
    FIndent: Integer;
    FInsideLevelLoad: Boolean;
    FShowLevel: Integer;
    FRecursionLevel: Integer;
    procedure CheckType(const AType: Integer; const ACaller: string);
    function HashOf(const ACanonicalName: AnsiString; const AType: Integer): Integer;
    function FindFile(const AFileName: AnsiString): TDeclFile;
  public
    constructor Create(const ASource: IDeclSource; const ALog: IIdLibLog = nil);
    destructor Destroy; override;
    /// <summary>
    ///   idDeclManagerLocal::MakeNameCanonical: '\' to '/', lower case, the text after the last '.' (and the dot)
    ///   dropped. The original overruns its buffer with a name of 1024 characters or more; here it is cut at 1023.
    /// </summary>
    class function MakeNameCanonical(const AName: AnsiString): AnsiString; static;
    // IDeclRegistry
    procedure RegisterDeclType(const ATypeName: AnsiString; const AType: Integer;
      const AAllocator: TDeclAllocator); overload;
    procedure RegisterDeclType(const AType: IDeclType); overload;
    procedure RegisterDeclFolder(const AFolder, AExtension: AnsiString; const ADefaultType: Integer);
    function GetNumDeclTypes: Integer;
    function GetDeclNameFromType(const AType: Integer): AnsiString;
    function GetDeclTypeFromName(const ATypeName: AnsiString): Integer;
    // IDeclFinder
    function FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean = True): IDecl;
    function FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
      const AMakeDefault: Boolean = True): IDecl;
    function GetNumDecls(const AType: Integer): Integer;
    function DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean = True): IDecl;
    // IDeclStatistics
    function GetTypeSlotCount: Integer;
    function IsTypeRegistered(const AType: Integer): Boolean;
    function GetTypeSize(const AType: Integer): NativeInt;
    function GetLoadedFileCount: Integer;
    function GetLoadedFilesSize: Int64;
    // IDeclManager
    function GetRegistry: IDeclRegistry;
    procedure Reload(const AForce: Boolean);
    procedure ReloadFile(const AFileName: AnsiString; const AForce: Boolean);
    procedure BeginLevelLoad;
    procedure EndLevelLoad;
    function GetChecksum: Integer;
    procedure SetShowLevel(const ALevel: Integer);
    procedure ListType(const AType: Integer; const AMode: TDeclListMode);
    procedure PrintType(const AType: Integer; const AName: AnsiString);
    function CreateNewDecl(const AType: Integer; const AName, AFileName: AnsiString): IDecl;
    function RenameDecl(const AType: Integer; const AOldName, ANewName: AnsiString): Boolean;
    function WritePrecacheCommands: AnsiString;
    // IDeclHost
    function GetDeclTypeInfo(const AType: Integer): IDeclType;
    function GetDeclTypeAt(const AIndex: Integer): IDeclType;
    function FindEntry(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean): TDeclEntry;
    function GetImplicitFile: TDeclFile;
    function GetSource: IDeclSource;
    function GetLog: IIdLibLog;
    function GetFinder: IDeclFinder;
    procedure MediaPrint(const AMessage: AnsiString);
    procedure IncIndent;
    procedure DecIndent;
    procedure EnterMakeDefault(const ADefaultText: AnsiString);
    procedure LeaveMakeDefault;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Strings, DelphiDoom.IdLib.Hashing.Md5, DelphiDoom.Decl.TypeInfo;

const
  SBadType = 'idDeclManager::%s: bad type: %d';
  SBadDefinition = 'idDecl::MakeDefault: bad DefaultDefinition(): %s';
  SIndexOutOfRange = 'idDeclManager::DeclByIndex: out of range';
  SBadTypeNumber = 'idDeclManager::RegisterDeclType: the type number %d of ''%s'' is out of range';
  MAX_NAME_CHARS = 1023;
  MAX_MAKE_DEFAULT_DEPTH = 100;

{ TDeclManager }

constructor TDeclManager.Create(const ASource: IDeclSource; const ALog: IIdLibLog);
var
  LType: Integer;
begin
  inherited Create;
  FSource := ASource;
  FLog := ALog;
  FTypes := TList<IDeclType>.Create;
  FFolders := TList<TPair<AnsiString, AnsiString>>.Create;
  FFiles := TObjectList<TDeclFile>.Create(True);
  for LType := 0 to DECL_MAX_TYPES - 1 do
  begin
    FHashTables[LType] := TIdHashIndex.Create;
    FLinearLists[LType] := TObjectList<TDeclEntry>.Create(True);
  end;
  // the file of the implicit decls is created when the manager is first used (it needs the host interface)
end;

destructor TDeclManager.Destroy;
var
  LType, LIndex: Integer;
begin
  // free decls
  for LType := 0 to DECL_MAX_TYPES - 1 do
  begin
    if Assigned(FLinearLists[LType]) then
      for LIndex := 0 to FLinearLists[LType].Count - 1 do
        FLinearLists[LType][LIndex].ReleaseDecl;
    FLinearLists[LType].Free;
    FHashTables[LType].Free;
  end;
  // free decl files, types and folders
  FImplicitFile.Free;
  FFiles.Free;
  FFolders.Free;
  FTypes.Free;
  inherited Destroy;
end;

class function TDeclManager.MakeNameCanonical(const AName: AnsiString): AnsiString;
var
  LIndex, LLastDot, LLength: Integer;
  LChar: AnsiChar;
begin
  LLength := Length(AName);
  if LLength > MAX_NAME_CHARS then
    LLength := MAX_NAME_CHARS;
  SetLength(Result, LLength);
  LLastDot := 0;
  for LIndex := 1 to LLength do
  begin
    LChar := AName[LIndex];
    if LChar = '\' then
      Result[LIndex] := '/'
    else if LChar = '.' then
    begin
      LLastDot := LIndex;
      Result[LIndex] := LChar;
    end
    else
      Result[LIndex] := TIdStrings.ToLower(LChar);
  end;
  if LLastDot <> 0 then
    SetLength(Result, LLastDot - 1);
end;

procedure TDeclManager.CheckType(const AType: Integer; const ACaller: string);
begin
  if (AType < 0) or (AType >= FTypes.Count) or not Assigned(FTypes[AType]) then
    raise EDeclException.CreateFmt(SBadType, [ACaller, AType]);
end;

function TDeclManager.HashOf(const ACanonicalName: AnsiString; const AType: Integer): Integer;
begin
  Result := FHashTables[AType].GenerateKey(ACanonicalName, False);
end;

function TDeclManager.FindFile(const AFileName: AnsiString): TDeclFile;
var
  LFile: TDeclFile;
begin
  for LFile in FFiles do
    if TIdStrings.Icmp(AFileName, LFile.FileName) = 0 then
      Exit(LFile);
  Result := nil;
end;

procedure TDeclManager.RegisterDeclType(const ATypeName: AnsiString; const AType: Integer;
  const AAllocator: TDeclAllocator);
begin
  RegisterDeclType(TDeclTypeInfo.Create(ATypeName, AType, AAllocator));
end;

procedure TDeclManager.RegisterDeclType(const AType: IDeclType);
var
  LNumber: Integer;
begin
  LNumber := AType.GetTypeId;
  if (LNumber < 0) or (LNumber >= DECL_MAX_TYPES) then
    raise EDeclException.CreateFmt(SBadTypeNumber, [LNumber, string(AType.GetTypeName)]);
  if (LNumber < FTypes.Count) and Assigned(FTypes[LNumber]) then
  begin
    if Assigned(FLog) then
      FLog.Warning(Format('idDeclManager::RegisterDeclType: type ''%s'' already exists', [string(AType.GetTypeName)]));
    Exit;
  end;
  while FTypes.Count <= LNumber do
    FTypes.Add(nil);
  FTypes[LNumber] := AType;
end;

procedure TDeclManager.RegisterDeclFolder(const AFolder, AExtension: AnsiString; const ADefaultType: Integer);
var
  LIndex: Integer;
  LKnown: Boolean;
  LFiles: TArray<AnsiString>;
  LFileName: AnsiString;
  LFile: TDeclFile;
begin
  // check whether this folder / extension combination already exists
  LKnown := False;
  for LIndex := 0 to FFolders.Count - 1 do
    if (TIdStrings.Icmp(FFolders[LIndex].Key, AFolder) = 0) and
      (TIdStrings.Icmp(FFolders[LIndex].Value, AExtension) = 0) then
      LKnown := True;
  if not LKnown then
    FFolders.Add(TPair<AnsiString, AnsiString>.Create(AFolder, AExtension));

  // scan for decl files, load and parse them
  LFiles := FSource.ListFiles(AFolder, AExtension);
  for LIndex := 0 to High(LFiles) do
  begin
    LFileName := AFolder + '/' + LFiles[LIndex];
    // check whether this file has already been loaded
    LFile := FindFile(LFileName);
    if not Assigned(LFile) then
    begin
      LFile := TDeclFile.Create((Self as IDeclHost), LFileName, ADefaultType);
      FFiles.Add(LFile);
    end;
    LFile.LoadAndParse;
  end;
end;

function TDeclManager.GetNumDeclTypes: Integer;
begin
  Result := FTypes.Count;
end;

function TDeclManager.GetDeclNameFromType(const AType: Integer): AnsiString;
begin
  CheckType(AType, 'GetDeclNameFromType');
  Result := FTypes[AType].GetTypeName;
end;

function TDeclManager.GetDeclTypeFromName(const ATypeName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FTypes.Count - 1 do
    if Assigned(FTypes[LIndex]) and (TIdStrings.Icmp(FTypes[LIndex].GetTypeName, ATypeName) = 0) then
      Exit(FTypes[LIndex].GetTypeId);
  Result := DECL_MAX_TYPES;
end;

function TDeclManager.GetImplicitFile: TDeclFile;
begin
  if not Assigned(FImplicitFile) then
    FImplicitFile := TDeclFile.Create((Self as IDeclHost), '', DECL_MAX_TYPES);
  Result := FImplicitFile;
end;

function TDeclManager.FindEntry(const AType: Integer; const AName: AnsiString;
  const AMakeDefault: Boolean): TDeclEntry;
var
  LCanonical: AnsiString;
  LHash, LIndex: Integer;
begin
  CheckType(AType, 'FindTypeWithoutParsing');
  LCanonical := MakeNameCanonical(AName);

  // see if it already exists
  LHash := HashOf(LCanonical, AType);
  LIndex := FHashTables[AType].First(LHash);
  while LIndex >= 0 do
  begin
    if TIdStrings.Icmp(FLinearLists[AType][LIndex].Name, LCanonical) = 0 then
    begin
      // only printed when decl_show is 2, because it can be a lot of clutter
      if FShowLevel > 1 then
        MediaPrint(AnsiString(Format('referencing %s %s'#10, [string(FTypes[AType].GetTypeName), string(AName)])));
      Exit(FLinearLists[AType][LIndex]);
    end;
    LIndex := FHashTables[AType].Next(LIndex);
  end;

  if not AMakeDefault then
    Exit(nil);

  Result := TDeclEntry.Create((Self as IDeclHost));
  Result.Name := LCanonical;
  Result.DeclType := AType;
  Result.State := dsUnparsed;
  Result.SourceFile := GetImplicitFile;
  Result.ParsedOutsideLevelLoad := not FInsideLevelLoad;

  // add it to the linear list and hash table
  Result.Index := FLinearLists[AType].Count;
  FHashTables[AType].Add(LHash, FLinearLists[AType].Add(Result));
end;

function TDeclManager.FindType(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean): IDecl;
var
  LName: AnsiString;
  LEntry: TDeclEntry;
begin
  LName := AName;
  if LName = '' then
    LName := '_emptyName';

  LEntry := FindEntry(AType, LName, AMakeDefault);
  if not Assigned(LEntry) then
    Exit(nil);

  LEntry.AllocateSelf;

  // if it hasn't been parsed yet, parse it now
  if LEntry.State = dsUnparsed then
    LEntry.ParseLocal;

  // mark it as referenced
  LEntry.MarkReferenced(FInsideLevelLoad);
  Result := LEntry.Decl;
end;

function TDeclManager.FindDeclWithoutParsing(const AType: Integer; const AName: AnsiString;
  const AMakeDefault: Boolean): IDecl;
var
  LEntry: TDeclEntry;
begin
  LEntry := FindEntry(AType, AName, AMakeDefault);
  // the original returns the object that exists, nil if none was made yet; here the object is made so a
  // caller never gets a nil for a decl that exists
  if Assigned(LEntry) then
  begin
    LEntry.AllocateSelf;
    Result := LEntry.Decl;
  end
  else
    Result := nil;
end;

function TDeclManager.GetNumDecls(const AType: Integer): Integer;
begin
  CheckType(AType, 'GetNumDecls');
  Result := FLinearLists[AType].Count;
end;

function TDeclManager.GetTypeSlotCount: Integer;
begin
  Result := FTypes.Count;
end;

function TDeclManager.IsTypeRegistered(const AType: Integer): Boolean;
begin
  Result := (AType >= 0) and (AType < FTypes.Count) and Assigned(FTypes[AType]);
end;

function TDeclManager.GetTypeSize(const AType: Integer): NativeInt;
var
  LEntry: TDeclEntry;
begin
  CheckType(AType, 'GetTypeSize');
  Result := 0;
  for LEntry in FLinearLists[AType] do
  begin
    Inc(Result, LEntry.Size);
    if Assigned(LEntry.Decl) then
      Inc(Result, LEntry.Decl.Size);
  end;
end;

function TDeclManager.GetLoadedFileCount: Integer;
begin
  Result := FFiles.Count;
end;

function TDeclManager.GetLoadedFilesSize: Int64;
var
  LFile: TDeclFile;
begin
  Result := 0;
  for LFile in FFiles do
    Inc(Result, LFile.FileSize);
end;

function TDeclManager.DeclByIndex(const AType, AIndex: Integer; const AForceParse: Boolean): IDecl;
var
  LEntry: TDeclEntry;
begin
  CheckType(AType, 'DeclByIndex');
  if (AIndex < 0) or (AIndex >= FLinearLists[AType].Count) then
    raise EDeclException.Create(SIndexOutOfRange);
  LEntry := FLinearLists[AType][AIndex];
  LEntry.AllocateSelf;
  if AForceParse and (LEntry.State = dsUnparsed) then
    LEntry.ParseLocal;
  Result := LEntry.Decl;
end;

function TDeclManager.GetRegistry: IDeclRegistry;
begin
  Result := Self;
end;

procedure TDeclManager.Reload(const AForce: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FFiles.Count - 1 do
    FFiles[LIndex].Reload(AForce);
end;

procedure TDeclManager.ReloadFile(const AFileName: AnsiString; const AForce: Boolean);
var
  LIndex: Integer;
begin
  for LIndex := 0 to FFiles.Count - 1 do
    if TIdStrings.Icmp(FFiles[LIndex].FileName, AFileName) = 0 then
      FFiles[LIndex].Reload(AForce);
end;

procedure TDeclManager.BeginLevelLoad;
var
  LType, LIndex: Integer;
begin
  FInsideLevelLoad := True;
  // clear all the referencedThisLevel flags and purge all the data so the next reference will cause a reparse
  for LType := 0 to DECL_MAX_TYPES - 1 do
    for LIndex := 0 to FLinearLists[LType].Count - 1 do
      FLinearLists[LType][LIndex].Purge;
end;

procedure TDeclManager.EndLevelLoad;
begin
  FInsideLevelLoad := False;
end;

function TDeclManager.GetChecksum: Integer;
var
  LType, LIndex, LTotal: Integer;
  LData: TArray<Cardinal>;
  LEntry: TDeclEntry;
  LBytes: TBytes;
begin
  SetLength(LData, 0);
  LTotal := 0;
  for LType := 0 to DECL_MAX_TYPES - 1 do
  begin
    // PDAs and associated decls are localized and are not checksummed
    if (LType = DECL_PDA) or (LType = DECL_VIDEO) or (LType = DECL_AUDIO) or (LType = DECL_EMAIL) then
      Continue;
    for LIndex := 0 to FLinearLists[LType].Count - 1 do
    begin
      LEntry := FLinearLists[LType][LIndex];
      if LEntry.SourceFile = GetImplicitFile then
        Continue;
      SetLength(LData, Length(LData) + 2);
      LData[LTotal * 2] := Cardinal(LTotal);
      LData[LTotal * 2 + 1] := LEntry.Checksum;
      Inc(LTotal);
    end;
  end;
  // little endian, as the original writes them on any machine (LittleRevBytes)
  SetLength(LBytes, LTotal * 8);
  for LIndex := 0 to LTotal * 2 - 1 do
  begin
    LBytes[LIndex * 4] := Byte(LData[LIndex]);
    LBytes[LIndex * 4 + 1] := Byte(LData[LIndex] shr 8);
    LBytes[LIndex * 4 + 2] := Byte(LData[LIndex] shr 16);
    LBytes[LIndex * 4 + 3] := Byte(LData[LIndex] shr 24);
  end;
  if LTotal = 0 then
    Result := Integer(TIdMd5.BlockChecksum(LTotal, 0))
  else
    Result := Integer(TIdMd5.BlockChecksum(LBytes[0], Length(LBytes)));
end;

procedure TDeclManager.SetShowLevel(const ALevel: Integer);
begin
  FShowLevel := ALevel;
end;

procedure TDeclManager.ListType(const AType: Integer; const AMode: TDeclListMode);
var
  LIndex, LPrinted, LCount: Integer;
  LEntry: TDeclEntry;
begin
  CheckType(AType, 'ListType');
  if not Assigned(FLog) then
    Exit;
  FLog.Printf('--------------------'#10);
  LPrinted := 0;
  LCount := FLinearLists[AType].Count;
  for LIndex := 0 to LCount - 1 do
  begin
    LEntry := FLinearLists[AType][LIndex];
    if (AMode <> dlmAll) and (LEntry.State = dsUnparsed) then
      Continue;
    if (AMode = dlmCurrent) and not LEntry.ReferencedThisLevel then
      Continue;
    if LEntry.ReferencedThisLevel then
      FLog.Printf('*')
    else if LEntry.EverReferenced then
      FLog.Printf('.')
    else
      FLog.Printf(' ');
    if LEntry.State = dsDefaulted then
      FLog.Printf('D')
    else
      FLog.Printf(' ');
    FLog.Printf(Format('%4d: ', [LEntry.Index]));
    Inc(LPrinted);
    if LEntry.State = dsUnparsed then
      // doesn't have any type specific data yet
      FLog.Printf(string(LEntry.Name) + #10)
    else
      LEntry.Decl.List;
  end;
  FLog.Printf('--------------------'#10);
  FLog.Printf(Format('%d of %d %s'#10, [LPrinted, LCount, string(FTypes[AType].GetTypeName)]));
end;

procedure TDeclManager.PrintType(const AType: Integer; const AName: AnsiString);
var
  LEntry: TDeclEntry;
  LTypeName: string;
begin
  CheckType(AType, 'PrintType');
  if not Assigned(FLog) then
    Exit;
  LTypeName := string(FTypes[AType].GetTypeName);
  // look it up, skipping the public path so it won't parse or reference
  LEntry := FindEntry(AType, AName, False);
  if not Assigned(LEntry) then
  begin
    FLog.Printf(Format('%s ''%s'' not found.'#10, [LTypeName, string(AName)]));
    Exit;
  end;

  // print information common to all decls
  FLog.Printf(Format('%s %s:'#10, [LTypeName, string(LEntry.Name)]));
  FLog.Printf(Format('source: %s:%d'#10, [string(LEntry.GetFileName), LEntry.SourceLine]));
  FLog.Printf('----------'#10);
  if LEntry.HasText then
    FLog.Printf(string(LEntry.GetText) + #10)
  else
    FLog.Printf('NO SOURCE'#10);
  FLog.Printf('----------'#10);
  case LEntry.State of
    dsUnparsed: FLog.Printf('Unparsed.'#10);
    dsDefaulted: FLog.Printf('<DEFAULTED>'#10);
    dsParsed: FLog.Printf('Parsed.'#10);
  end;

  if LEntry.ReferencedThisLevel then
    FLog.Printf('Currently referenced this level.'#10)
  else if LEntry.EverReferenced then
    FLog.Printf('Referenced in a previous level.'#10)
  else
    FLog.Printf('Never referenced.'#10);

  // allow type-specific data to be printed
  if Assigned(LEntry.Decl) then
    LEntry.Decl.Print;
end;

function TDeclManager.CreateNewDecl(const AType: Integer; const AName, AFileName: AnsiString): IDecl;
var
  LCanonical, LFileName, LHeader, LDefaultText: AnsiString;
  LHash, LIndex: Integer;
  LSourceFile: TDeclFile;
  LEntry: TDeclEntry;
begin
  CheckType(AType, 'CreateNewDecl');
  LCanonical := MakeNameCanonical(AName);
  LFileName := AnsiString(StringReplace(string(AFileName), '\', '/', [rfReplaceAll]));

  // see if it already exists
  LHash := HashOf(LCanonical, AType);
  LIndex := FHashTables[AType].First(LHash);
  while LIndex >= 0 do
  begin
    if TIdStrings.Icmp(FLinearLists[AType][LIndex].Name, LCanonical) = 0 then
    begin
      FLinearLists[AType][LIndex].AllocateSelf;
      Exit(FLinearLists[AType][LIndex].Decl);
    end;
    LIndex := FHashTables[AType].Next(LIndex);
  end;

  // find existing source file or create a new one
  LSourceFile := FindFile(LFileName);
  if not Assigned(LSourceFile) then
  begin
    LSourceFile := TDeclFile.Create((Self as IDeclHost), LFileName, AType);
    FFiles.Add(LSourceFile);
  end;

  LEntry := TDeclEntry.Create((Self as IDeclHost));
  LEntry.Name := LCanonical;
  LEntry.DeclType := AType;
  LEntry.State := dsUnparsed;
  LEntry.AllocateSelf;
  LHeader := FTypes[AType].GetTypeName;
  LDefaultText := LEntry.Decl.DefaultDefinition;

  LEntry.SetTextLocal(LHeader + ' ' + LCanonical + ' ' + LDefaultText);
  LEntry.SourceFile := LSourceFile;
  LEntry.SourceTextOffset := LSourceFile.FileSize;
  LEntry.SourceTextLength := 0;
  LEntry.SourceLine := LSourceFile.NumLines;

  LEntry.ParseLocal;

  // add this decl to the source file list
  LSourceFile.Decls.Add(LEntry);

  // add it to the hash table and linear list
  LEntry.Index := FLinearLists[AType].Count;
  FHashTables[AType].Add(LHash, FLinearLists[AType].Add(LEntry));
  Result := LEntry.Decl;
end;

function TDeclManager.RenameDecl(const AType: Integer; const AOldName, ANewName: AnsiString): Boolean;
var
  LOld, LNew: AnsiString;
  LEntry: TDeclEntry;
  LHash, LIndex: Integer;
begin
  CheckType(AType, 'RenameDecl');
  LOld := MakeNameCanonical(AOldName);
  LNew := MakeNameCanonical(ANewName);
  LEntry := nil;

  // make sure it already exists
  LHash := HashOf(LOld, AType);
  LIndex := FHashTables[AType].First(LHash);
  while LIndex >= 0 do
  begin
    if TIdStrings.Icmp(FLinearLists[AType][LIndex].Name, LOld) = 0 then
    begin
      LEntry := FLinearLists[AType][LIndex];
      Break;
    end;
    LIndex := FHashTables[AType].Next(LIndex);
  end;
  if not Assigned(LEntry) then
    Exit(False);

  // The original adds the index to the new chain and then removes it from the old one; a hash index has one
  // link per index, so adding first overwrites the link the removal needs. The order is reversed here.
  FHashTables[AType].Remove(LHash, LEntry.Index);
  LEntry.Name := LNew;
  FHashTables[AType].Add(HashOf(LNew, AType), LEntry.Index);
  Result := True;
end;

function TDeclManager.WritePrecacheCommands: AnsiString;
var
  LType, LIndex: Integer;
  LEntry: TDeclEntry;
  LLine: string;
begin
  Result := '';
  for LType := 0 to FTypes.Count - 1 do
  begin
    if not Assigned(FTypes[LType]) then
      Continue;
    for LIndex := 0 to FLinearLists[LType].Count - 1 do
    begin
      LEntry := FLinearLists[LType][LIndex];
      if not LEntry.ReferencedThisLevel then
        Continue;
      LLine := Format('touch %s %s'#10, [string(FTypes[LType].GetTypeName), string(LEntry.Name)]);
      if Assigned(FLog) then
        FLog.Printf(LLine);
      Result := Result + AnsiString(LLine);
    end;
  end;
end;

function TDeclManager.GetDeclTypeInfo(const AType: Integer): IDeclType;
begin
  CheckType(AType, 'GetDeclType');
  Result := FTypes[AType];
end;

function TDeclManager.GetDeclTypeAt(const AIndex: Integer): IDeclType;
begin
  Result := FTypes[AIndex];
end;

function TDeclManager.GetSource: IDeclSource;
begin
  Result := FSource;
end;

function TDeclManager.GetLog: IIdLibLog;
begin
  Result := FLog;
end;

function TDeclManager.GetFinder: IDeclFinder;
begin
  Result := Self;
end;

procedure TDeclManager.MediaPrint(const AMessage: AnsiString);
var
  LIndex: Integer;
  LText: string;
begin
  if (FShowLevel = 0) or not Assigned(FLog) then
    Exit;
  LText := '';
  for LIndex := 1 to FIndent do
    LText := LText + '    ';
  FLog.Printf(LText + string(AMessage));
end;

procedure TDeclManager.IncIndent;
begin
  Inc(FIndent);
end;

procedure TDeclManager.DecIndent;
begin
  Dec(FIndent);
end;

procedure TDeclManager.EnterMakeDefault(const ADefaultText: AnsiString);
begin
  Inc(FRecursionLevel);
  if FRecursionLevel > MAX_MAKE_DEFAULT_DEPTH then
  begin
    Dec(FRecursionLevel);
    raise EDeclException.CreateFmt(SBadDefinition, [string(ADefaultText)]);
  end;
end;

procedure TDeclManager.LeaveMakeDefault;
begin
  Dec(FRecursionLevel);
end;

end.
