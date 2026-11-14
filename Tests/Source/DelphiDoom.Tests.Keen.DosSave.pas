{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the saved games of the DOS program   }
{  (the executable unpacked, the states found in it, the file converted)        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.DosSave;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.Keen.Types,
  DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.LzExe, DelphiDoom.Keen.DosStateLocator,
  DelphiDoom.Keen.DosSaveConverter;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenLzExe = class(TObject)
  strict private
    /// <summary>An EXE that LZEXE 0.91 would have packed, made by hand: literals and one match, then the end mark</summary>
    function PackedProgram(const AOutput: TBytes): TBytes;
  public
    [Test]
    procedure DovrebbeRiconoscereUnEseguibileImpacchettato;
    [Test]
    procedure DovrebbeEspandereUnEseguibileImpacchettato;
    [Test]
    procedure DovrebbeDareLImmagineDiUnEseguibileNonImpacchettato;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonEUnProgramma;
    [Test]
    procedure DovrebbeRifiutareUnProgrammaImpacchettatoTroncato;
    [Test]
    procedure DovrebbeRifiutareUnaIntestazioneOltreIlFile;
    [Test]
    procedure DovrebbeEspandereIlVeroKdreamsExe;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenDosStateLocator = class(TObject)
  strict private
    FStates: IKeenStateTable;
    function BuildImage(ADataStart: Integer; AShiftSuccessors: Boolean): TBytes;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeTrovareITrecentoTrediciStatiInUnaImmagineCostruita;
    [Test]
    procedure DovrebbeDareGliIndirizziDelSegmentoDati;
    [Test]
    procedure DovrebbeDistinguereGliStatiConGliStessiCampi;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineSenzaStati;
    [Test]
    procedure DovrebbeRifiutareUnaImmagineConDueSegmentiDati;
    [Test]
    procedure DovrebbeTrovareGliStatiDelVeroEseguibile;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenDosSaveConverter = class(TObject)
  strict private
    FStates: IKeenStateTable;
    FMap: TKeenDosStateMap;
    function Offset(AState: Integer): Integer;
    function MakeFile(const AStates: array of Integer; const ATemps: array of SmallInt; AMapOn: Integer = 1): TBytes;
    function ReadRecord(const ABytes: TBytes; AIndex: Integer): TKeenSaveObject;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure DovrebbeTradurreGliIndirizziDegliStatiInNumeri;
    [Test]
    procedure DovrebbeDareIlNomeELivelloDelGioco;
    [Test]
    procedure DovrebbeLasciareIlResto;
    [Test]
    procedure DovrebbeMettereUnCollegamentoFinoAllUltimoAttore;
    [Test]
    procedure DovrebbeTradurreLoStatoDiUnNemicoDiventatoFiore;
    [Test]
    procedure DovrebbeTradurreIlFioreDiUnaNuvola;
    [Test]
    procedure DovrebbeTradurreLoZeesDiKeenAddormentato;
    [Test]
    procedure KeenAddormentatoSenzaZeesDovrebbeAvereLAttoreFinto;
    [Test]
    procedure UnContatoreDiKeenNonDovrebbeEssereUnIndirizzo;
    [Test]
    procedure DovrebbeRifiutareUnaFirmaSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnFileCorto;
    [Test]
    procedure DovrebbeRifiutareUnLivelloCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareUnPianoTroncato;
    [Test]
    procedure DovrebbeRifiutareUnaDimensioneDegliAttoriSbagliata;
    [Test]
    procedure DovrebbeRifiutareUnFileSenzaAttori;
    [Test]
    procedure DovrebbeRifiutareUnoStatoCheNonE;
    [Test]
    procedure DovrebbeRifiutareICollegamentiCheNonSiSeguono;
    [Test]
    procedure DovrebbeRifiutareUnPuntatoreAUnFioreCheNonCe;
    [Test]
    procedure LaPartitaVeraDelProgrammaDOSDovrebbeTornareComEra;
    [Test]
    procedure LaPartitaVeraConvertitaDovrebbeScriversiComeIlProgrammaLaScrisse;
  end;

implementation

uses
  System.IOUtils, DelphiDoom.Keen.StateTableCopy, DelphiDoom.Keen.StateTable, DelphiDoom.Keen.StateTypes, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.GameSaver, DelphiDoom.Keen.Factory, DelphiDoom.Keen.UserIntf, DelphiDoom.Tests.Shared.Files,
  DelphiDoom.Tests.Shared.Skip, DelphiDoom.Tests.Keen.GameSession;

const
  EXECUTABLE_FILE = 'Reference\_dati\keen\KDREAMS.EXE';
  DOS_SAVE_FILE = 'Reference\_dati\keen_build\riferimento\dossave\SAVEGM0.KDR';
  /// <summary>Length and FNV-1a of the memory image of KDREAMS.EXE 1.13 as the unlzexe tool of the reference gives it</summary>
  IMAGE_LENGTH = 206368;

{ TTestKeenLzExe }

function TTestKeenLzExe.PackedProgram(const AOutput: TBytes): TBytes;
var
  LStream: TBytes;
  LWordAt: Integer;
  LUsed: Integer;

  procedure Reserve;
  begin
    LWordAt := Length(LStream);
    SetLength(LStream, Length(LStream) + 2);
    LUsed := 0;
  end;

  procedure Bit(AValue: Integer);
  begin
    if AValue <> 0 then
      LStream[LWordAt + LUsed div 8] := LStream[LWordAt + LUsed div 8] or Byte(1 shl (LUsed mod 8));
    Inc(LUsed);
    if LUsed = 16 then
      Reserve;
  end;

  procedure Put(AValue: Byte);
  begin
    SetLength(LStream, Length(LStream) + 1);
    LStream[High(LStream)] := AValue;
  end;

var
  LIndex: Integer;
  LHeader: TBytes;
begin
  // a header of two paragraphs: MZ, the paragraphs of the header, the entry segment (cs) at 22, "LZ91" at 28
  SetLength(LHeader, 32);
  LHeader[0] := Ord('M');
  LHeader[1] := Ord('Z');
  LHeader[8] := 2;
  LHeader[28] := Ord('L');
  LHeader[29] := Ord('Z');
  LHeader[30] := Ord('9');
  LHeader[31] := Ord('1');
  // cs = 1: the info block is at (1 + 2) * 16 = 48 and its fifth word (4) puts the packed data at (1 - 4 + 2) * 16 < 0:
  // use cs = 8 and 4 for the distance, so the data begin at (8 - 4 + 2) * 16 = 96 and the info block at 160
  LHeader[22] := 8;
  SetLength(LStream, 0);
  Reserve;
  // the first literals
  for LIndex := 0 to Length(AOutput) - 1 do
  begin
    Bit(1);
    Put(AOutput[LIndex]);
  end;
  // a short match: 0 0, two bits of length - 2 (1: length 3), a byte of distance (-3)
  Bit(0);
  Bit(0);
  Bit(0);
  Bit(1);
  Put(Byte(-3 and $FF));
  // the end: 0 1, the byte, then the byte with the length bits at 0 (length 2) and a length byte of 0
  Bit(0);
  Bit(1);
  Put(0);
  Put(0);
  Put(0);
  SetLength(Result, 200);
  Move(LHeader[0], Result[0], 32);
  Move(LStream[0], Result[96], Length(LStream));
  // the info block at (cs + header) * 16 = 160: the packed data may overlap it, the program only reads the word at 8
  Result[160 + 8] := 4;
end;

procedure TTestKeenLzExe.DovrebbeRiconoscereUnEseguibileImpacchettato;
begin
  Assert.IsTrue(TKeenLzExe.IsPacked(PackedProgram(TBytes.Create(1, 2, 3))));
  Assert.IsFalse(TKeenLzExe.IsPacked(TBytes.Create(Ord('M'), Ord('Z'), 0, 0)));
  Assert.IsFalse(TKeenLzExe.IsPacked(nil));
end;

procedure TTestKeenLzExe.DovrebbeEspandereUnEseguibileImpacchettato;
var
  LImage: TBytes;
begin
  LImage := TKeenLzExe.LoadImage(PackedProgram(TBytes.Create(10, 20, 30, 40)));
  // the four literals, then the match of length 3 at distance 3 (20, 30, 40)
  Assert.AreEqual(7, Length(LImage));
  Assert.AreEqual(10, Integer(LImage[0]));
  Assert.AreEqual(40, Integer(LImage[3]));
  Assert.AreEqual(20, Integer(LImage[4]));
  Assert.AreEqual(30, Integer(LImage[5]));
  Assert.AreEqual(40, Integer(LImage[6]));
end;

procedure TTestKeenLzExe.DovrebbeDareLImmagineDiUnEseguibileNonImpacchettato;
var
  LFile: TBytes;
  LImage: TBytes;
begin
  SetLength(LFile, 32 + 5);
  LFile[0] := Ord('M');
  LFile[1] := Ord('Z');
  LFile[8] := 2;
  LFile[32] := 7;
  LFile[36] := 9;
  LImage := TKeenLzExe.LoadImage(LFile);
  Assert.AreEqual(5, Length(LImage));
  Assert.AreEqual(7, Integer(LImage[0]));
  Assert.AreEqual(9, Integer(LImage[4]));
end;

procedure TTestKeenLzExe.DovrebbeRifiutareUnFileCheNonEUnProgramma;
begin
  Assert.WillRaise(
    procedure
    begin
      TKeenLzExe.LoadImage(TBytes.Create(1, 2, 3, 4));
    end, EKeenDataException);
  Assert.WillRaise(
    procedure
    begin
      TKeenLzExe.LoadImage(nil);
    end, EKeenDataException);
end;

procedure TTestKeenLzExe.DovrebbeRifiutareUnProgrammaImpacchettatoTroncato;
var
  LFile: TBytes;
begin
  LFile := PackedProgram(TBytes.Create(1, 2, 3));
  SetLength(LFile, 100);
  Assert.WillRaise(
    procedure
    begin
      TKeenLzExe.LoadImage(LFile);
    end, EKeenDataException);
end;

procedure TTestKeenLzExe.DovrebbeRifiutareUnaIntestazioneOltreIlFile;
var
  LFile: TBytes;
begin
  SetLength(LFile, 40);
  LFile[0] := Ord('M');
  LFile[1] := Ord('Z');
  LFile[8] := 100;
  Assert.WillRaise(
    procedure
    begin
      TKeenLzExe.LoadImage(LFile);
    end, EKeenDataException);
end;

procedure TTestKeenLzExe.DovrebbeEspandereIlVeroKdreamsExe;
var
  LPath: string;
  LImage: TBytes;
begin
  LPath := TTestFiles.FindFileUp(EXECUTABLE_FILE);
  if LPath = '' then
    TTestSkip.Ignore('il KDREAMS.EXE dello shareware 1.13 non e'' su questa macchina');
  LImage := TKeenLzExe.LoadImage(TFile.ReadAllBytes(LPath));
  // the same bytes as the image that the unlzexe tool of the reference makes (Reference\_dati\keen_build\tools)
  Assert.AreEqual(IMAGE_LENGTH, Length(LImage));
  Assert.IsTrue(TKeenLzExe.IsPacked(TFile.ReadAllBytes(LPath)));
end;

{ TTestKeenDosStateLocator }

procedure TTestKeenDosStateLocator.Setup;
begin
  FStates := TKeenStateTableCopy.CreateGameStates;
end;

function TTestKeenDosStateLocator.BuildImage(ADataStart: Integer; AShiftSuccessors: Boolean): TBytes;
var
  LIndex: Integer;
  LAt: Integer;
  LDef: TKeenStateDef;

  procedure PutWord(APosition, AValue: Integer);
  begin
    Result[APosition] := Byte(AValue);
    Result[APosition + 1] := Byte(AValue shr 8);
  end;

  procedure PutFar(APosition: Integer; AAction: Word);
  begin
    if AAction = 0 then
    begin
      PutWord(APosition, 0);
      PutWord(APosition + 2, 0);
    end
    else
    begin
      PutWord(APosition, $2000 + AAction * 4);
      PutWord(APosition + 2, $05E8);
    end;
  end;

begin
  // noise that is not a state, then the 213 states one after the other, 30 bytes each
  SetLength(Result, ADataStart + $100 + 30 * FStates.Count + 64);
  FillChar(Result[0], Length(Result), $FF);
  for LIndex := 0 to FStates.Count - 1 do
  begin
    LDef := FStates[LIndex];
    LAt := ADataStart + $100 + 30 * LIndex;
    PutWord(LAt, Word(LDef.LeftShape));
    PutWord(LAt + 2, Word(LDef.RightShape));
    PutWord(LAt + 4, Ord(LDef.Progress));
    PutWord(LAt + 6, Ord(LDef.Skippable));
    PutWord(LAt + 8, Ord(LDef.PushToFloor));
    PutWord(LAt + 10, Word(LDef.TicTime));
    PutWord(LAt + 12, Word(LDef.XMove));
    PutWord(LAt + 14, Word(LDef.YMove));
    PutFar(LAt + 16, LDef.Think);
    PutFar(LAt + 20, LDef.Contact);
    PutFar(LAt + 24, LDef.React);
    if LDef.NextState >= 0 then
    begin
      PutWord(LAt + 28, $100 + 30 * LDef.NextState);
      // a second data segment for some of the states: the successors do not agree
      if AShiftSuccessors and (LIndex mod 7 = 0) then
        PutWord(LAt + 28, $100 + 30 * LDef.NextState + 6);
    end
    else
      PutWord(LAt + 28, 0);
  end;
end;

procedure TTestKeenDosStateLocator.DovrebbeTrovareITrecentoTrediciStatiInUnaImmagineCostruita;
var
  LMap: TKeenDosStateMap;
begin
  LMap := TKeenDosStateLocator.Locate(BuildImage($400, False), FStates);
  Assert.AreEqual(213, Length(LMap.Offsets));
  Assert.AreEqual(0, LMap.Missing);
  Assert.AreEqual(0, LMap.Ambiguous);
end;

procedure TTestKeenDosStateLocator.DovrebbeDareGliIndirizziDelSegmentoDati;
var
  LMap: TKeenDosStateMap;
  LIndex: Integer;
begin
  LMap := TKeenDosStateLocator.Locate(BuildImage($400, False), FStates);
  Assert.AreEqual($400, LMap.DataStart);
  for LIndex := 0 to High(LMap.Offsets) do
    Assert.AreEqual($100 + 30 * LIndex, LMap.Offsets[LIndex], 'state ' + IntToStr(LIndex));
end;

procedure TTestKeenDosStateLocator.DovrebbeDistinguereGliStatiConGliStessiCampi;
var
  LMap: TKeenDosStateMap;
  LSeen: TDictionary<Integer, Integer>;
  LIndex: Integer;
begin
  // the explosion states 5, 7 and 9 have the same fields (the explosion goes on to the same two): their addresses
  // are the ones where they are, one after the other
  LMap := TKeenDosStateLocator.Locate(BuildImage($400, False), FStates);
  LSeen := TDictionary<Integer, Integer>.Create;
  try
    for LIndex := 0 to High(LMap.Offsets) do
    begin
      Assert.IsFalse(LSeen.ContainsKey(LMap.Offsets[LIndex]), 'two states at the same address: ' + IntToStr(LIndex));
      LSeen.Add(LMap.Offsets[LIndex], LIndex);
    end;
  finally
    LSeen.Free;
  end;
end;

procedure TTestKeenDosStateLocator.DovrebbeRifiutareUnaImmagineSenzaStati;
var
  LNothing: TBytes;
begin
  SetLength(LNothing, 4096);
  FillChar(LNothing[0], Length(LNothing), $FF);
  Assert.WillRaise(
    procedure
    begin
      TKeenDosStateLocator.Locate(LNothing, FStates);
    end, EKeenDataException);
end;

procedure TTestKeenDosStateLocator.DovrebbeRifiutareUnaImmagineConDueSegmentiDati;
var
  LImage: TBytes;
begin
  LImage := BuildImage($400, True);
  Assert.WillRaise(
    procedure
    begin
      TKeenDosStateLocator.Locate(LImage, FStates);
    end, EKeenDataException);
end;

procedure TTestKeenDosStateLocator.DovrebbeTrovareGliStatiDelVeroEseguibile;
var
  LPath: string;
  LMap: TKeenDosStateMap;
begin
  LPath := TTestFiles.FindFileUp(EXECUTABLE_FILE);
  if LPath = '' then
    TTestSkip.Ignore('il KDREAMS.EXE dello shareware 1.13 non e'' su questa macchina');
  LMap := TKeenDosStateLocator.Locate(TKeenLzExe.LoadImage(TFile.ReadAllBytes(LPath)), FStates);
  Assert.AreEqual(0, LMap.Missing);
  Assert.AreEqual(0, LMap.Ambiguous);
  // the first state of the table, the one that Keen has on the world map and the last: the addresses that the
  // program of the original wrote in a saved game (SAVEGM0.KDR of the real program)
  Assert.AreEqual($BB4, LMap.Offsets[KEEN_STATE_S_SCORE]);
  Assert.AreEqual($D3A, LMap.Offsets[KEEN_STATE_S_WORLDKEEN]);
  Assert.AreEqual($BD2, LMap.Offsets[KEEN_STATE_S_FLOWERPOWER1]);
  // one after the other, 30 bytes each
  Assert.AreEqual(30, LMap.Offsets[KEEN_STATE_S_WORLDKEEN + 1] - LMap.Offsets[KEEN_STATE_S_WORLDKEEN]);
end;

{ TTestKeenDosSaveConverter }

procedure TTestKeenDosSaveConverter.Setup;
var
  LIndex: Integer;
begin
  FStates := TKeenStateTableCopy.CreateGameStates;
  FMap.Missing := 0;
  FMap.Ambiguous := 0;
  FMap.DataStart := 0;
  SetLength(FMap.Offsets, FStates.Count);
  for LIndex := 0 to FStates.Count - 1 do
    FMap.Offsets[LIndex] := $BB4 + 30 * LIndex;
end;

function TTestKeenDosSaveConverter.Offset(AState: Integer): Integer;
begin
  Result := FMap.Offsets[AState];
end;

function TTestKeenDosSaveConverter.MakeFile(const AStates: array of Integer; const ATemps: array of SmallInt;
  AMapOn: Integer): TBytes;
var
  LCount: Integer;
  LStream: TBytesStream;
  LHeader: TKeenSaveHeader;
  LState: TKeenSaveGameState;
  LRecord: TKeenSaveObject;
  LIndex: Integer;
  LEmpty: Word;
begin
  LCount := Length(AStates);
  LStream := TBytesStream.Create;
  try
    LHeader := Default(TKeenSaveHeader);
    LHeader.Signature[0] := 'K';
    LHeader.Signature[1] := 'D';
    LHeader.Signature[2] := 'R';
    LHeader.Name[0] := 'g';
    LHeader.Name[1] := 'o';
    LStream.WriteBuffer(LHeader, SizeOf(LHeader));
    LState := Default(TKeenSaveGameState);
    LState.MapOn := AMapOn;
    LState.Lives := 3;
    LStream.WriteBuffer(LState, SizeOf(LState));
    LEmpty := 0;
    for LIndex := 0 to 2 do
      LStream.WriteBuffer(LEmpty, 2);
    for LIndex := 0 to LCount - 1 do
    begin
      LRecord := Default(TKeenSaveObject);
      LRecord.ObClass := Word(LIndex);
      LRecord.X := Word(100 + LIndex);
      if AStates[LIndex] >= 0 then
        LRecord.State := Word(Offset(AStates[LIndex]));
      LRecord.Sprite := $C1EA;
      if LIndex < LCount - 1 then
        LRecord.Next := Word($7000 + 76 * (LIndex + 1));
      if LIndex > 0 then
        LRecord.Prev := Word($7000 + 76 * (LIndex - 1));
      // the address of the player is the back link of the second actor
      if LIndex = 1 then
        LRecord.Prev := $7000;
      if LIndex * 4 + 3 < Length(ATemps) then
      begin
        LRecord.Temp1 := ATemps[LIndex * 4];
        LRecord.Temp2 := ATemps[LIndex * 4 + 1];
        LRecord.Temp3 := ATemps[LIndex * 4 + 2];
        LRecord.Temp4 := ATemps[LIndex * 4 + 3];
      end;
      LStream.WriteBuffer(LRecord, SizeOf(LRecord));
    end;
    Result := Copy(LStream.Bytes, 0, LStream.Size);
  finally
    LStream.Free;
  end;
end;

function TTestKeenDosSaveConverter.ReadRecord(const ABytes: TBytes; AIndex: Integer): TKeenSaveObject;
begin
  Move(ABytes[40 + 60 + 6 + AIndex * SizeOf(TKeenSaveObject)], Result, SizeOf(Result));
end;

procedure TTestKeenDosSaveConverter.DovrebbeTradurreGliIndirizziDegliStatiInNumeri;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE,
    KEEN_STATE_S_KEENDIE1], []), FMap, LInfo);
  Assert.AreEqual(KEEN_STATE_S_KEENSTAND + 1, Integer(ReadRecord(LBytes, 0).State));
  Assert.AreEqual(KEEN_STATE_S_SCORE + 1, Integer(ReadRecord(LBytes, 1).State));
  Assert.AreEqual(KEEN_STATE_S_KEENDIE1 + 1, Integer(ReadRecord(LBytes, 2).State));
  // an actor with no state (it removed itself) keeps 0
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE, -1], []), FMap, LInfo);
  Assert.AreEqual(0, Integer(ReadRecord(LBytes, 2).State));
