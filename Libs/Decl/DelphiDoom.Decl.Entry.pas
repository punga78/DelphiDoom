{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - TDeclEntry and TDeclFile                  }
{                                                                              }
{  Port of the declaration manager of Doom 3 (id Software, GPL v3):            }
{  framework\DeclManager.cpp (idDeclLocal, idDeclFile). Copyright (C)          }
{  1999-2011 id Software LLC, a ZeniMax Media company.                         }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Entry;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.Decl.Types,
  DelphiDoom.Decl.Intf, DelphiDoom.Decl.Source.Intf, DelphiDoom.Decl.FileScanner.Intf;

type
  TDeclFile = class;
  TDeclEntry = class;

  /// <summary>
  ///   What an entry and a file ask of the manager that owns them (idDeclManagerLocal, which the original reaches
  ///   through the global <c>declManagerLocal</c>). Internal: implemented by <c>TDeclManager</c>.
  /// </summary>
  IDeclHost = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0008}']
    /// <summary>The registered type; an <c>EDeclException</c> for a bad number</summary>
    function GetDeclTypeInfo(const AType: Integer): IDeclType;
    function GetNumDeclTypes: Integer;
    /// <summary>The type at the position of the type list, nil for a gap</summary>
    function GetDeclTypeAt(const AIndex: Integer): IDeclType;
    /// <summary>FindTypeWithoutParsing: finds or creates the entry, no parse</summary>
    function FindEntry(const AType: Integer; const AName: AnsiString; const AMakeDefault: Boolean): TDeclEntry;
    function GetImplicitFile: TDeclFile;
    function GetSource: IDeclSource;
    function GetLog: IIdLibLog;
    function GetFinder: IDeclFinder;
    procedure MediaPrint(const AMessage: AnsiString);
    procedure IncIndent;
    procedure DecIndent;
    /// <summary>Counts a nested <c>MakeDefault</c>; an <c>EDeclException</c> after 100 levels</summary>
    procedure EnterMakeDefault(const ADefaultText: AnsiString);
    procedure LeaveMakeDefault;
  end;

  /// <summary>
  ///   A file of declarations (idDeclFile): what was read, its time and checksum, the decls it defines.
  ///   Lives with <c>TDeclEntry</c> in this unit because each one reaches into the fields of the other,
  ///   as the friend classes of the original do.
  /// </summary>
  TDeclFile = class
  strict private
    FFileName: AnsiString;
    FDefaultType: Integer;
    FTimestamp: Int64;
    FChecksum: Cardinal;
    FFileSize: Integer;
    FNumLines: Integer;
    FDecls: TList<TDeclEntry>;
    [weak] FHost: IDeclHost;
    /// <summary>The scanner of the default type of this file, nil for the types read with the lexer of idLib</summary>
    function FindScanner: IDeclFileScanner;
    /// <summary>LoadAndParse for a type with its own syntax (<c>IDeclFileScanner</c>)</summary>
    function LoadWithScanner(const AScanner: IDeclFileScanner; const ABuffer: AnsiString): Cardinal;
  public
    /// <summary>The file of the implicit decls has the name "&lt;implicit file&gt;" and the type DECL_MAX_TYPES</summary>
    constructor Create(const AHost: IDeclHost; const AFileName: AnsiString; const ADefaultType: Integer);
    destructor Destroy; override;
    /// <summary>Reloads the file if its time changed, or always with <c>AForce</c></summary>
    procedure Reload(const AForce: Boolean);
    /// <summary>
    ///   Reads the file and finds every declaration in it; used for the first load and for reloads.
    ///   Returns the checksum of the file.
    /// </summary>
    function LoadAndParse: Cardinal;
    property FileName: AnsiString read FFileName;
    property DefaultType: Integer read FDefaultType;
    property Timestamp: Int64 read FTimestamp write FTimestamp;
    property Checksum: Cardinal read FChecksum write FChecksum;
    property FileSize: Integer read FFileSize write FFileSize;
    property NumLines: Integer read FNumLines;
    /// <summary>The decls defined in this file (not owned)</summary>
    property Decls: TList<TDeclEntry> read FDecls;
  end;

  /// <summary>
  ///   What the manager knows of one declaration (idDeclLocal): the text, where it came from, the state,
  ///   and the object of the type that parses it. Owned by the manager; no reference count.
  /// </summary>
  TDeclEntry = class(TObject, IInterface, IDeclBase)
  strict private
    [weak] FHost: IDeclHost;
    FSelf: IDecl;
    FName: AnsiString;
    FTextSource: AnsiString;
    FHasText: Boolean;
    FSourceFile: TDeclFile;
    FSourceTextOffset: Integer;
    FSourceTextLength: Integer;
    FSourceLine: Integer;
    FChecksum: Cardinal;
    FDeclType: Integer;
    FState: TDeclState;
    FIndex: Integer;
    FParsedOutsideLevelLoad: Boolean;
    FEverReferenced: Boolean;
    FReferencedThisLevel: Boolean;
    FRedefinedInReload: Boolean;
  public
    // IInterface without a count: the manager owns the entry
    function QueryInterface(const AIID: TGUID; out AObj): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  public
    constructor Create(const AHost: IDeclHost);
    /// <summary>idDeclLocal::AllocateSelf: makes the object of the type if there is none</summary>
    procedure AllocateSelf;
    /// <summary>After this a decl is usable: its text is parsed, or defaulted</summary>
    procedure ParseLocal;
    /// <summary>A MakeDefault that sets the state back to unparsed (the next find parses the real data again)</summary>
    procedure Purge;
    procedure SetTextLocal(const AText: AnsiString);
    /// <summary>The next find parses it; used by <c>FindType</c> to mark a reference</summary>
    procedure MarkReferenced(const AInsideLevelLoad: Boolean);
    function GetName: AnsiString;
    function GetDeclType: Integer;
    function GetState: TDeclState;
    function IsImplicit: Boolean;
    function IsValid: Boolean;
    procedure Invalidate;
    procedure Reload;
    procedure EnsureNotPurged;
    function GetIndex: Integer;
    function GetLineNum: Integer;
    function GetFileName: AnsiString;
    function GetText: AnsiString;
    function GetTextLength: Integer;
    procedure SetText(const AText: AnsiString);
    function ReplaceSourceFileText: Boolean;
    function SourceFileChanged: Boolean;
    procedure MakeDefault;
    function EverReferenced: Boolean;
    function SetDefaultText: Boolean;
    function DefaultDefinition: AnsiString;
    function Parse(const AText: AnsiString): Boolean;
    procedure FreeData;
    function Size: NativeInt;
    procedure List;
    procedure Print;
    function GetFinder: IDeclFinder;
    function GetLog: IIdLibLog;
    /// <summary>The object of the type, nil before <c>AllocateSelf</c></summary>
    property Decl: IDecl read FSelf;
    /// <summary>Releases the object (the manager is shutting down)</summary>
    procedure ReleaseDecl;
    property Name: AnsiString read FName write FName;
    property DeclType: Integer read FDeclType write FDeclType;
    property State: TDeclState read FState write FState;
    property Index: Integer read FIndex write FIndex;
    property HasText: Boolean read FHasText;
    property Checksum: Cardinal read FChecksum;
    property SourceFile: TDeclFile read FSourceFile write FSourceFile;
    property SourceTextOffset: Integer read FSourceTextOffset write FSourceTextOffset;
    property SourceTextLength: Integer read FSourceTextLength write FSourceTextLength;
    property SourceLine: Integer read FSourceLine write FSourceLine;
    property ParsedOutsideLevelLoad: Boolean read FParsedOutsideLevelLoad write FParsedOutsideLevelLoad;
    property ReferencedThisLevel: Boolean read FReferencedThisLevel write FReferencedThisLevel;
    property RedefinedInReload: Boolean read FRedefinedInReload write FRedefinedInReload;
    /// <summary>Drops the text (a generated default text is freed after the parse)</summary>
    procedure ClearText;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Lexer, DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Strings,
  DelphiDoom.IdLib.Hashing.Md5;

