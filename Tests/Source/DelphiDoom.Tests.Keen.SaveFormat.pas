{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - the format of a file of a saved game }
{  (this port, its first format, the DOS program) and what loading does        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.SaveFormat;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.UserTypes,
  DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.SaveFormat, DelphiDoom.Keen.SaveSlots, DelphiDoom.Tests.Keen.UiWorld;

/// <summary>
///   What follows the header in a file that this port can load: the state of the game, three empty planes and two
///   actors (the last one with no next); AMarker is the second byte of the state
/// </summary>
function MakeSaveBody(AMarker: Byte): TBytes;

type
  /// <summary>The game of a slot: it keeps where the stream was when it was asked to load</summary>
  TRecordingHooks = class(TInterfacedObject, IKeenGameHooks)
  public
    LoadedAt: Integer;
    Loads: Integer;
    function LoadGame(AStream: TStream): Boolean;
    function SaveGame(AStream: TStream): Boolean;
    procedure ResetGame;
  end;

  [TestFixture]
  [Category('keen')]
  TTestKeenSaveFormat = class(TObject)
  strict private
    /// <summary>
    ///   A file with a header of AHeaderSize bytes (a 40 byte header has AVersion in the high byte of present), the
    ///   state of the game, three empty planes and the actors: their states are AStates, the last one has no next
    /// </summary>
    function MakeFile(AHeaderSize, AVersion: Integer; const AStates: array of Word): TBytes;
  public
    [Test]
    procedure UnFileConLaVersioneDovrebbeEssereQuelloCorrente;
    [Test]
    procedure UnFileDellaPrimaVersioneDovrebbeAvereLaTestataCorta;
    [Test]
    procedure UnFileDelProgrammaDOSDovrebbeAvereGliIndirizziNegliStati;
    [Test]
    procedure UnFileConUnaFirmaSbagliataNonDovrebbeEssereNulla;
    [Test]
    procedure UnFileTroppoCortoNonDovrebbeEssereNulla;
    [Test]
    procedure UnFileConIPianiTroncatiNonDovrebbeEssereNulla;
    [Test]
    procedure UnFileConAttoriATrattiNonDovrebbeEssereNulla;
    [Test]
    procedure UnFileSenzaUnAttoreFinaleSenzaSeguenteNonDovrebbeEssereNulla;
    [Test]
    procedure UnFileSenzaVersioneConStatiPiccoliATrentanoveDovrebbeEssereDellaPrimaVersione;
    [Test]
    procedure UnFileSenzaVersioneENonDelPrimoFormatoNonDovrebbeEssereNulla;
    [Test]
    procedure LaTestataDovrebbeEssereLunga;
    [Test]
    procedure LaTestataScrittaDovrebbeDareLaVersione;
    [Test]
    procedure CaricareUnFileCorrenteDovrebbePartireDopoLaTestataDi40Byte;
    [Test]
    procedure CaricareUnFileDellaPrimaVersioneDovrebbePartireDopoLaTestataDi39Byte;
    [Test]
    procedure CaricareUnFileDelProgrammaDOSDovrebbeDireDiImportarlo;
    [Test]
    procedure CaricareUnFileCheNonEUnaPartitaDovrebbeDireCheEIncompleto;
    [Test]
    procedure IlNomeDiUnFileDOSDovrebbeEssereNellaLista;
  end;

implementation

const
  PLANES_AND_STATE_SIZE = 60 + 3 * 2;

function MakeSaveBody(AMarker: Byte): TBytes;
begin
  SetLength(Result, PLANES_AND_STATE_SIZE + 2 * SizeOf(TKeenSaveObject));
  FillChar(Result[0], Length(Result), 0);
  Result[1] := AMarker;
  // the first actor has a next one, the last has none; their states are numbers
  Result[PLANES_AND_STATE_SIZE + 72] := 1;
  Result[PLANES_AND_STATE_SIZE + 30] := 14;
end;

{ TRecordingHooks }

function TRecordingHooks.LoadGame(AStream: TStream): Boolean;
begin
  LoadedAt := Integer(AStream.Position);
  Inc(Loads);
  Result := True;
end;

function TRecordingHooks.SaveGame(AStream: TStream): Boolean;
begin
  Result := True;
end;

procedure TRecordingHooks.ResetGame;
begin
end;

{ TTestKeenSaveFormat }

function TTestKeenSaveFormat.MakeFile(AHeaderSize, AVersion: Integer; const AStates: array of Word): TBytes;
var
  LCount: Integer;
  LActor: Integer;
  LAt: Integer;
begin
  LCount := Length(AStates);
  SetLength(Result, AHeaderSize + PLANES_AND_STATE_SIZE + LCount * SizeOf(TKeenSaveObject));
  Result[0] := Ord('K');
  Result[1] := Ord('D');
  Result[2] := Ord('R');
  if AHeaderSize = 40 then
    Result[5] := Byte(AVersion);
  Result[6] := Ord('x');
  for LActor := 0 to LCount - 1 do
  begin
    LAt := AHeaderSize + PLANES_AND_STATE_SIZE + LActor * SizeOf(TKeenSaveObject);
    Result[LAt + 30] := Byte(AStates[LActor]);
    Result[LAt + 31] := Byte(AStates[LActor] shr 8);
    // a link to the next actor in all but the last one
    if LActor < LCount - 1 then
      Result[LAt + 72] := 1;
  end;
end;

procedure TTestKeenSaveFormat.UnFileConLaVersioneDovrebbeEssereQuelloCorrente;
begin
  Assert.AreEqual(Ord(ksvCurrent), Ord(TKeenSaveFormat.Detect(MakeFile(40, KEEN_SAVE_FORMAT_VERSION, [1, 2, 3]))));
  // whatever the states are: the version says it
  Assert.AreEqual(Ord(ksvCurrent), Ord(TKeenSaveFormat.Detect(MakeFile(40, KEEN_SAVE_FORMAT_VERSION, [$BB4, 2]))));
end;

procedure TTestKeenSaveFormat.UnFileDellaPrimaVersioneDovrebbeAvereLaTestataCorta;
begin
  Assert.AreEqual(Ord(ksvShortHeader), Ord(TKeenSaveFormat.Detect(MakeFile(39, 0, [14, 1, 40, 212]))));
end;

procedure TTestKeenSaveFormat.UnFileDelProgrammaDOSDovrebbeAvereGliIndirizziNegliStati;
begin
  Assert.AreEqual(Ord(ksvDos), Ord(TKeenSaveFormat.Detect(MakeFile(40, 0, [$D3A, $BB4, $1B82]))));
  // the DOS program writes 1 in present when the slot was in use
  Assert.AreEqual(Ord(ksvDos), Ord(TKeenSaveFormat.Detect(MakeFile(40, 1, [$D3A, $BB4]))));
end;

procedure TTestKeenSaveFormat.UnFileConUnaFirmaSbagliataNonDovrebbeEssereNulla;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile(40, KEEN_SAVE_FORMAT_VERSION, [1, 2]);
  LBytes[1] := Ord('X');
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(LBytes)));
  LBytes := MakeFile(40, KEEN_SAVE_FORMAT_VERSION, [1, 2]);
  LBytes[3] := 7;
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(LBytes)));
end;