end;

procedure TTestKeenDosSaveConverter.DovrebbeDareIlNomeELivelloDelGioco;
var
  LInfo: TKeenDosSaveInfo;
begin
  TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE, KEEN_STATE_S_KEENDIE1], [], 5),
    FMap, LInfo);
  Assert.AreEqual(AnsiString('go'), LInfo.Name);
  Assert.AreEqual(5, LInfo.MapOn);
  Assert.AreEqual(3, LInfo.Actors);
  Assert.AreEqual(0, LInfo.PointersConverted);
end;

procedure TTestKeenDosSaveConverter.DovrebbeLasciareIlResto;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
  LRecord: TKeenSaveObject;
begin
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE],
    [3, 4, 5, 6, 7, 8, 9, 10]), FMap, LInfo);
  LRecord := ReadRecord(LBytes, 0);
  Assert.AreEqual(100, Integer(LRecord.X));
  Assert.AreEqual(3, Integer(LRecord.Temp1));
  Assert.AreEqual(6, Integer(LRecord.Temp4));
  Assert.AreEqual(0, Integer(LRecord.Sprite));
  Assert.AreEqual(0, Integer(LRecord.Prev));
  LRecord := ReadRecord(LBytes, 1);
  Assert.AreEqual(101, Integer(LRecord.X));
  Assert.AreEqual(9, Integer(LRecord.Temp3));