const
  SImplicitFileName = '<implicit file>';
  SCouldNotLoad = 'couldn''t load %s';
  SCouldNotParse = 'Couldn''t parse %s';

function TextChecksum(const AText: AnsiString): Cardinal;
begin
  Result := TIdMd5.BlockChecksum(PAnsiChar(AText)^, Length(AText));
end;

{ TDeclFile }

constructor TDeclFile.Create(const AHost: IDeclHost; const AFileName: AnsiString; const ADefaultType: Integer);
begin
  inherited Create;
  FHost := AHost;
  if AFileName = '' then
  begin
    FFileName := SImplicitFileName;
    FDefaultType := DECL_MAX_TYPES;
  end
  else
  begin
    FFileName := AFileName;
    FDefaultType := ADefaultType;
  end;
  FDecls := TList<TDeclEntry>.Create;
end;

destructor TDeclFile.Destroy;
begin
  FDecls.Free;
  FHost := nil;
  inherited Destroy;
end;

function TDeclFile.FindScanner: IDeclFileScanner;
var
  LType: IDeclType;
begin
  Result := nil;
  if (FDefaultType < 0) or (FDefaultType >= DECL_MAX_TYPES) then
    Exit;
  LType := FHost.GetDeclTypeAt(FDefaultType);
  if Assigned(LType) then
    Supports(LType, IDeclFileScanner, Result);