procedure TTestKeenSaveFormat.UnFileTroppoCortoNonDovrebbeEssereNulla;
begin
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(nil)));
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(TBytes.Create(75, 68, 82, 0))));
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(Copy(MakeFile(40, 0, [$BB4, $D3A]), 0, 90))));
end;

procedure TTestKeenSaveFormat.UnFileConIPianiTroncatiNonDovrebbeEssereNulla;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile(40, 0, [$BB4, $D3A]);
  // the first plane says 600 bytes
  LBytes[40 + 60] := $58;
  LBytes[40 + 61] := $02;
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(LBytes)));
end;

procedure TTestKeenSaveFormat.UnFileConAttoriATrattiNonDovrebbeEssereNulla;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile(40, 0, [$BB4, $D3A]);
  SetLength(LBytes, Length(LBytes) - 5);
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(LBytes)));
end;

procedure TTestKeenSaveFormat.UnFileSenzaUnAttoreFinaleSenzaSeguenteNonDovrebbeEssereNulla;
var
  LBytes: TBytes;
begin
  LBytes := MakeFile(40, 0, [$BB4, $D3A]);
  LBytes[Length(LBytes) - 76 + 72] := 1;
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(LBytes)));
  // and fewer than two actors is not a game
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(MakeFile(40, 0, [$BB4]))));
end;

procedure TTestKeenSaveFormat.UnFileSenzaVersioneConStatiPiccoliATrentanoveDovrebbeEssereDellaPrimaVersione;
begin
  Assert.AreEqual(Ord(ksvShortHeader), Ord(TKeenSaveFormat.Detect(MakeFile(39, 0, [0, 213]))));
end;

procedure TTestKeenSaveFormat.UnFileSenzaVersioneENonDelPrimoFormatoNonDovrebbeEssereNulla;
begin
  // a header of 40 bytes, no version, and states that are numbers: no format of any version wrote it
  Assert.AreEqual(Ord(ksvUnknown), Ord(TKeenSaveFormat.Detect(MakeFile(40, 0, [14, 1, 40]))));
end;

procedure TTestKeenSaveFormat.LaTestataDovrebbeEssereLunga;
begin
  Assert.AreEqual(40, TKeenSaveFormat.HeaderSize(ksvCurrent));
  Assert.AreEqual(39, TKeenSaveFormat.HeaderSize(ksvShortHeader));
  Assert.AreEqual(40, TKeenSaveFormat.HeaderSize(ksvDos));
end;

procedure TTestKeenSaveFormat.LaTestataScrittaDovrebbeDareLaVersione;
var
  LSlot: TKeenSaveSlot;
  LBytes: TBytes;
begin
  LSlot.Present := True;
  LSlot.Name := 'v';
  LBytes := TKeenSaveSlots.EncodeHeader(LSlot);
  Assert.AreEqual(KEEN_SAVE_FORMAT_VERSION, Integer(LBytes[5]));
  Assert.AreEqual(1, Integer(LBytes[4]));