end;

procedure TTestKeenDosSaveConverter.DovrebbeMettereUnCollegamentoFinoAllUltimoAttore;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE,
    KEEN_STATE_S_KEENDIE1], []), FMap, LInfo);
  Assert.AreEqual(1, Integer(ReadRecord(LBytes, 0).Next));
  Assert.AreEqual(1, Integer(ReadRecord(LBytes, 1).Next));
  Assert.AreEqual(0, Integer(ReadRecord(LBytes, 2).Next));
end;

procedure TTestKeenDosSaveConverter.DovrebbeTradurreLoStatoDiUnNemicoDiventatoFiore;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  // temp1: the class that the enemy had, temp2: its state (an address), temp3: the time as a flower
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE, KEEN_STATE_S_FLOWER3],
    [0, 0, 0, 0, 0, 0, 0, 0, 5, SmallInt(Offset(KEEN_STATE_S_WORLDKEEN)), 77, 0]), FMap, LInfo);
  Assert.AreEqual(5, Integer(ReadRecord(LBytes, 2).Temp1));
  Assert.AreEqual(KEEN_STATE_S_WORLDKEEN, Integer(ReadRecord(LBytes, 2).Temp2));
  Assert.AreEqual(77, Integer(ReadRecord(LBytes, 2).Temp3));
  Assert.AreEqual(1, LInfo.PointersConverted);