end;

function TDeclFile.LoadWithScanner(const AScanner: IDeclFileScanner; const ABuffer: AnsiString): Cardinal;
var
  LBlocks: TArray<TDeclScannedBlock>;
  LBlock: TDeclScannedBlock;
  LNumLines: Integer;
  LNewDecl, LDecl: TDeclEntry;
  LReparse: Boolean;
  LLog: IIdLibLog;
begin
  LLog := FHost.GetLog;
  for LDecl in FDecls do
    LDecl.RedefinedInReload := False;
  FChecksum := TextChecksum(ABuffer);
  FFileSize := Length(ABuffer);
  LBlocks := AScanner.ScanFile(ABuffer, FFileName, FDefaultType, LLog, LNumLines);
  for LBlock in LBlocks do
  begin
    LReparse := False;
    LNewDecl := FHost.FindEntry(LBlock.TypeId, LBlock.Name, False);
    if Assigned(LNewDecl) then
    begin
      if (LNewDecl.SourceFile <> Self) or LNewDecl.RedefinedInReload then
      begin
        if Assigned(LLog) then
          LLog.Warning(Format('file %s, line %d: %s ''%s'' previously defined at %s:%d',
            [string(FFileName), LBlock.Line, string(FHost.GetDeclTypeInfo(LBlock.TypeId).GetTypeName),
            string(LBlock.Name), string(LNewDecl.SourceFile.FileName), LNewDecl.SourceLine]));
        Continue;
      end;
      if LNewDecl.State <> dsUnparsed then
        LReparse := True;
    end
    else
    begin
      LNewDecl := FHost.FindEntry(LBlock.TypeId, LBlock.Name, True);
      FDecls.Add(LNewDecl);
    end;
    LNewDecl.RedefinedInReload := True;
    LNewDecl.ClearText;
    if LBlock.Text <> '' then
      LNewDecl.SetTextLocal(LBlock.Text)
    else
      LNewDecl.SetTextLocal(Copy(ABuffer, LBlock.Offset + 1, LBlock.Length));
    LNewDecl.SourceFile := Self;
    LNewDecl.SourceTextOffset := LBlock.Offset;
    LNewDecl.SourceTextLength := LBlock.Length;
    LNewDecl.SourceLine := LBlock.Line;
    LNewDecl.State := dsUnparsed;
    if LReparse then
      LNewDecl.ParseLocal;
  end;
  FNumLines := LNumLines;
  for LDecl in FDecls do
    if not LDecl.RedefinedInReload then
    begin
      LDecl.MakeDefault;
      LDecl.SourceTextOffset := LDecl.SourceFile.FileSize;
      LDecl.SourceTextLength := 0;
      LDecl.SourceLine := LDecl.SourceFile.NumLines;
    end;
  Result := FChecksum;
