{******************************************************************************}
{                                                                              }
{  DelphiDoom: PAK - the PAK file system of the engine                         }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
{$I Doom32.inc}

unit DelphiDoom.Pak.FileSystem;

interface

uses
  d_delphi,
  DelphiDoom.Wad.Intf,
  DelphiDoom.Wad.Pak.Types,
  DelphiDoom.Wad.Pak.Intf,
  DelphiDoom.Engine.Wad.Intf,
  DelphiDoom.Pak.Intf,
  DelphiDoom.Pak.EntryReader;

type
  /// <summary>
  ///   The PAK file system (the old TPakManager of w_pak): the containers are read with the WAD
  ///   services of the engine, their files go in an IPakIndex and are opened with the rules of an
  ///   IPakPathResolver, both made by the services. A WAD gives its PK3ENTRY aliases and the
  ///   images between HI_START/HI_END and TX_START/TX_END (as TEXTURES\name.ext); a WAD inside a
  ///   PAK or a PK3 is given to w_wad to be loaded later
  /// </summary>
  TPakFileSystem = class(TInterfacedObject, IPakFileSystem, IPakContainers)
  strict private
    FServices: IEngineWadServices;
    FIndex: IPakIndex;
    FResolver: IPakPathResolver;
    FContainers: TDStringList;
    FSources: TArray<IWadSource>;
    FPending: TDStringList;
    FInitialized: Boolean;
    procedure Reset;
    function AddContainer(const AFileName: string): Boolean;
    procedure AddWadLumps(var AFile: file; const AContainer: string; ANumber: Integer;
      const ASource: IWadSource);
    function ReadTextOf(AIndex: Integer; out AText: string): Boolean;
  public
    /// <summary>Raises EArgumentNilException when AServices is nil</summary>
    constructor Create(const AServices: IEngineWadServices);
    destructor Destroy; override;
    { IPakContainers }
    procedure Initialize;
    procedure ShutDown;
    function AddFile(const AFileName: string): Boolean;
    procedure AddDirectory(const APath: string);
    procedure LoadPending;
    { IPakFileSystem }
    function Open(const AFileName: string; AMode: TPakLookupMode;
      const APreferred: TArray<string>; const ADirectory: string): TDStream;
    function OpenEntry(AIndex: Integer): TDStream;
    function Locate(const AFileName: string; AMode: TPakLookupMode; const APreferred: TArray<string>;
      const ADirectory: string; const ADisk: TPakDiskOpener; const AEntry: TPakEntryOpener): Boolean;
    function ReadEntry(AIndex: Integer): TPakEntryReader;
    function MatchingEntries(const AName: string): TArray<Integer>;
    function EntryCount: Integer;
    function EntryName(AIndex: Integer): string;
    function Texts(const AName: string): TArray<string>;
    function ReadText(const AName: string): string;
    function ReadAllTexts(const AName: string): string;
    function GlobalHash: Cardinal;
  end;

implementation

uses
  System.SysUtils,
  i_system,
  w_wad,
  DelphiDoom.Wad.Types,
  DelphiDoom.Texture.PatchInspector,
  DelphiDoom.Texture.Decoder.Flat,
  DelphiDoom.Texture.Decoder.Pcx,
  DelphiDoom.Pak.Stream;

const
  SServicesMissing = 'TPakFileSystem: the WAD services are nil';
  // the bytes of a lump between HI_START and TX_START that tell its image format
  IMAGE_HEADER_SIZE = 128;

{ TPakFileSystem }

constructor TPakFileSystem.Create(const AServices: IEngineWadServices);
begin
  inherited Create;
  if not Assigned(AServices) then
    raise EArgumentNilException.Create(SServicesMissing);
  FServices := AServices;
  FPending := TDStringList.Create;
  // before Initialize a name can only be a file on disk, as with the old code
  Reset;
end;

destructor TPakFileSystem.Destroy;
begin
  FContainers.Free;
  FPending.Free;
  inherited;
end;

procedure TPakFileSystem.Reset;
begin
  FResolver := nil;
  FIndex := FServices.CreatePakIndex;
  FResolver := FServices.CreatePakResolver(FIndex);
  FSources := nil;
  FContainers.Free;
  FContainers := TDStringList.Create;
end;

procedure TPakFileSystem.Initialize;
begin
  Reset;
  FInitialized := True;
end;

procedure TPakFileSystem.ShutDown;
begin
  Reset;
  FInitialized := False;
end;

procedure TPakFileSystem.LoadPending;
var
  LIndex: Integer;