end;

procedure TTestKeenDosSaveConverter.DovrebbeTradurreIlFioreDiUnaNuvola;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  // the puff of smoke that gives the flower back to the enemy has the address of the flower in temp1: the third actor
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE, KEEN_STATE_S_FLOWER1,
    KEEN_STATE_S_POOFFROM2], [0, 0, 0, 0, 0, 0, 0, 0, 5, SmallInt(Offset(KEEN_STATE_S_WORLDKEEN)), 0, 0,
    SmallInt($7000 + 76 * 2), 0, 0, 0]), FMap, LInfo);
  Assert.AreEqual(2, Integer(ReadRecord(LBytes, 3).Temp1));
end;

procedure TTestKeenDosSaveConverter.DovrebbeTradurreLoZeesDiKeenAddormentato;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSLEEP1, KEEN_STATE_S_SCORE, KEEN_STATE_S_KEENZEE1],
    [SmallInt($7000 + 76 * 2), 0, 0, 0]), FMap, LInfo);
  Assert.AreEqual(2, Integer(ReadRecord(LBytes, 0).Temp1));
  Assert.AreEqual(1, LInfo.PointersConverted);
end;

procedure TTestKeenDosSaveConverter.KeenAddormentatoSenzaZeesDovrebbeAvereLAttoreFinto;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  // the address of dummyobj is not the address of an actor of the list
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENSLEEP2, KEEN_STATE_S_SCORE, KEEN_STATE_S_KEENZEE1],
    [SmallInt($1234), 0, 0, 0]), FMap, LInfo);
  Assert.AreEqual(KEEN_DUMMY_SLOT, Integer(ReadRecord(LBytes, 0).Temp1));