end;

procedure TDeclFile.Reload(const AForce: Boolean);
var
  LLength: Integer;
  LTimestamp: Int64;
begin
  // check for an unchanged timestamp
  if (not AForce) and (FTimestamp <> 0) then
    if FHost.GetSource.TryGetFileInfo(FFileName, LLength, LTimestamp) and (LTimestamp = FTimestamp) then
      Exit;
  LoadAndParse;
end;

function TDeclFile.LoadAndParse: Cardinal;
var
  LSource: TIdLexer;
  LToken: TIdToken;
  LBuffer: AnsiString;
  LIndex, LNumTypes, LStartMarker, LSourceLine, LSize: Integer;
  LIdentifiedType: Integer;
  LFound, LReparse: Boolean;
  LTypeInfo: IDeclType;
  LName: AnsiString;
  LNewDecl: TDeclEntry;
  LDecl: TDeclEntry;
  LScanner: IDeclFileScanner;
begin
  if not FHost.GetSource.TryReadFile(FFileName, LBuffer, FTimestamp) then
    raise EDeclException.CreateFmt(SCouldNotLoad, [string(FFileName)]);
  LScanner := FindScanner;
  if Assigned(LScanner) then
    Exit(LoadWithScanner(LScanner, LBuffer));
  LSource := TIdLexer.Create(0, FHost.GetLog);
  try
    if not LSource.LoadMemory(LBuffer, Length(LBuffer), FFileName) then
      raise EDeclException.CreateFmt(SCouldNotParse, [string(FFileName)]);

    // mark all the defs that were from the last reload of this file
    for LDecl in FDecls do
      LDecl.RedefinedInReload := False;

    LSource.Flags := DECL_LEXER_FLAGS;
    FChecksum := TextChecksum(LBuffer);
    FFileSize := Length(LBuffer);

    // scan through, identifying each individual declaration
    while True do
    begin
      LStartMarker := LSource.GetFileOffset;
      LSourceLine := LSource.LineNum;

      // parse the decl type name
      if not LSource.ReadToken(LToken) then
        Break;

      LIdentifiedType := DECL_MAX_TYPES;
      LFound := False;

      // get the decl type from the type name
      LNumTypes := FHost.GetNumDeclTypes;
      for LIndex := 0 to LNumTypes - 1 do
      begin
        LTypeInfo := FHost.GetDeclTypeAt(LIndex);
        if Assigned(LTypeInfo) and (TIdStrings.Icmp(LTypeInfo.GetTypeName, LToken.Text) = 0) then
        begin
          LIdentifiedType := LTypeInfo.GetTypeId;
          LFound := True;
          Break;
        end;
      end;

      if not LFound then
      begin
        if TIdStrings.Icmp(LToken.Text, '{') = 0 then
        begin
          // if we ever see an open brace, we somehow missed the [type] <name> prefix
          LSource.Warning('Missing decl name', []);
          LSource.SkipBracedSection(False);
          Continue;
        end
        else
        begin
          if FDefaultType = DECL_MAX_TYPES then
          begin
            LSource.Warning('No type', []);
            Continue;
          end;
          LSource.UnreadToken(LToken);
          // use the default type
          LIdentifiedType := FDefaultType;
        end;
      end;

      // now parse the name
      if not LSource.ReadToken(LToken) then
      begin
        LSource.Warning('Type without definition at end of file', []);
        Break;
      end;

      if TIdStrings.Icmp(LToken.Text, '{') = 0 then
      begin
        LSource.Warning('Missing decl name', []);
        LSource.SkipBracedSection(False);
        Continue;
      end;

      // export decls are only used by the model exporter, they are skipped here
      if LIdentifiedType = DECL_MODELEXPORT then
      begin
        LSource.SkipBracedSection;
        Continue;
      end;

      LName := LToken.Text;

      // make sure there's a '{'
      if not LSource.ReadToken(LToken) then
      begin
        LSource.Warning('Type without definition at end of file', []);
        Break;
      end;
      if not LToken.IsText('{') then
      begin
        LSource.Warning('Expecting ''{'' but found ''%s''', [string(LToken.Text)]);
        Continue;
      end;
      LSource.UnreadToken(LToken);

      // now take everything until a matched closing brace
      LSource.SkipBracedSection;
      LSize := LSource.GetFileOffset - LStartMarker;

      // look it up, possibly getting a newly created default decl
      LReparse := False;
      LNewDecl := FHost.FindEntry(LIdentifiedType, LName, False);
      if Assigned(LNewDecl) then
      begin
        // update the existing copy
        if (LNewDecl.SourceFile <> Self) or LNewDecl.RedefinedInReload then
        begin
          LSource.Warning('%s ''%s'' previously defined at %s:%d',
            [string(FHost.GetDeclTypeInfo(LIdentifiedType).GetTypeName), string(LName),
            string(LNewDecl.SourceFile.FileName), LNewDecl.SourceLine]);
          Continue;
        end;
        if LNewDecl.State <> dsUnparsed then
          LReparse := True;
      end
      else
      begin
        // allow it to be created as a default, then add it to the per-file list
        LNewDecl := FHost.FindEntry(LIdentifiedType, LName, True);
        FDecls.Add(LNewDecl);
      end;

      LNewDecl.RedefinedInReload := True;
      LNewDecl.ClearText;
      LNewDecl.SetTextLocal(LSource.GetBufferText(LStartMarker, LStartMarker + LSize));
      LNewDecl.SourceFile := Self;
      LNewDecl.SourceTextOffset := LStartMarker;
      LNewDecl.SourceTextLength := LSize;
      LNewDecl.SourceLine := LSourceLine;
      LNewDecl.State := dsUnparsed;

      // if it is currently in use, reparse it immediately
      if LReparse then
        LNewDecl.ParseLocal;
    end;

    FNumLines := LSource.LineNum;
  finally
    LSource.Free;
  end;

  // any defs that weren't redefinedInReload should now be defaulted
  for LDecl in FDecls do
    if not LDecl.RedefinedInReload then
    begin
      LDecl.MakeDefault;
      LDecl.SourceTextOffset := LDecl.SourceFile.FileSize;
      LDecl.SourceTextLength := 0;
      LDecl.SourceLine := LDecl.SourceFile.NumLines;
    end;

  Result := FChecksum;