end;

procedure TTestKeenSaveFormat.CaricareUnFileCorrenteDovrebbePartireDopoLaTestataDi40Byte;
var
  LFiles: TUiFakeFiles;
  LKeeper: IKeenUserFiles;
  LSlots: TKeenSaveSlots;
  LHooks: TRecordingHooks;
  LHooksKeeper: IKeenGameHooks;
  LError: AnsiString;
begin
  LFiles := TUiFakeFiles.Create;
  LKeeper := LFiles;
  LFiles.Put('SAVEGM0.KDR', MakeFile(40, KEEN_SAVE_FORMAT_VERSION, [14, 1]));
  LSlots := TKeenSaveSlots.Create(LKeeper);
  try
    LHooks := TRecordingHooks.Create;
    LHooksKeeper := LHooks;
    Assert.IsTrue(LSlots.Load(0, LHooksKeeper, LError));
    Assert.AreEqual(40, LHooks.LoadedAt);
  finally
    LSlots.Free;
  end;
end;

procedure TTestKeenSaveFormat.CaricareUnFileDellaPrimaVersioneDovrebbePartireDopoLaTestataDi39Byte;
var
  LFiles: TUiFakeFiles;
  LKeeper: IKeenUserFiles;
  LSlots: TKeenSaveSlots;
  LHooks: TRecordingHooks;
  LHooksKeeper: IKeenGameHooks;
  LError: AnsiString;
begin
  LFiles := TUiFakeFiles.Create;
  LKeeper := LFiles;
  LFiles.Put('SAVEGM1.KDR', MakeFile(39, 0, [14, 1]));
  LSlots := TKeenSaveSlots.Create(LKeeper);
  try
    LHooks := TRecordingHooks.Create;
    LHooksKeeper := LHooks;
    Assert.IsTrue(LSlots.Load(1, LHooksKeeper, LError));
    Assert.AreEqual(39, LHooks.LoadedAt);
  finally
    LSlots.Free;
  end;
end;

procedure TTestKeenSaveFormat.CaricareUnFileDelProgrammaDOSDovrebbeDireDiImportarlo;
var
  LFiles: TUiFakeFiles;
  LKeeper: IKeenUserFiles;
  LSlots: TKeenSaveSlots;
  LHooks: TRecordingHooks;
  LHooksKeeper: IKeenGameHooks;
  LError: AnsiString;
begin
  LFiles := TUiFakeFiles.Create;
  LKeeper := LFiles;
  LFiles.Put('SAVEGM2.KDR', MakeFile(40, 0, [$D3A, $BB4]));
  LSlots := TKeenSaveSlots.Create(LKeeper);
  try
    LHooks := TRecordingHooks.Create;
    LHooksKeeper := LHooks;
    Assert.IsFalse(LSlots.Load(2, LHooksKeeper, LError));
    Assert.AreEqual(0, LHooks.Loads, 'the game is not loaded');
    Assert.IsTrue(Pos('-importsave', string(LError)) > 0, string(LError));
  finally
    LSlots.Free;
  end;
end;

procedure TTestKeenSaveFormat.CaricareUnFileCheNonEUnaPartitaDovrebbeDireCheEIncompleto;
var
  LFiles: TUiFakeFiles;
  LKeeper: IKeenUserFiles;
  LSlots: TKeenSaveSlots;
  LHooks: TRecordingHooks;
  LHooksKeeper: IKeenGameHooks;
  LError: AnsiString;
  LBytes: TBytes;
begin
  LFiles := TUiFakeFiles.Create;
  LKeeper := LFiles;
  // a header and nothing else
  LBytes := MakeFile(40, KEEN_SAVE_FORMAT_VERSION, [1, 2]);
  LBytes := Copy(LBytes, 0, 41);
  LBytes[5] := 0;
  LFiles.Put('SAVEGM3.KDR', LBytes);
  LSlots := TKeenSaveSlots.Create(LKeeper);
  try
    LHooks := TRecordingHooks.Create;
    LHooksKeeper := LHooks;
    Assert.IsFalse(LSlots.Load(3, LHooksKeeper, LError));
    Assert.AreEqual(AnsiString('File is Incomplete'), LError);
    Assert.AreEqual(0, LHooks.Loads);
  finally
    LSlots.Free;
  end;
end;

procedure TTestKeenSaveFormat.IlNomeDiUnFileDOSDovrebbeEssereNellaLista;
var
  LFiles: TUiFakeFiles;
  LKeeper: IKeenUserFiles;
  LSlots: TKeenSaveSlots;
begin
  LFiles := TUiFakeFiles.Create;
  LKeeper := LFiles;
  LFiles.Put('SAVEGM0.KDR', MakeFile(40, 0, [$D3A, $BB4]));
  LSlots := TKeenSaveSlots.Create(LKeeper);
  try
    LSlots.Check;
    Assert.IsTrue(LSlots.GetSlot(0).Present);
    Assert.AreEqual(AnsiString('x'), LSlots.GetSlot(0).Name);
  finally
    LSlots.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenSaveFormat);

end.