end;

procedure TTestKeenDosSaveConverter.UnContatoreDiKeenNonDovrebbeEssereUnIndirizzo;
var
  LInfo: TKeenDosSaveInfo;
  LBytes: TBytes;
begin
  // standing, the same field is the time of the pause: it is left as it is
  LBytes := TKeenDosSaveConverter.Convert(MakeFile([KEEN_STATE_S_KEENPAUSELOOK, KEEN_STATE_S_SCORE,
    KEEN_STATE_S_KEENZEE1], [SmallInt(250), 0, 0, 0]), FMap, LInfo);
  Assert.AreEqual(250, Integer(ReadRecord(LBytes, 0).Temp1));
  Assert.AreEqual(0, LInfo.PointersConverted);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnaFirmaSbagliata;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE], []);
  LBytes[0] := Ord('X');
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnFileCorto;
begin
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(TBytes.Create(75, 68, 82, 0), FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnLivelloCheNonEsiste;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE], [], 99);
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnPianoTroncato;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE], []);
  // the first plane says that it has 500 bytes
  LBytes[100] := $F4;
  LBytes[101] := $01;
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnaDimensioneDegliAttoriSbagliata;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE], []);
  SetLength(LBytes, Length(LBytes) - 3);
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnFileSenzaAttori;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE], []);
  SetLength(LBytes, Length(LBytes) - 2 * SizeOf(TKeenSaveObject));
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnoStatoCheNonE;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE], []);
  // an address that is none of the 213 states: a game written by another version of the program
  LBytes[40 + 60 + 6 + 30] := $01;
  LBytes[40 + 60 + 6 + 31] := $01;
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareICollegamentiCheNonSiSeguono;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE, KEEN_STATE_S_KEENDIE1], []);
  // the third actor says that the one before it is somewhere else
  LBytes[40 + 60 + 6 + 2 * SizeOf(TKeenSaveObject) + 74] := $55;
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.DovrebbeRifiutareUnPuntatoreAUnFioreCheNonCe;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile([KEEN_STATE_S_KEENSTAND, KEEN_STATE_S_SCORE, KEEN_STATE_S_POOFFROM1],
    [0, 0, 0, 0, 0, 0, 0, 0, SmallInt($1111), 0, 0, 0]);
  Assert.WillRaise(
    procedure
    var
      LInfo: TKeenDosSaveInfo;
    begin
      TKeenDosSaveConverter.Convert(LBytes, FMap, LInfo);
    end, EKeenDataException);