end;

{ TDeclEntry }

constructor TDeclEntry.Create(const AHost: IDeclHost);
begin
  inherited Create;
  FHost := AHost;
  FName := 'unnamed';
  FDeclType := DECL_ENTITYDEF;
  FState := dsUnparsed;
end;

function TDeclEntry.QueryInterface(const AIID: TGUID; out AObj): HResult;
begin
  if GetInterface(AIID, AObj) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TDeclEntry._AddRef: Integer;
begin
  Result := -1;
end;

function TDeclEntry._Release: Integer;
begin
  Result := -1;
end;

procedure TDeclEntry.ReleaseDecl;
begin
  if Assigned(FSelf) then
  begin
    FSelf.FreeData;
    FSelf.SetBase(nil);
    FSelf := nil;
  end;
end;

procedure TDeclEntry.AllocateSelf;
begin
  if not Assigned(FSelf) then
  begin
    FSelf := FHost.GetDeclTypeInfo(FDeclType).CreateDecl;
    FSelf.SetBase(Self);
  end;
end;

function TDeclEntry.GetName: AnsiString;
begin
  Result := FName;
end;

function TDeclEntry.GetDeclType: Integer;
begin
  Result := FDeclType;
end;

function TDeclEntry.GetState: TDeclState;
begin
  Result := FState;
end;

function TDeclEntry.IsImplicit: Boolean;
begin
  Result := FSourceFile = FHost.GetImplicitFile;
end;

function TDeclEntry.IsValid: Boolean;
begin
  Result := FState <> dsUnparsed;
