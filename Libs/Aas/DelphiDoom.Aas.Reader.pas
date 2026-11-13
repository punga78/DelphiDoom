{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - reading an AAS file (AAS_LoadAASFile)             }
{                                                                              }
{  Port of AAS_LoadAASFile and AAS_LoadAASLump of be_aas_file.c. Based on the  }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id   }
{  Software, Inc. This unit is derived from the Quake III Arena source code    }
{  and is therefore available under the GNU General Public License, version 2  }
{  or (at your option) any later version.                                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Reader;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, DelphiDoom.MathCore.Types, DelphiDoom.BotAi.Import.Intf, DelphiDoom.Aas.Types,
  DelphiDoom.Aas.Intf;

type
  /// <summary>
  ///   Reads a .aas file of Quake III Arena (version 4 or 5). The checks are those of the
  ///   original: identifier, version, checksum of the BSP; version 5 has the header scrambled.
  ///   Differences: a lump that is not inside the file is an error (the original reads what
  ///   it finds and leaves the rest zero); the identifier of a file shorter than the header
  ///   is wrong, not read from nothing. The warning "AAS file not sequentially read" is
  ///   printed as the original does, with its habit of not remembering the offset it
  ///   jumped to (so a lump after a gap gives a warning each time).
  /// </summary>
  TAasReader = class(TInterfacedObject, IAasReader)
  strict private
    FImport: IBotImport;
    FFiles: IBotFileSource;
    FLibVars: IBotLibVars;
    FSwapBytes: Boolean;
    class function AToI(const AText: AnsiString): Integer; static;
    function LumpData(const AData: TBytes; const AHeader: TAasFileHeader; const AIndex, ARecordSize: Integer;
      var ALastOffset: Integer; const AName: string): TBytes;
  public
    /// <summary>
    ///   AImport receives the messages, AFiles gives the files and ALibVars the variable
    ///   sv_mapChecksum (all three are only needed by Load; ParseBytes needs the import to
    ///   print its warning). ASwapBytes: the machine is big endian
    /// </summary>
    constructor Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars;
      const ASwapBytes: Boolean = False);
    function Load(const AFileName: AnsiString; out AFile: IAasFile): Integer;
    function ParseBytes(const AData: TBytes; const AName: AnsiString; const ABspChecksum: Integer): IAasFile;
  end;

implementation

uses
  DelphiDoom.BotAi.Types, DelphiDoom.Aas.AasFile, DelphiDoom.Aas.ByteSwapper, DelphiDoom.Aas.HeaderCipher,
  DelphiDoom.Aas.Printer;

resourcestring
  STryingToLoad = 'trying to load %s'#10;
  SCannotOpen = 'can''t open %s';
  SNotAnAasFile = '%s is not an AAS file';
  SWrongVersion = 'aas file %s is version %d, not %d';
  SOutOfDate = 'aas file %s is out of date';
  SNotSequential = 'AAS file not sequentially read'#10;
  SLumpOutside = 'aas lump %d of %s is outside the file (offset %d, length %d, file %d bytes)';

type
  /// <summary>Turns the bytes of a lump into an array of its records</summary>
  TRecordArray<T> = class
    class function FromBytes(const ABytes: TBytes): TArray<T>; static;
  end;

const
  CHECKSUM_VARIABLE = 'sv_mapChecksum';

{ TAasReader }

constructor TAasReader.Create(const AImport: IBotImport; const AFiles: IBotFileSource; const ALibVars: IBotLibVars;
  const ASwapBytes: Boolean);
begin
  inherited Create;
  FImport := AImport;
  FFiles := AFiles;
  FLibVars := ALibVars;
  FSwapBytes := ASwapBytes;
end;

class function TAasReader.AToI(const AText: AnsiString): Integer;
var
  LIndex: Integer;
  LNegative: Boolean;
  LValue: Cardinal;