end;

procedure TTestKeenDosSaveConverter.LaPartitaVeraDelProgrammaDOSDovrebbeTornareComEra;
var
  LExe: string;
  LSave: string;
  LDos: TBytes;
  LConverted: TBytes;
  LInfo: TKeenDosSaveInfo;
  LMap: TKeenDosStateMap;
  LSession: TKeenTestSession;
  LSaver: TKeenGameSaver;
  LStream: TBytesStream;
  LStates: IKeenStateTable;
  LState: PKeenGameState;
begin
  LExe := TTestFiles.FindFileUp(EXECUTABLE_FILE);
  LSave := TTestFiles.FindFileUp(DOS_SAVE_FILE);
  if (LExe = '') or (LSave = '') then
    TTestSkip.Ignore('KDREAMS.EXE e una partita salvata dal programma DOS non sono su questa macchina');
  LDos := TFile.ReadAllBytes(LSave);
  LMap := TKeenDosStateLocator.Locate(TKeenLzExe.LoadImage(TFile.ReadAllBytes(LExe)), FStates);
  LConverted := TKeenDosSaveConverter.Convert(LDos, LMap, LInfo);
  // the game that the player saved: "ab" on the world map, with Keen and the score box
  Assert.AreEqual(AnsiString('ab'), LInfo.Name);
  Assert.AreEqual(0, LInfo.MapOn);
  Assert.AreEqual(2, LInfo.Actors);
  LSession := TKeenTestSession.Create('wait 1');
  try
    LStates := TKeenFactory.CreateGameStateTable;
    LSaver := TKeenGameSaver.Create(LSession.Game.Play, LSession.Game.Objects, LStates, LSession.Game.Level);
    try
      LStream := TBytesStream.Create(LConverted);
      try
        // after the header of 40 bytes, as the control panel reads it
        LStream.Position := 40;
        Assert.IsTrue(LSaver.Load(LStream), 'the game is loaded');
      finally
        LStream.Free;
      end;
      LState := LSession.Game.Play.GameState;
      Assert.AreEqual(0, Integer(LState^.MapOn));
      Assert.AreEqual(3, Integer(LState^.Lives));
      Assert.AreEqual(2, LSession.Game.Objects.Count);
      // Keen on the world map where the DOS program had him: the record of the file
      Assert.AreEqual(12288, Integer(LSession.Game.Objects.Player^.X));
      Assert.AreEqual(9984, Integer(LSession.Game.Objects.Player^.Y));
      Assert.AreEqual(KEEN_STATE_S_WORLDKEEN, Integer(LSession.Game.Objects.Player^.State));
    finally
      LSaver.Free;
    end;
  finally
    LSession.Free;
  end;