end;

procedure TDeclEntry.Invalidate;
begin
  FState := dsUnparsed;
end;

procedure TDeclEntry.EnsureNotPurged;
begin
  if FState = dsUnparsed then
    ParseLocal;
end;

function TDeclEntry.GetIndex: Integer;
begin
  Result := FIndex;
end;

function TDeclEntry.GetLineNum: Integer;
begin
  Result := FSourceLine;
end;

function TDeclEntry.GetFileName: AnsiString;
begin
  if Assigned(FSourceFile) then
    Result := FSourceFile.FileName
  else
    Result := '*invalid*';
end;

function TDeclEntry.Size: NativeInt;
begin
  Result := SizeOf(TDeclEntry) + Length(FName);
end;

function TDeclEntry.GetText: AnsiString;
begin
  Result := FTextSource;
end;

function TDeclEntry.GetTextLength: Integer;
begin
  Result := Length(FTextSource);
end;

procedure TDeclEntry.SetText(const AText: AnsiString);
begin
  SetTextLocal(AText);
end;

procedure TDeclEntry.SetTextLocal(const AText: AnsiString);
begin
  FChecksum := TextChecksum(AText);
  FTextSource := AText;
  FHasText := True;
end;

procedure TDeclEntry.ClearText;
begin
  FTextSource := '';
  FHasText := False;
end;

function TDeclEntry.ReplaceSourceFileText: Boolean;
var
  LBuffer, LNew, LDeclText: AnsiString;
  LTimestamp: Int64;
  LLength: Integer;
  LDecl: TDeclEntry;
  LLog: IIdLibLog;