begin
  if FPending.Count = 0 then
    Exit;
  for LIndex := 0 to FPending.Count - 1 do
    if I_DirectoryExists(FPending.Strings[LIndex]) then
      AddDirectory(FPending.Strings[LIndex])
    else
      AddContainer(FPending.Strings[LIndex]);
  FPending.Clear;
end;

procedure TPakFileSystem.AddDirectory(const APath: string);

  procedure AddMatching(const AMask: string);
  var
    LMask: string;
    LFiles: TDStringList;
    LIndex: Integer;
  begin
    LMask := AMask;
    if APath <> '' then
      LMask := APath + '\' + LMask;
    LFiles := findfiles(LMask);
    try
      // findfiles gives the names without the path: a folder other than the current one
      // added nothing, because the files could not be opened
      for LIndex := 0 to LFiles.Count - 1 do
        if APath <> '' then
          AddContainer(APath + '\' + LFiles[LIndex])
        else
          AddContainer(LFiles[LIndex]);
    finally
      LFiles.Free;
    end;
  end;

begin
  if not FInitialized then
  begin
    FPending.Add(APath);
    Exit;
  end;
  // a ZIP is not loaded from a folder: only PK3/PK4, PAK and WAD
  AddMatching('*.PAK');
  AddMatching('*.PK3');
  AddMatching('*.PK4');
  AddMatching('*.WAD');
  AddMatching('*.IWAD');
end;

function TPakFileSystem.AddFile(const AFileName: string): Boolean;
begin
  if not FInitialized then
  begin
    FPending.Add(AFileName);
    Exit(False);
  end;

  LoadPending;

  if I_DirectoryExists(AFileName) then
  begin
    printf(' adding directory %s'#13#10, [AFileName]);
    AddDirectory(AFileName);
    Result := True;
  end
  else
    Result := AddContainer(AFileName);
end;

function TPakFileSystem.AddContainer(const AFileName: string): Boolean;
var
  LFile: file;
  LRead: Integer;
  LId: Integer;
  LName: string;
  LNumber: Integer;
  LSource: IWadSource;
  LEntry: TWadEntry;
  LIndex: Integer;
  LIsWad: Boolean;
  LWads: TDStringList;
  LExtension: string;
begin
  Result := False;
  LName := d_delphi.strupper(AFileName);
  if FContainers.IndexOf(LName) > -1 then
  begin
    I_Warning('TPakManager.PAddFile(): Trying to add twice file "%s"'#13#10, [AFileName]);
    Exit;
  end;

  if not fopen(LFile, LName, fOpenReadOnly) then
  begin
    I_Warning('TPakManager.PAddFile(): Can not open file "%s"'#13#10, [AFileName]);
    Exit;
  end;

  BlockRead(LFile, LId, 4, LRead);
  if LRead <> 4 then
  begin
    Close(LFile);
    I_Warning('TPakManager.PAddFile(): Can not read file "%s"'#13#10, [AFileName]);
    Exit;
  end;
  LIsWad := (LId = WAD_ID_IWAD) or (LId = WAD_ID_PWAD) or (LId = WAD_ID_DWAD);
  if (LId <> PAK_ID) and (LId <> WAD2_ID) and (LId <> WAD3_ID) and (LId <> ZIP_ID) and not LIsWad then
  begin
    Close(LFile);
    I_Warning('TPakManager.PAddFile(): Unknown file type "%s"'#13#10, [AFileName]);
    Exit;
  end;

  // The directory of the file is read by the WAD library; the file stays open only for a WAD,
  // to look at the first bytes of its textures
  if not LIsWad then
    Close(LFile);

  LNumber := FContainers.Add(LName);
  SetLength(FSources, FContainers.Count);

  try
    LSource := FServices.OpenPath(LName);
  except
    on E: EWadException do
    begin
      if LIsWad then
        Close(LFile);
      I_Warning('TPakManager.PAddFile(): Can not read file "%s": %s'#13#10, [AFileName, E.Message]);
      Exit;
    end;
  end;
  FSources[LNumber] := LSource;

  LWads := nil;
  try
    if not LIsWad then
    begin
      // PAK, ZIP (PK3/PK4), WAD2/WAD3: the entries are the files
      for LIndex := 0 to LSource.Count - 1 do
      begin
        LEntry := LSource.Entries[LIndex];
        FIndex.Add(LEntry.Name, LName, LNumber, LIndex, LEntry.Size);
        LExtension := d_delphi.strupper(fext(LEntry.Name));
        if (LExtension = '.WAD') or (LExtension = '.IWAD') then
        begin
          if LWads = nil then
            LWads := TDStringList.Create;
          LWads.Add(LEntry.Name);
        end;
      end;
    end
    else
    begin
      AddWadLumps(LFile, LName, LNumber, LSource);
      Close(LFile);
    end;

    Result := True;
    printf(' adding %s'#13#10, [AFileName]);

    if LWads <> nil then
      for LIndex := 0 to LWads.Count - 1 do
        W_AddPendingWADfromPAK(LWads.Strings[LIndex]);
  finally
    LWads.Free;
  end;
end;

procedure TPakFileSystem.AddWadLumps(var AFile: file; const AContainer: string; ANumber: Integer;
  const ASource: IWadSource);

  function IsValidPatch(const AEntry: TWadEntry): Boolean;
  var
    LPosition: Integer;
    LRead: Integer;
    LLump: TBytes;
  begin
    // the lump as the old T_IsValidPatchImage read it: from the file, then back where it was
    LPosition := FilePos(AFile);
    Seek(AFile, AEntry.Offset);
    SetLength(LLump, AEntry.Size);
    LRead := 0;
    if AEntry.Size > 0 then
      BlockRead(AFile, LLump[0], AEntry.Size, LRead);
    Result := (LRead = AEntry.Size) and TTexturePatchInspector.IsValid(LLump, LRead);
    Seek(AFile, LPosition);
  end;

var
  LInHires: Boolean;
  LInTextures: Boolean;
  LHeader: TBytes;
  LRead: Integer;
  LAliases: TDStringList;
  LAlias: string;
  LLumpBytes: TBytes;
  LLine: string;
  LComment: Integer;
  LIndex: Integer;
  LCharacter: Integer;
  LEntry: TWadEntry;
  LLumpName: string;
begin
  LInHires := False;
  LInTextures := False;
  SetLength(LHeader, IMAGE_HEADER_SIZE);
  LAliases := TDStringList.Create;
  try
    for LIndex := 0 to ASource.Count - 1 do
    begin
      LEntry := ASource.Entries[LIndex];
      // 'PK3ENTRY' wad lump contains aliases for wad lumps (8 characters - short filename)
      // to the PK3/PAK filesystem (long filenames).
      LLumpName := LEntry.Name;
      if LLumpName = 'PK3ENTRY' then
      begin
        LLumpBytes := ASource.ReadEntry(LIndex);
        SetLength(LAlias, Length(LLumpBytes));
        for LCharacter := 1 to Length(LLumpBytes) do
          LAlias[LCharacter] := Chr(LLumpBytes[LCharacter - 1]);
        LAliases.Text := LAliases.Text + LAlias + #13#10;
      end
      else if LLumpName = 'HI_START' then
        LInHires := True
      else if LLumpName = 'HI_END' then
        LInHires := False
      else if LLumpName = 'TX_START' then
        LInTextures := True
      else if LLumpName = 'TX_END' then
        LInTextures := False
      else if LInHires or LInTextures then
      begin
        Seek(AFile, LEntry.Offset);
        FillChar(LHeader[0], IMAGE_HEADER_SIZE, 0);
        BlockRead(AFile, LHeader[0], IMAGE_HEADER_SIZE, LRead);
        if (LHeader[0] = 0) and (LHeader[1] = 0) and (LHeader[2] = 2) and (LHeader[3] = 0) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.TGA', AContainer, ANumber, LIndex, LEntry.Size)
        else if (LHeader[1] = $50) and (LHeader[2] = $4E) and (LHeader[3] = $47) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.PNG', AContainer, ANumber, LIndex, LEntry.Size)
        else if (LHeader[0] = $42) and (LHeader[1] = $4D) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.BMP', AContainer, ANumber, LIndex, LEntry.Size)
        else if (LHeader[6] = $4A) and (LHeader[7] = $46) and (LHeader[8] = $49) and (LHeader[9] = $46) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.JPG', AContainer, ANumber, LIndex, LEntry.Size)
        else if (LRead >= IMAGE_HEADER_SIZE) and TTexturePcxDecoder.IsValidHeader(LHeader) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.PCX', AContainer, ANumber, LIndex, LEntry.Size)
        else if (LRead >= 4) and IsValidPatch(LEntry) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.PATCH', AContainer, ANumber, LIndex, LEntry.Size)
        else if TTextureFlatDecoder.IsFlatLength(LEntry.Size) then
          FIndex.Add(PAK_TEXTURE_PATH + LLumpName + '.FLAT', AContainer, ANumber, LIndex, LEntry.Size);
      end;
    end;
    // JVAL: 20190913 Allow comments inside PK3ENTRY lumps
    LAlias := '';
    for LIndex := 0 to LAliases.Count - 1 do
    begin
      LLine := LAliases.Strings[LIndex];
      LComment := Pos('//', LLine);
      if LComment > 0 then
        SetLength(LLine, LComment - 1);
      LLine := strremovespaces(LLine);
      if LLine <> '' then
        LAlias := LAlias + LLine + #13#10;
    end;
    LAliases.Text := LAlias;
    // JVAL: 20170904 Remove blanc entries
    for LIndex := LAliases.Count - 1 downto 0 do
      if LAliases.Strings[LIndex] = '' then
        LAliases.Delete(LIndex);
    if LAliases.Count > 0 then
      for LIndex := 0 to ASource.Count - 1 do
      begin
        LEntry := ASource.Entries[LIndex];
        if LAliases.IndexOfName(LEntry.Name) > -1 then
          FIndex.Add(LAliases.Values[LEntry.Name], AContainer, ANumber, LIndex, LEntry.Size);
      end;
  finally
    LAliases.Free;
  end;
end;

function TPakFileSystem.Open(const AFileName: string; AMode: TPakLookupMode;
  const APreferred: TArray<string>; const ADirectory: string): TDStream;
begin
  Result := TPakFileStream.Create(Self, AFileName, AMode, APreferred, ADirectory);
end;

function TPakFileSystem.OpenEntry(AIndex: Integer): TDStream;
begin
  Result := TPakFileStream.CreateEntry(Self, AIndex);
end;

function TPakFileSystem.Locate(const AFileName: string; AMode: TPakLookupMode;
  const APreferred: TArray<string>; const ADirectory: string; const ADisk: TPakDiskOpener;
  const AEntry: TPakEntryOpener): Boolean;
begin
  Result := FResolver.Resolve(AFileName, AMode, APreferred, ADirectory, ADisk, AEntry);
end;

function TPakFileSystem.ReadEntry(AIndex: Integer): TPakEntryReader;
var
  LEntry: TPakIndexEntry;
begin
  LEntry := FIndex.Entry(AIndex);
  try
    Result := TPakEntryReader.Create(FSources[LEntry.Source], LEntry.Entry);
  except
    on E: EWadException do
    begin
      I_Warning('TPakManager.PLoadEntry(): %s'#13#10, [E.Message]);
      Result := nil;
    end;
  end;
end;

function TPakFileSystem.MatchingEntries(const AName: string): TArray<Integer>;
begin
  Result := FIndex.Matching(AName);
end;

function TPakFileSystem.EntryCount: Integer;
begin
  Result := FIndex.Count;
end;

function TPakFileSystem.EntryName(AIndex: Integer): string;
begin
  Result := FIndex.Entry(AIndex).Name;
end;

function TPakFileSystem.ReadTextOf(AIndex: Integer; out AText: string): Boolean;
var
  LStream: TDStream;
  LLines: TDStringList;
begin
  LStream := OpenEntry(AIndex);
  try
    Result := LStream.IOResult = 0;
    if Result then
    begin
      LLines := TDStringList.Create;
      try
        LLines.LoadFromStream(LStream);
        AText := LLines.Text;
      finally
        LLines.Free;
      end;
    end;
  finally
    LStream.Free;
  end;
end;

function TPakFileSystem.Texts(const AName: string): TArray<string>;
var
  LEntries: TArray<Integer>;
  LIndex: Integer;
  LCount: Integer;
  LText: string;
begin
  LEntries := MatchingEntries(AName);
  SetLength(Result, Length(LEntries));
  LCount := 0;
  for LIndex := 0 to High(LEntries) do
    if ReadTextOf(LEntries[LIndex], LText) then
    begin
      Result[LCount] := LText;
      Inc(LCount);
    end;
  SetLength(Result, LCount);
end;

function TPakFileSystem.ReadText(const AName: string): string;
var
  LEntries: TArray<Integer>;
begin
  Result := '';
  LEntries := MatchingEntries(AName);
  if Length(LEntries) > 0 then
    ReadTextOf(LEntries[High(LEntries)], Result);
end;

function TPakFileSystem.ReadAllTexts(const AName: string): string;
var
  LText: string;
begin
  Result := '';
  for LText in Texts(AName) do
    Result := Result + LText + #13#10;
end;

function TPakFileSystem.GlobalHash: Cardinal;
begin
  Result := FIndex.GlobalHash;
end;

end.