begin
  // atoi: blanks, a sign, digits up to the first other character; the value wraps
  LIndex := 1;
  while (LIndex <= System.Length(AText)) and (AText[LIndex] in [' ', #9, #10, #11, #12, #13]) do
    Inc(LIndex);
  LNegative := False;
  if (LIndex <= System.Length(AText)) and (AText[LIndex] in ['+', '-']) then
  begin
    LNegative := AText[LIndex] = '-';
    Inc(LIndex);
  end;
  LValue := 0;
  while (LIndex <= System.Length(AText)) and (AText[LIndex] in ['0'..'9']) do
  begin
    LValue := LValue * 10 + Cardinal(Ord(AText[LIndex]) - Ord('0'));
    Inc(LIndex);
  end;
  if LNegative then
    LValue := Cardinal(-Integer(LValue));
  Result := Integer(LValue);
end;

class function TRecordArray<T>.FromBytes(const ABytes: TBytes): TArray<T>;
begin
  SetLength(Result, Length(ABytes) div SizeOf(T));
  if System.Length(Result) > 0 then
    Move(ABytes[0], Result[0], System.Length(Result) * SizeOf(T));
end;

function TAasReader.LumpData(const AData: TBytes; const AHeader: TAasFileHeader; const AIndex, ARecordSize: Integer;
  var ALastOffset: Integer; const AName: string): TBytes;
var
  LOffset, LLength: Integer;
begin
  LOffset := AHeader.Lumps[AIndex].FileOffset;
  LLength := AHeader.Lumps[AIndex].FileLength;
  Result := nil;
  // an empty lump is a dummy: no seek, no warning
  if LLength = 0 then
    Exit;
  if (LLength < 0) or (LOffset < 0) or (Int64(LOffset) + LLength > System.Length(AData)) then
    raise EAasFileException.Create(BLERR_CANNOTREADAASLUMP,
      Format(SLumpOutside, [AIndex, AName, LOffset, LLength, System.Length(AData)]));
  if LOffset <> ALastOffset then
    TAasPrinter.Print(FImport, PRT_WARNING, SNotSequential);
  // the number of records is length / size, the rest of the bytes is not used
  SetLength(Result, (LLength div ARecordSize) * ARecordSize);
  if System.Length(Result) > 0 then
    Move(AData[LOffset], Result[0], System.Length(Result));
  Inc(ALastOffset, LLength);
end;

function TAasReader.ParseBytes(const AData: TBytes; const AName: AnsiString;
  const ABspChecksum: Integer): IAasFile;
var
  LHeader: TAasFileHeader;
  LContent: TAasFileData;
  LLastOffset: Integer;
  LName: string;
begin
  LName := string(AName);
  if System.Length(AData) < SizeOf(TAasFileHeader) then
    raise EAasFileException.Create(BLERR_WRONGAASFILEID, Format(SNotAnAasFile, [LName]));
  Move(AData[0], LHeader, SizeOf(TAasFileHeader));
  if LHeader.Ident <> AAS_ID then
    raise EAasFileException.Create(BLERR_WRONGAASFILEID, Format(SNotAnAasFile, [LName]));
  if (LHeader.Version <> AAS_VERSION_OLD) and (LHeader.Version <> AAS_VERSION) then
    raise EAasFileException.Create(BLERR_WRONGAASFILEVERSION,
      Format(SWrongVersion, [LName, LHeader.Version, AAS_VERSION]));
  if LHeader.Version = AAS_VERSION then
    TAasHeaderCipher.Apply(LHeader);
  if LHeader.BspChecksum <> ABspChecksum then
    raise EAasFileException.Create(BLERR_WRONGAASFILEVERSION, Format(SOutOfDate, [LName]));

  LContent.Header := LHeader;
  LLastOffset := SizeOf(TAasFileHeader);
  LContent.BBoxes := TRecordArray<TAasBBox>.FromBytes(LumpData(AData, LHeader, AASLUMP_BBOXES, SizeOf(TAasBBox), LLastOffset, LName));
  LContent.Vertexes := TRecordArray<TVec3>.FromBytes(LumpData(AData, LHeader, AASLUMP_VERTEXES, SizeOf(TVec3), LLastOffset, LName));
  LContent.Planes := TRecordArray<TAasPlane>.FromBytes(LumpData(AData, LHeader, AASLUMP_PLANES, SizeOf(TAasPlane), LLastOffset, LName));
  LContent.Edges := TRecordArray<TAasEdge>.FromBytes(LumpData(AData, LHeader, AASLUMP_EDGES, SizeOf(TAasEdge), LLastOffset, LName));
  LContent.EdgeIndex := TRecordArray<Integer>.FromBytes(LumpData(AData, LHeader, AASLUMP_EDGEINDEX, SizeOf(Integer), LLastOffset, LName));
  LContent.Faces := TRecordArray<TAasFace>.FromBytes(LumpData(AData, LHeader, AASLUMP_FACES, SizeOf(TAasFace), LLastOffset, LName));
  LContent.FaceIndex := TRecordArray<Integer>.FromBytes(LumpData(AData, LHeader, AASLUMP_FACEINDEX, SizeOf(Integer), LLastOffset, LName));
  LContent.Areas := TRecordArray<TAasArea>.FromBytes(LumpData(AData, LHeader, AASLUMP_AREAS, SizeOf(TAasArea), LLastOffset, LName));
  LContent.AreaSettings := TRecordArray<TAasAreaSettings>.FromBytes(LumpData(AData, LHeader, AASLUMP_AREASETTINGS, SizeOf(TAasAreaSettings), LLastOffset, LName));
  LContent.Reachability := TRecordArray<TAasReachability>.FromBytes(LumpData(AData, LHeader, AASLUMP_REACHABILITY, SizeOf(TAasReachability), LLastOffset, LName));
  LContent.Nodes := TRecordArray<TAasNode>.FromBytes(LumpData(AData, LHeader, AASLUMP_NODES, SizeOf(TAasNode), LLastOffset, LName));
  LContent.Portals := TRecordArray<TAasPortal>.FromBytes(LumpData(AData, LHeader, AASLUMP_PORTALS, SizeOf(TAasPortal), LLastOffset, LName));
  LContent.PortalIndex := TRecordArray<Integer>.FromBytes(LumpData(AData, LHeader, AASLUMP_PORTALINDEX, SizeOf(Integer), LLastOffset, LName));
  LContent.Clusters := TRecordArray<TAasCluster>.FromBytes(LumpData(AData, LHeader, AASLUMP_CLUSTERS, SizeOf(TAasCluster), LLastOffset, LName));
  if FSwapBytes then
    TAasByteSwapper.Swap(LContent);
  Result := TAasFile.Create(LContent);
end;

function TAasReader.Load(const AFileName: AnsiString; out AFile: IAasFile): Integer;
var
  LData: TBytes;
  LChecksum: Integer;
begin
  AFile := nil;
  TAasPrinter.Print(FImport, PRT_MESSAGE, Format(STryingToLoad, [string(AFileName)]));
  if not Assigned(FFiles) or not FFiles.TryReadFile(AFileName, LData) then
  begin
    TAasPrinter.Print(FImport, PRT_FATAL, Format(SCannotOpen, [string(AFileName)]) + #10);
    Exit(BLERR_CANNOTOPENAASFILE);
  end;
  LChecksum := 0;
  if Assigned(FLibVars) then
    LChecksum := AToI(FLibVars.GetStringOrCreate(CHECKSUM_VARIABLE, ''));
  try
    AFile := ParseBytes(LData, AFileName, LChecksum);
    Result := BLERR_NOERROR;
  except
    on E: EAasFileException do
    begin
      TAasPrinter.Print(FImport, PRT_FATAL, E.Message + #10);
      Result := E.ErrorCode;
    end;
  end;
end;

end.