begin
  Result := False;
  LLog := FHost.GetLog;
  if Assigned(LLog) then
    LLog.Printf(Format('Writing ''%s'' to ''%s''...'#10, [string(FName), string(GetFileName)]));

  if FSourceFile = FHost.GetImplicitFile then
  begin
    if Assigned(LLog) then
      LLog.Warning(Format('Can''t save implicit declaration %s.', [string(FName)]));
    Exit;
  end;

  LBuffer := '';
  // read original file
  if FSourceFile.FileSize <> 0 then
  begin
    if not FHost.GetSource.TryReadFile(GetFileName, LBuffer, LTimestamp) then
    begin
      if Assigned(LLog) then
        LLog.Warning(Format('Couldn''t open %s for reading.', [string(GetFileName)]));
      Exit;
    end;
    if (Length(LBuffer) <> FSourceFile.FileSize) or (LTimestamp <> FSourceFile.Timestamp) or
      (TextChecksum(LBuffer) <> FSourceFile.Checksum) then
    begin
      if Assigned(LLog) then
        LLog.Warning(Format('The file %s has been modified outside of the engine.', [string(GetFileName)]));
      Exit;
    end;
  end;

  // insert new text
  LDeclText := GetText;
  LNew := Copy(LBuffer, 1, FSourceTextOffset) + LDeclText +
    Copy(LBuffer, FSourceTextOffset + FSourceTextLength + 1, MaxInt);

  // write out new file
  if not FHost.GetSource.WriteFile(GetFileName, LNew) then
  begin
    if Assigned(LLog) then
      LLog.Warning(Format('Couldn''t open %s for writing.', [string(GetFileName)]));
    Exit;
  end;

  // set new file size, checksum and timestamp
  FSourceFile.FileSize := Length(LNew);
  FSourceFile.Checksum := TextChecksum(LNew);
  FHost.GetSource.TryGetFileInfo(GetFileName, LLength, LTimestamp);
  FSourceFile.Timestamp := LTimestamp;

  // move all decls in the same file
  for LDecl in FSourceFile.Decls do
    if LDecl.SourceTextOffset > FSourceTextOffset then
      LDecl.SourceTextOffset := LDecl.SourceTextOffset + GetTextLength - FSourceTextLength;

  // set new size of text in source file
  FSourceTextLength := GetTextLength;
  Result := True;
end;

function TDeclEntry.SourceFileChanged: Boolean;
var
  LLength: Integer;
  LTimestamp: Int64;
begin
  if FSourceFile.FileSize <= 0 then
    Exit(False);
  if not FHost.GetSource.TryGetFileInfo(GetFileName, LLength, LTimestamp) then
    Exit(True);
  Result := (LLength <> FSourceFile.FileSize) or (LTimestamp <> FSourceFile.Timestamp);
end;

procedure TDeclEntry.MakeDefault;
var
  LDefaultText: AnsiString;
begin
  FHost.MediaPrint('DEFAULTED'#10);
  FState := dsDefaulted;
  AllocateSelf;
  LDefaultText := FSelf.DefaultDefinition;

  // a parse error inside a DefaultDefinition() string could cause an infinite loop, but normal default
  // definitions could still reference other default definitions, so the host counts the depth
  FHost.EnterMakeDefault(LDefaultText);
  try
    // always free data before parsing
    FSelf.FreeData;
    FSelf.Parse(LDefaultText);
  finally
    FHost.LeaveMakeDefault;
  end;
end;

function TDeclEntry.EverReferenced: Boolean;
begin
  Result := FEverReferenced;
end;

procedure TDeclEntry.MarkReferenced(const AInsideLevelLoad: Boolean);
begin
  FReferencedThisLevel := True;
  FEverReferenced := True;
  if AInsideLevelLoad then
    FParsedOutsideLevelLoad := False;
end;

function TDeclEntry.SetDefaultText: Boolean;
begin
  Result := False;
end;

function TDeclEntry.DefaultDefinition: AnsiString;
begin
  Result := '{ }';
end;

function TDeclEntry.Parse(const AText: AnsiString): Boolean;
var
  LSource: TIdLexer;
begin
  LSource := TIdLexer.Create(0, FHost.GetLog);
  try
    LSource.LoadMemory(AText, Length(AText), GetFileName, GetLineNum);
    LSource.Flags := DECL_LEXER_FLAGS;
    LSource.SkipUntilString('{');
    LSource.SkipBracedSection(False);
  finally
    LSource.Free;
  end;
  Result := True;
end;

procedure TDeclEntry.FreeData;
begin
end;

procedure TDeclEntry.List;
var
  LLog: IIdLibLog;
begin
  LLog := FHost.GetLog;
  if Assigned(LLog) then
    LLog.Printf(string(FName) + #10);
end;

procedure TDeclEntry.Print;
begin
end;

function TDeclEntry.GetFinder: IDeclFinder;
begin
  Result := FHost.GetFinder;
end;

function TDeclEntry.GetLog: IIdLibLog;
begin
  Result := FHost.GetLog;
end;

procedure TDeclEntry.Reload;
begin
  FSourceFile.Reload(False);
end;

procedure TDeclEntry.ParseLocal;
var
  LGeneratedDefaultText: Boolean;
begin
  LGeneratedDefaultText := False;
  AllocateSelf;

  // always free data before parsing
  FSelf.FreeData;

  FHost.MediaPrint(AnsiString(Format('parsing %s %s'#10,
    [string(FHost.GetDeclTypeInfo(FDeclType).GetTypeName), string(FName)])));

  // if no text source try to generate default text
  if not FHasText then
    LGeneratedDefaultText := FSelf.SetDefaultText;

  // indent for DEFAULTED or media file references
  FHost.IncIndent;
  try
    // no text immediately causes a MakeDefault()
    if not FHasText then
    begin
      MakeDefault;
      Exit;
    end;

    FState := dsParsed;

    // parse
    FSelf.Parse(GetText);

    // free generated text
    if LGeneratedDefaultText then
      ClearText;
  finally
    FHost.DecIndent;
  end;
end;

procedure TDeclEntry.Purge;
begin
  // never purge things that were referenced outside level load, like the console and menu graphics
  if FParsedOutsideLevelLoad then
    Exit;

  FReferencedThisLevel := False;
  MakeDefault;

  // the next Find() for this will re-parse the real data
  FState := dsUnparsed;
end;

end.
