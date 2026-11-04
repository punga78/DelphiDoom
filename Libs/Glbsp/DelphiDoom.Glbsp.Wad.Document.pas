{******************************************************************************}
{                                                                              }
{  DelphiDoom: glbsp - WAD in memory: read, edit and write                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Port of wad.c of glBSP 2.24 (C) 2000-2007 Andrew Apted                      }
{  Based on 'BSP 2.3' by Colin Reed, Lee Killough and others.                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Glbsp.Wad.Document;

interface

uses
  System.Classes,
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.Glbsp.Wad.Lump,
  DelphiDoom.Glbsp.Wad.Types;

type
  /// <summary>
  ///   A WAD loaded in memory. Reads the directory, marks the levels, lets
  ///   the node builder add the (GL) lumps of a level and writes the result
  /// </summary>
  /// <remarks>
  ///   Unlike the C original it has no global state and no files: it works on
  ///   streams that the caller owns. When lumps are not loaded (ALoadAll
  ///   False) the input stream must stay alive until WriteToStream returns,
  ///   because the lumps marked LUMP_COPY_ME are copied from it.
  ///   Messages that glbsp prints as warnings are collected in Warnings
  /// </remarks>
  TGlbspWad = class
  private
    FKind: TGlbspWadKind;
    FNumEntries: Integer;
    FDirStart: Integer;
    FDirectory: TObjectList<TGlbspLump>;
    FCurrentLevel: TGlbspLump;
    FLevelNames: TStringList;
    FWarnings: TStringList;
    FInput: TStream;
    FLoadAll: Boolean;
    FGwaMode: Boolean;
    function CheckLevelName(const AName: AnsiString): Boolean;
    function CheckGLLumpName(const AName: AnsiString): Boolean;
    procedure DetermineLevelNames;
    procedure ProcessDirectoryEntry(const ALump: TGlbspLump);
    procedure ReadHeader(const AStream: TStream);
    procedure ReadDirectory;
    procedure ReadLumpData(const ALump: TGlbspLump);
    function ReadAllLumps: Integer;
    procedure RecomputeDirectory;
    procedure WriteLumpData(const AOutput: TStream; const ALump: TGlbspLump);
    function WriteAllLumps(const AOutput: TStream): Integer;
    function WriteDirectory(const AOutput: TStream): Integer;
    procedure WriteDirectoryEntry(const AOutput: TStream; const ALump: TGlbspLump);
    function CreateGLMarker: TGlbspLump;
    function FindOrCreateChild(const AChildren: TObjectList<TGlbspLump>;
      const AName: AnsiString): TGlbspLump;
    function GLLevel: TGlbspLump;
    procedure Warn(const AMessage: string);
    class function AlignLength(const ALength: Integer): Integer; static;
    class function LumpNameToString(const AName: array of AnsiChar): AnsiString; static;
  public
    constructor Create;
    destructor Destroy; override;

    /// <summary>
    ///   Reads the whole WAD from AStream. With ALoadAll False only the
    ///   lumps of the levels are loaded and the others are copied on write.
    ///   AGwaMode marks every lump of the input as not to be written (the
    ///   output holds only what the node builder creates)
    /// </summary>
    /// <exception cref="EGlbspWadException">bad magic or truncated header</exception>
    procedure ReadFromStream(const AStream: TStream; const ALoadAll,
      AGwaMode: Boolean);

    /// <summary>
    ///   Writes the WAD to AOutput; in GWA mode the kind becomes PWAD
    /// </summary>
    procedure WriteToStream(const AOutput: TStream);

    /// <summary>Number of normal levels (the GL levels are not counted)</summary>
    function CountLevels: Integer;

    /// <summary>
    ///   Moves CurrentLevel to the next normal level (the first one right
    ///   after ReadFromStream). False when there are no more levels
    /// </summary>
    function FindNextLevel: Boolean;

    /// <summary>Name of the current level</summary>
    function GetLevelName: AnsiString;

    /// <summary>
    ///   Lump of the current level with that name; nil if it does not exist
    /// </summary>
    function FindLevelLump(const AName: AnsiString): TGlbspLump;

    /// <summary>
    ///   Creates a lump in the current level, or empties it if it exists
    /// </summary>
    function CreateLevelLump(const AName: AnsiString): TGlbspLump;

    /// <summary>
    ///   Same as CreateLevelLump for the GL level of the current level,
    ///   created together with its marker when it is missing
    /// </summary>
    function CreateGLLump(const AName: AnsiString): TGlbspLump;

    /// <summary>
    ///   Adds the line "AKeyword=AValue" to the marker of the GL level
    /// </summary>
    procedure AddGLTextLine(const AKeyword, AValue: AnsiString);

    procedure MarkSoftFailure(const ASoft: Integer);
    procedure MarkHardFailure(const AHard: Integer);
    procedure MarkV5Switch(const AV5: Integer);
    procedure MarkZDSwitch;

    property Kind: TGlbspWadKind read FKind;
    property NumEntries: Integer read FNumEntries;
    property DirStart: Integer read FDirStart;
    /// <summary>Directory in the order it is written; the list owns it</summary>
    property Directory: TObjectList<TGlbspLump> read FDirectory;
    property CurrentLevel: TGlbspLump read FCurrentLevel write FCurrentLevel;
    property LevelNames: TStringList read FLevelNames;
    property Warnings: TStringList read FWarnings;
  end;

implementation

const
  LEVEL_LUMPS: array[0..11] of AnsiString = (
    'THINGS', 'LINEDEFS', 'SIDEDEFS', 'VERTEXES', 'SEGS', 'SSECTORS', 'NODES',
    'SECTORS', 'REJECT', 'BLOCKMAP', 'BEHAVIOR', 'SCRIPTS');

  GL_LUMPS: array[0..4] of AnsiString = (
    'GL_VERT', 'GL_SEGS', 'GL_SSECT', 'GL_NODES', 'GL_PVS');

  IWAD_MAGIC: array[0..3] of AnsiChar = 'IWAD';
  PWAD_MAGIC: array[0..3] of AnsiChar = 'PWAD';

  // Index (1..12) of the last lump that decides a level name: SECTORS
  LAST_LEVEL_DEFINING_LUMP = 8;

  SBadHeader = 'Trouble reading wad header';
  SBadMagic = 'The stream does not appear to be a wad file (bad magic)';
  SBadDirectory = 'Trouble reading wad directory';
  SNoCurrentLevel = 'GetLevelName: no current level';
  SReadConsistency = 'Read directory count consistency failure (%d,%d)';
  SWriteConsistency = 'Write directory count consistency failure (%d,%d,%d)';

type
  TLumpNames = array of AnsiString;

function IndexOfLevelLump(const AName: AnsiString): Integer;
var
  LIndex: Integer;
begin
  for LIndex := Low(LEVEL_LUMPS) to High(LEVEL_LUMPS) do
  begin
    if LEVEL_LUMPS[LIndex] = AName then
      Exit(LIndex + 1);
  end;
  Result := 0;
end;

procedure SortChildren(const AChildren: TObjectList<TGlbspLump>;
  const ANames: array of AnsiString);
var
  LNameIndex: Integer;
  LLumpIndex: Integer;
  LLump: TGlbspLump;
begin
  // For each name, going backwards, the first lump with that name moves to
  // the head of the list: this leaves the known lumps in the order of ANames
  for LNameIndex := High(ANames) downto Low(ANames) do
  begin
    for LLumpIndex := 0 to AChildren.Count - 1 do
    begin
      if AChildren[LLumpIndex].Name <> ANames[LNameIndex] then
        Continue;
      LLump := AChildren.Extract(AChildren[LLumpIndex]);
      AChildren.Insert(0, LLump);
      Break;
    end;
  end;
end;

{ TGlbspWad }

constructor TGlbspWad.Create;
begin
  inherited Create;
  FDirectory := TObjectList<TGlbspLump>.Create(True);
  FLevelNames := TStringList.Create;
  FLevelNames.CaseSensitive := True;
  FWarnings := TStringList.Create;
end;

destructor TGlbspWad.Destroy;
begin
  FWarnings.Free;
  FLevelNames.Free;
  FDirectory.Free;
  inherited Destroy;
end;

class function TGlbspWad.AlignLength(const ALength: Integer): Integer;
begin
  Result := ((ALength + 3) div 4) * 4;
end;

class function TGlbspWad.LumpNameToString(const AName: array of AnsiChar): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := Low(AName) to High(AName) do
  begin
    if AName[LIndex] = #0 then
      Break;
    Result := Result + AName[LIndex];
  end;
end;

procedure TGlbspWad.Warn(const AMessage: string);
begin
  FWarnings.Add(AMessage);
end;

function TGlbspWad.CheckLevelName(const AName: AnsiString): Boolean;
begin
  Result := FLevelNames.IndexOf(string(AName)) >= 0;
end;

function TGlbspWad.CheckGLLumpName(const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  if Copy(AName, 1, 3) <> 'GL_' then
    Exit;
  for LIndex := Low(GL_LUMPS) to High(GL_LUMPS) do
  begin
    if GL_LUMPS[LIndex] = AName then
      Exit(True);
  end;
  Result := CheckLevelName(Copy(AName, 4, MaxInt));
end;

procedure TGlbspWad.ReadHeader(const AStream: TStream);
var
  LHeader: TRawWadHeader;
begin
  if AStream.Read(LHeader, SizeOf(LHeader)) <> SizeOf(LHeader) then
    raise EGlbspWadException.Create(SBadHeader);

  if not ((LHeader.MagicType[0] in ['I', 'P']) and (LHeader.MagicType[1] = 'W') and
    (LHeader.MagicType[2] = 'A') and (LHeader.MagicType[3] = 'D')) then
    raise EGlbspWadException.Create(SBadMagic);

  if LHeader.MagicType[0] = 'I' then
    FKind := wkIWad
  else
    FKind := wkPWad;
  FNumEntries := LHeader.NumEntries;
  FDirStart := LHeader.DirStart;
end;

procedure TGlbspWad.DetermineLevelNames;
var
  LIndex: Integer;
  LNext: Integer;
  LCount: Integer;
  LMatched: Integer;
  LLumpIndex: Integer;
  LName: AnsiString;
begin
  for LIndex := 0 to FDirectory.Count - 1 do
  begin
    LName := FDirectory[LIndex].Name;
    // Known lumps are never valid level names
    if IndexOfLevelLump(LName) <> 0 then
      Continue;

    // The next four lumps must be level lumps up to SECTORS, with no repeats
    LMatched := 0;
    LCount := 0;
    LNext := LIndex + 1;
    while (LCount < 4) and (LNext < FDirectory.Count) do
    begin
      LLumpIndex := IndexOfLevelLump(FDirectory[LNext].Name);
      if (LLumpIndex = 0) or (LLumpIndex > LAST_LEVEL_DEFINING_LUMP) or
        ((LMatched and (1 shl LLumpIndex)) <> 0) then
        Break;
      LMatched := LMatched or (1 shl LLumpIndex);
      Inc(LCount);
      Inc(LNext);
    end;
    if LCount <> 4 then
      Continue;

    if CheckLevelName(LName) then
    begin
      Warn(Format('Level name ''%s'' found twice in wad - Skipped', [string(LName)]));
      Continue;
    end;
    if Length(LName) > 5 then
      Warn(Format('Long level name ''%s'' found in wad', [string(LName)]));

    FLevelNames.Add(string(LName));
  end;
end;

procedure TGlbspWad.ProcessDirectoryEntry(const ALump: TGlbspLump);
begin
  // Previous GL lumps are discarded
  if CheckGLLumpName(ALump.Name) then
  begin
    ALump.Free;
    Dec(FNumEntries);
    Exit;
  end;

  if FGwaMode then
    ALump.Flags := ALump.Flags or LUMP_IGNORE_ME;

  // Level marker: starts a new level (it can have data in Hexen)
  if CheckLevelName(ALump.Name) then
  begin
    if FLoadAll then
      ALump.Flags := ALump.Flags or LUMP_READ_ME
    else
      ALump.Flags := ALump.Flags or LUMP_COPY_ME;
    ALump.AttachLevelInfo(0);
    FCurrentLevel := ALump;
    FDirectory.Add(ALump);
    Exit;
  end;

  // Level lumps are chained to the level, in reverse order
  if Assigned(FCurrentLevel) then
  begin
    if IndexOfLevelLump(ALump.Name) <> 0 then
    begin
      if Assigned(FindLevelLump(ALump.Name)) then
      begin
        Warn(Format('Duplicate entry ''%s'' ignored in %s',
          [string(ALump.Name), string(FCurrentLevel.Name)]));
        ALump.Free;
        Dec(FNumEntries);
        Exit;
      end;
      ALump.Flags := ALump.Flags or LUMP_READ_ME;
      FCurrentLevel.LevelInfo.Children.Insert(0, ALump);
      Exit;
    end;
    // A non level lump ends the level
    FCurrentLevel := nil;
  end;

  if IndexOfLevelLump(ALump.Name) <> 0 then
    Warn(Format('Level lump ''%s'' found outside any level', [string(ALump.Name)]));

  if FLoadAll then
    ALump.Flags := ALump.Flags or LUMP_READ_ME
  else
    ALump.Flags := ALump.Flags or LUMP_COPY_ME;
  FDirectory.Add(ALump);
end;

procedure TGlbspWad.ReadDirectory;
var
  LIndex: Integer;
  LEntry: TRawWadEntry;
  LLump: TGlbspLump;
  LRead: TObjectList<TGlbspLump>;
  LTotal: Integer;
begin
  LTotal := FNumEntries;
  FInput.Position := FDirStart;

  // First pass: the directory as it is on disk
  for LIndex := 0 to LTotal - 1 do
  begin
    if FInput.Read(LEntry, SizeOf(LEntry)) <> SizeOf(LEntry) then
      raise EGlbspWadException.Create(SBadDirectory);
    LLump := TGlbspLump.Create(LumpNameToString(LEntry.Name));
    LLump.Start := LEntry.Start;
    LLump.Length := LEntry.Length;
    FDirectory.Add(LLump);
  end;

  DetermineLevelNames;

  // Second pass: every lump is processed in turn and linked where it belongs
  LRead := TObjectList<TGlbspLump>.Create(False);
  try
    for LIndex := 0 to FDirectory.Count - 1 do
      LRead.Add(FDirectory[LIndex]);
    FDirectory.OwnsObjects := False;
    FDirectory.Clear;
    FDirectory.OwnsObjects := True;
    FCurrentLevel := nil;
    for LIndex := 0 to LRead.Count - 1 do
      ProcessDirectoryEntry(LRead[LIndex]);
  finally
    LRead.Free;
  end;
end;

procedure TGlbspWad.ReadLumpData(const ALump: TGlbspLump);
var
  LData: TBytes;
begin
  if ALump.Length = 0 then
    Exit;
  SetLength(LData, ALump.Length);
  FInput.Position := ALump.Start;
  if FInput.Read(LData[0], ALump.Length) <> ALump.Length then
  begin
    if Assigned(FCurrentLevel) then
      Warn(Format('Trouble reading lump ''%s'' in %s',
        [string(ALump.Name), string(FCurrentLevel.Name)]))
    else
      Warn(Format('Trouble reading lump ''%s''', [string(ALump.Name)]));
  end;
  ALump.Data := LData;
  ALump.Flags := ALump.Flags and not LUMP_READ_ME;
end;

function TGlbspWad.ReadAllLumps: Integer;
var
  LLump: TGlbspLump;
  LChild: TGlbspLump;
begin
  Result := 0;
  for LLump in FDirectory do
  begin
    Inc(Result);
    if (LLump.Flags and LUMP_READ_ME) <> 0 then
      ReadLumpData(LLump);

    if Assigned(LLump.LevelInfo) and ((LLump.LevelInfo.Flags and LEVEL_IS_GL) = 0) then
    begin
      for LChild in LLump.LevelInfo.Children do
      begin
        Inc(Result);
        if (LChild.Flags and LUMP_READ_ME) <> 0 then
          ReadLumpData(LChild);
      end;
    end;
  end;
end;

procedure TGlbspWad.ReadFromStream(const AStream: TStream; const ALoadAll,
  AGwaMode: Boolean);
var
  LCheck: Integer;
begin
  FDirectory.Clear;
  FLevelNames.Clear;
  FWarnings.Clear;
  FCurrentLevel := nil;
  FInput := AStream;
  FLoadAll := ALoadAll;
  FGwaMode := AGwaMode;

  AStream.Position := 0;
  ReadHeader(AStream);
  ReadDirectory;

  LCheck := ReadAllLumps;
  if LCheck <> FNumEntries then
    raise EGlbspWadException.CreateFmt(SReadConsistency, [LCheck, FNumEntries]);

  FCurrentLevel := nil;
end;

procedure TGlbspWad.RecomputeDirectory;
var
  LLump: TGlbspLump;
  LChild: TGlbspLump;
begin
  FNumEntries := 0;
  FDirStart := WAD_HEADER_SIZE;

  for LLump in FDirectory do
  begin
    if (LLump.Flags and LUMP_IGNORE_ME) <> 0 then
      Continue;

    LLump.NewStart := FDirStart;
    Inc(FDirStart, AlignLength(LLump.Length));
    Inc(FNumEntries);

    if Assigned(LLump.LevelInfo) then
    begin
      if (LLump.LevelInfo.Flags and LEVEL_IS_GL) <> 0 then
        SortChildren(LLump.LevelInfo.Children, GL_LUMPS)
      else
        SortChildren(LLump.LevelInfo.Children, LEVEL_LUMPS);

      for LChild in LLump.LevelInfo.Children do
      begin
        if (LChild.Flags and LUMP_IGNORE_ME) <> 0 then
          Continue;
        LChild.NewStart := FDirStart;
        Inc(FDirStart, AlignLength(LChild.Length));
        Inc(FNumEntries);
      end;
    end;
  end;
end;

procedure TGlbspWad.WriteLumpData(const AOutput: TStream; const ALump: TGlbspLump);
const
  FILLER: array[0..3] of Byte = (0, 0, 0, 0);
var
  LAlignSize: Integer;
  LData: TBytes;
begin
  if AOutput.Position <> ALump.NewStart then
    Warn(Format('Consistency failure writing %s (%08X, %08X)',
      [string(ALump.Name), AOutput.Position, ALump.NewStart]));

  if ALump.Length = 0 then
    Exit;

  if (ALump.Flags and LUMP_COPY_ME) <> 0 then
  begin
    SetLength(LData, ALump.Length);
    FInput.Position := ALump.Start;
    if FInput.Read(LData[0], ALump.Length) <> ALump.Length then
      Warn(Format('Trouble reading lump %s to copy', [string(ALump.Name)]));
  end
  else
    LData := ALump.Data;

  AOutput.WriteBuffer(LData[0], ALump.Length);

  LAlignSize := AlignLength(ALump.Length) - ALump.Length;
  if LAlignSize > 0 then
    AOutput.WriteBuffer(FILLER[0], LAlignSize);

  ALump.Data := nil;
end;

function TGlbspWad.WriteAllLumps(const AOutput: TStream): Integer;
var
  LLump: TGlbspLump;
  LChild: TGlbspLump;
begin
  Result := 0;
  for LLump in FDirectory do
  begin
    if (LLump.Flags and LUMP_IGNORE_ME) <> 0 then
      Continue;

    WriteLumpData(AOutput, LLump);
    Inc(Result);

    if Assigned(LLump.LevelInfo) then
    begin
      for LChild in LLump.LevelInfo.Children do
      begin
        if (LChild.Flags and LUMP_IGNORE_ME) <> 0 then
          Continue;
        WriteLumpData(AOutput, LChild);
        Inc(Result);
      end;
    end;
  end;
end;

procedure TGlbspWad.WriteDirectoryEntry(const AOutput: TStream;
  const ALump: TGlbspLump);
var
  LEntry: TRawWadEntry;
  LIndex: Integer;
begin
  FillChar(LEntry, SizeOf(LEntry), 0);
  for LIndex := 1 to Length(ALump.Name) do
  begin
    if LIndex > WAD_LUMP_NAME_SIZE then
      Break;
    LEntry.Name[LIndex - 1] := ALump.Name[LIndex];
  end;
  LEntry.Start := ALump.NewStart;
  LEntry.Length := ALump.Length;
  AOutput.WriteBuffer(LEntry, SizeOf(LEntry));
end;

function TGlbspWad.WriteDirectory(const AOutput: TStream): Integer;
var
  LLump: TGlbspLump;
  LChild: TGlbspLump;
begin
  Result := 0;
  if AOutput.Position <> FDirStart then
    Warn(Format('Consistency failure writing lump directory (%08X,%08X)',
      [AOutput.Position, FDirStart]));

  for LLump in FDirectory do
  begin
    if (LLump.Flags and LUMP_IGNORE_ME) <> 0 then
      Continue;

    WriteDirectoryEntry(AOutput, LLump);
    Inc(Result);

    // As in glbsp, the children follow the flags of their level marker
    if Assigned(LLump.LevelInfo) then
    begin
      for LChild in LLump.LevelInfo.Children do
      begin
        WriteDirectoryEntry(AOutput, LChild);
        Inc(Result);
      end;
    end;
  end;
end;

procedure TGlbspWad.WriteToStream(const AOutput: TStream);
var
  LHeader: TRawWadHeader;
  LCheck1: Integer;
  LCheck2: Integer;
begin
  if FGwaMode then
    FKind := wkPWad;

  RecomputeDirectory;

  if FKind = wkIWad then
    LHeader.MagicType := IWAD_MAGIC
  else
    LHeader.MagicType := PWAD_MAGIC;
  LHeader.NumEntries := FNumEntries;
  LHeader.DirStart := FDirStart;
  AOutput.WriteBuffer(LHeader, SizeOf(LHeader));

  LCheck1 := WriteAllLumps(AOutput);
  LCheck2 := WriteDirectory(AOutput);

  if (LCheck1 <> FNumEntries) or (LCheck2 <> FNumEntries) then
    raise EGlbspWadException.CreateFmt(SWriteConsistency,
      [LCheck1, LCheck2, FNumEntries]);
end;

function TGlbspWad.CreateGLMarker: TGlbspLump;
var
  LLevel: TGlbspLump;
  LLongName: Boolean;
  LName: AnsiString;
begin
  LLevel := FCurrentLevel;
  LLongName := Length(LLevel.Name) > 5;
  if LLongName then
    LName := 'GL_LEVEL'
  else
    LName := 'GL_' + LLevel.Name;

  Result := TGlbspLump.Create(LName);
  Result.AttachLevelInfo(LEVEL_IS_GL);
  // The marker goes right after the level it belongs to
  FDirectory.Insert(FDirectory.IndexOf(LLevel) + 1, Result);
  LLevel.LevelInfo.Buddy := Result;

  if LLongName then
    AddGLTextLine('LEVEL', LLevel.Name);
end;

function TGlbspWad.GLLevel: TGlbspLump;
begin
  if not Assigned(FCurrentLevel.LevelInfo.Buddy) then
    CreateGLMarker;
  Result := FCurrentLevel.LevelInfo.Buddy;
end;

function TGlbspWad.FindOrCreateChild(const AChildren: TObjectList<TGlbspLump>;
  const AName: AnsiString): TGlbspLump;
var
  LLump: TGlbspLump;
begin
  for LLump in AChildren do
  begin
    if LLump.Name = AName then
    begin
      LLump.Truncate;
      Exit(LLump);
    end;
  end;

  // New lumps go to the head of the list, as in glbsp
  Result := TGlbspLump.Create(AName);
  AChildren.Insert(0, Result);
end;

function TGlbspWad.CreateLevelLump(const AName: AnsiString): TGlbspLump;
begin
  Result := FindOrCreateChild(FCurrentLevel.LevelInfo.Children, AName);
end;

function TGlbspWad.CreateGLLump(const AName: AnsiString): TGlbspLump;
begin
  Result := FindOrCreateChild(GLLevel.LevelInfo.Children, AName);
end;

procedure TGlbspWad.AddGLTextLine(const AKeyword, AValue: AnsiString);
var
  LMarker: TGlbspLump;
begin
  LMarker := GLLevel;
  LMarker.Append(AKeyword);
  LMarker.Append('=');
  LMarker.Append(AValue);
  LMarker.Append(#10);
end;

function TGlbspWad.CountLevels: Integer;
var
  LLump: TGlbspLump;
begin
  Result := 0;
  for LLump in FDirectory do
  begin
    if Assigned(LLump.LevelInfo) and ((LLump.LevelInfo.Flags and LEVEL_IS_GL) = 0) then
      Inc(Result);
  end;
end;

function TGlbspWad.FindNextLevel: Boolean;
var
  LIndex: Integer;
begin
  if Assigned(FCurrentLevel) then
    LIndex := FDirectory.IndexOf(FCurrentLevel) + 1
  else
    LIndex := 0;

  while (LIndex < FDirectory.Count) and
    not (Assigned(FDirectory[LIndex].LevelInfo) and
    ((FDirectory[LIndex].LevelInfo.Flags and LEVEL_IS_GL) = 0)) do
    Inc(LIndex);

  if LIndex < FDirectory.Count then
    FCurrentLevel := FDirectory[LIndex]
  else
    FCurrentLevel := nil;
  Result := Assigned(FCurrentLevel);
end;

function TGlbspWad.GetLevelName: AnsiString;
begin
  if not Assigned(FCurrentLevel) then
    raise EGlbspWadException.Create(SNoCurrentLevel);
  Result := FCurrentLevel.Name;
end;

function TGlbspWad.FindLevelLump(const AName: AnsiString): TGlbspLump;
var
  LLump: TGlbspLump;
begin
  for LLump in FCurrentLevel.LevelInfo.Children do
  begin
    if LLump.Name = AName then
      Exit(LLump);
  end;
  Result := nil;
end;

procedure TGlbspWad.MarkSoftFailure(const ASoft: Integer);
begin
  with FCurrentLevel.LevelInfo do
    SoftLimit := SoftLimit or ASoft;
end;

procedure TGlbspWad.MarkHardFailure(const AHard: Integer);
begin
  with FCurrentLevel.LevelInfo do
    HardLimit := HardLimit or AHard;
end;

procedure TGlbspWad.MarkV5Switch(const AV5: Integer);
begin
  with FCurrentLevel.LevelInfo do
    V5Switch := V5Switch or AV5;
end;

procedure TGlbspWad.MarkZDSwitch;
begin
  with FCurrentLevel.LevelInfo do
  begin
    V5Switch := V5Switch or LIMIT_ZDBSP;
    SoftLimit := SoftLimit and not LIMIT_VERTEXES;
    HardLimit := HardLimit and not LIMIT_VERTEXES;
  end;
end;

end.