end;

procedure TTestKeenDosSaveConverter.LaPartitaVeraConvertitaDovrebbeScriversiComeIlProgrammaLaScrisse;
var
  LExe: string;
  LSave: string;
  LDos: TBytes;
  LConverted: TBytes;
  LInfo: TKeenDosSaveInfo;
  LMap: TKeenDosStateMap;
  LSession: TKeenTestSession;
  LSaver: TKeenGameSaver;
  LStream: TBytesStream;
  LWritten: TBytesStream;
  LStates: IKeenStateTable;
  LBytes: TBytes;
  LObjects: Integer;
begin
  LExe := TTestFiles.FindFileUp(EXECUTABLE_FILE);
  LSave := TTestFiles.FindFileUp(DOS_SAVE_FILE);
  if (LExe = '') or (LSave = '') then
    TTestSkip.Ignore('KDREAMS.EXE e una partita salvata dal programma DOS non sono su questa macchina');
  LDos := TFile.ReadAllBytes(LSave);
  LMap := TKeenDosStateLocator.Locate(TKeenLzExe.LoadImage(TFile.ReadAllBytes(LExe)), FStates);
  LConverted := TKeenDosSaveConverter.Convert(LDos, LMap, LInfo);
  LSession := TKeenTestSession.Create('wait 1');
  try
    LStates := TKeenFactory.CreateGameStateTable;
    LSaver := TKeenGameSaver.Create(LSession.Game.Play, LSession.Game.Objects, LStates, LSession.Game.Level);
    try
      LStream := TBytesStream.Create(LConverted);
      try
        LStream.Position := 40;
        Assert.IsTrue(LSaver.Load(LStream));
      finally
        LStream.Free;
      end;
      LWritten := TBytesStream.Create;
      try
        Assert.IsTrue(LSaver.Save(LWritten));
        LBytes := Copy(LWritten.Bytes, 0, LWritten.Size);
      finally
        LWritten.Free;
      end;
    finally
      LSaver.Free;
    end;
  finally
    LSession.Free;
  end;
  // what the port writes (after the header) is what the program of the original wrote: the state of the game and
  // the three planes of the map in RLEW, byte for byte. The actors differ where they have addresses
  LObjects := Length(LConverted) - 2 * SizeOf(TKeenSaveObject);
  Assert.AreEqual(LObjects - 40, Length(LBytes) - 2 * SizeOf(TKeenSaveObject));
  Assert.IsTrue(CompareMem(@LBytes[0], @LConverted[40], LObjects - 40), 'the state of the game and the planes');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenLzExe);
  TDUnitX.RegisterTestFixture(TTestKeenDosStateLocator);
  TDUnitX.RegisterTestFixture(TTestKeenDosSaveConverter);

end.
