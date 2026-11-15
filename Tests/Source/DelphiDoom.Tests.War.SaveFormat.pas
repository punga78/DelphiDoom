{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - the format of a saved game           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.SaveFormat;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.GameHost.Types, DelphiDoom.War.Save.Types;

type
  /// <summary>The bytes of a saved game: layout, round trip, and everything that makes a file refused</summary>
  [TestFixture]
  [Category('war')]
  TTestWarSaveFormat = class(TObject)
  strict private
    function SampleContent: TWarSaveContent;
    function Sealed(const ABytes: TBytes): TBytes;
  public
    [Test]
    procedure DovrebbeAvereLeDimensioniDelFormatoSuDisco;
    [Test]
    procedure DovrebbeScrivereLaFirmaELeVersioni;
    [Test]
    procedure DovrebbeRileggereQuelloCheHaScritto;
    [Test]
    procedure DovrebbeTenereIBitDelTempoDiUnFotogramma;
    [Test]
    procedure DovrebbeTenereIModificatoriIlTastoEIlPulsante;
    [Test]
    procedure DovrebbeScrivereLaStessaSequenzaDiByteSempre;
    [Test]
    procedure DovrebbeNonSalvareGliEventiCheIlGiocoNonLegge;
    [Test]
    procedure DovrebbeSalvareUnGiocoSenzaFotogrammi;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonEUnSalvataggio;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneDelFormatoDiversa;
    [Test]
    procedure DovrebbeRifiutareLeRegoleDiUnaVersioneDiversa;
    [Test]
    procedure DovrebbeRifiutareUnFileDanneggiato;
    [Test]
    procedure DovrebbeRifiutareUnFileGiocatoConAltriDati;
    [Test]
    procedure DovrebbeRifiutareUnFileTagliatoAncheSeLaSommaTorna;
    [Test]
    procedure DovrebbeRifiutareUnEventoCheNonEsiste;
    [Test]
    procedure DovrebbeRifiutareTroppiEventiInUnFotogramma;
  end;

implementation

uses
  DelphiDoom.War.Save.Checksum, DelphiDoom.War.Save.Writer, DelphiDoom.War.Save.Reader;

const
  DATA_SIZE = 12852768;

{ TTestWarSaveFormat }

function TTestWarSaveFormat.SampleContent: TWarSaveContent;
var
  LEvent: TGameHostEvent;
begin
  Result := Default(TWarSaveContent);
  Result.Seed := 4242;
  Result.DataSize := DATA_SIZE;
  Result.StartRace := 2;
  Result.StartMission := 5;
  SetLength(Result.Frames, 3);
  Result.Frames[0].Delta := 1 / 60;
  LEvent := TGameHostEvent.Make(hekMouseMotion);
  LEvent.X := 160;
  LEvent.Y := 100;
  Result.Frames[0].Events := [LEvent];
  Result.Frames[1].Delta := 0.02;
  LEvent := TGameHostEvent.Make(hekMouseDown);
  LEvent.Button := hmbRight;
  LEvent.X := 7;
  LEvent.Y := 199;
  Result.Frames[1].Events := [LEvent];
  Result.Frames[2].Delta := 0.1;
end;

function TTestWarSaveFormat.Sealed(const ABytes: TBytes): TBytes;
var
  LChecksum: Cardinal;
begin
  // the file with a good checksum again, to reach the checks after it
  Result := Copy(ABytes);
  LChecksum := TWarSaveChecksum.Compute(Result, Length(Result) - SizeOf(Cardinal));
  Move(LChecksum, Result[Length(Result) - SizeOf(Cardinal)], SizeOf(Cardinal));
end;

procedure TTestWarSaveFormat.DovrebbeAvereLeDimensioniDelFormatoSuDisco;
begin
  Assert.AreEqual(32, SizeOf(TWarSaveHeader));
  Assert.AreEqual(6, SizeOf(TWarSaveFrameHeader));
  Assert.AreEqual(12, SizeOf(TWarSaveEventRecord));
end;

procedure TTestWarSaveFormat.DovrebbeScrivereLaFirmaELeVersioni;
var
  LBytes: TBytes;
  LHeader: TWarSaveHeader;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  Move(LBytes[0], LHeader, SizeOf(LHeader));
  Assert.IsTrue(CompareMem(@LHeader.Magic, @WAR_SAVE_MAGIC, 8));
  Assert.AreEqual<Integer>(WAR_SAVE_FORMAT_VERSION, LHeader.FormatVersion);
  Assert.AreEqual<Integer>(WAR_SAVE_MODEL_VERSION, LHeader.ModelVersion);
  Assert.AreEqual<Cardinal>(4242, LHeader.Seed);
  Assert.AreEqual<Cardinal>(DATA_SIZE, LHeader.DataSize);
  Assert.AreEqual<Integer>(2, LHeader.StartRace);
  Assert.AreEqual<Integer>(5, LHeader.StartMission);
  Assert.AreEqual<Cardinal>(3, LHeader.FrameCount);
  Assert.AreEqual<Cardinal>(2, LHeader.EventCount);
  Assert.AreEqual<Integer>(32 + 3 * 6 + 2 * 12 + 4, Length(LBytes));
end;

procedure TTestWarSaveFormat.DovrebbeRileggereQuelloCheHaScritto;
var
  LRead: TWarSaveContent;
begin
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(SampleContent), DATA_SIZE);
  Assert.AreEqual<Cardinal>(4242, LRead.Seed);
  Assert.AreEqual<Integer>(2, LRead.StartRace);
  Assert.AreEqual<Integer>(5, LRead.StartMission);
  Assert.AreEqual<Integer>(3, Length(LRead.Frames));
  Assert.AreEqual<Integer>(1, Length(LRead.Frames[0].Events));
  Assert.IsTrue(LRead.Frames[0].Events[0].Kind = hekMouseMotion);
  Assert.AreEqual(160, LRead.Frames[0].Events[0].X);
  Assert.AreEqual(100, LRead.Frames[0].Events[0].Y);
  Assert.IsTrue(LRead.Frames[1].Events[0].Kind = hekMouseDown);
  Assert.IsTrue(LRead.Frames[1].Events[0].Button = hmbRight);
  Assert.AreEqual(199, LRead.Frames[1].Events[0].Y);
  Assert.AreEqual<Integer>(0, Length(LRead.Frames[2].Events));
end;

procedure TTestWarSaveFormat.DovrebbeTenereIBitDelTempoDiUnFotogramma;
var
  LRead: TWarSaveContent;
  LContent: TWarSaveContent;
  LIndex: Integer;
begin
  LContent := SampleContent;
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), DATA_SIZE);
  for LIndex := 0 to 2 do
    Assert.AreEqual<Cardinal>(PCardinal(@LContent.Frames[LIndex].Delta)^, PCardinal(@LRead.Frames[LIndex].Delta)^,
      'il tempo e'' lo stesso Single, bit per bit');
end;

procedure TTestWarSaveFormat.DovrebbeTenereIModificatoriIlTastoEIlPulsante;
var
  LContent: TWarSaveContent;
  LEvent: TGameHostEvent;
  LRead: TGameHostEvent;
begin
  LContent := Default(TWarSaveContent);
  LContent.DataSize := DATA_SIZE;
  SetLength(LContent.Frames, 1);
  LEvent := TGameHostEvent.Make(hekKeyDown);
  LEvent.VirtualKey := $4D;
  LEvent.Character := Ord('m');
  LEvent.Modifiers := [hmShift, hmAlt];
  LContent.Frames[0].Events := [LEvent, TGameHostEvent.Make(hekActive)];
  LContent.Frames[0].Events[1].Focused := True;
  LContent.Frames[0].Events[1].Minimized := True;
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), DATA_SIZE).Frames[0].Events[0];
  Assert.AreEqual($4D, LRead.VirtualKey);
  Assert.AreEqual<Cardinal>(Ord('m'), LRead.Character);
  Assert.IsTrue(LRead.Modifiers = [hmShift, hmAlt]);
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), DATA_SIZE).Frames[0].Events[1];
  Assert.IsTrue(LRead.Focused);
  Assert.IsTrue(LRead.Minimized);
  Assert.IsTrue(LRead.Modifiers = []);
end;

procedure TTestWarSaveFormat.DovrebbeScrivereLaStessaSequenzaDiByteSempre;
var
  LFirst: TBytes;
  LSecond: TBytes;
begin
  LFirst := TWarSaveWriter.Write(SampleContent);
  LSecond := TWarSaveWriter.Write(SampleContent);
  Assert.IsTrue(CompareMem(@LFirst[0], @LSecond[0], Length(LFirst)));
  Assert.AreEqual(Length(LFirst), Length(LSecond));
end;

procedure TTestWarSaveFormat.DovrebbeNonSalvareGliEventiCheIlGiocoNonLegge;
var
  LContent: TWarSaveContent;
  LRead: TWarSaveContent;
begin
  LContent := Default(TWarSaveContent);
  LContent.DataSize := DATA_SIZE;
  SetLength(LContent.Frames, 1);
  LContent.Frames[0].Events := [TGameHostEvent.Make(hekQuit), TGameHostEvent.Make(hekMouseWheel),
    TGameHostEvent.Make(hekResize), TGameHostEvent.Make(hekKeyUp)];
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), DATA_SIZE);
  Assert.AreEqual<Integer>(1, Length(LRead.Frames[0].Events));
  Assert.IsTrue(LRead.Frames[0].Events[0].Kind = hekKeyUp);
  Assert.IsFalse(TWarSaveWriter.IsSaved(TGameHostEvent.Make(hekQuit)));
end;

procedure TTestWarSaveFormat.DovrebbeSalvareUnGiocoSenzaFotogrammi;
var
  LContent: TWarSaveContent;
  LRead: TWarSaveContent;
begin
  LContent := Default(TWarSaveContent);
  LContent.DataSize := DATA_SIZE;
  LRead := TWarSaveReader.Read(TWarSaveWriter.Write(LContent), DATA_SIZE);
  Assert.AreEqual<Integer>(0, Length(LRead.Frames));
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnFileTroppoCorto;
begin
  Assert.WillRaise(
    procedure
    begin
      TWarSaveReader.Read([1, 2, 3], DATA_SIZE);
    end, EWarSaveException);
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnFileCheNonEUnSalvataggio;
var
  LBytes: TBytes;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  LBytes[0] := Ord('X');
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(Sealed(LBytes), DATA_SIZE);
    end, EWarSaveException, 'not a saved game');
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnaVersioneDelFormatoDiversa;
var
  LBytes: TBytes;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  LBytes[8] := WAR_SAVE_FORMAT_VERSION + 1;
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(Sealed(LBytes), DATA_SIZE);
    end, EWarSaveException, 'format');
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareLeRegoleDiUnaVersioneDiversa;
var
  LBytes: TBytes;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  LBytes[10] := WAR_SAVE_MODEL_VERSION + 1;
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(Sealed(LBytes), DATA_SIZE);
    end, EWarSaveException, 'rules');
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnFileDanneggiato;
var
  LBytes: TBytes;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  LBytes[40] := LBytes[40] xor $01;
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(LBytes, DATA_SIZE);
    end, EWarSaveException, 'damaged');
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnFileGiocatoConAltriDati;
begin
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(TWarSaveWriter.Write(SampleContent), DATA_SIZE + 1);
    end, EWarSaveException, 'DATA.WAR');
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnFileTagliatoAncheSeLaSommaTorna;
var
  LBytes: TBytes;
  LCount: Cardinal;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  // the header says there are more frames than the file has
  LCount := 1000;
  Move(LCount, LBytes[24], SizeOf(LCount));
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(Sealed(LBytes), DATA_SIZE);
    end, EWarSaveException, 'cut short');
  // the number of events of a frame goes past the end
  LBytes := TWarSaveWriter.Write(SampleContent);
  LBytes[32 + 4] := 200;
  Assert.WillRaise(
    procedure
    begin
      TWarSaveReader.Read(Sealed(LBytes), DATA_SIZE);
    end, EWarSaveException);
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareUnEventoCheNonEsiste;
var
  LBytes: TBytes;
begin
  LBytes := TWarSaveWriter.Write(SampleContent);
  // the first event record starts after the header and the first frame header
  LBytes[32 + 6] := 99;
  Assert.WillRaiseWithMessageRegex(
    procedure
    begin
      TWarSaveReader.Read(Sealed(LBytes), DATA_SIZE);
    end, EWarSaveException, 'does not exist');
end;

procedure TTestWarSaveFormat.DovrebbeRifiutareTroppiEventiInUnFotogramma;
var
  LContent: TWarSaveContent;
  LEvents: TArray<TGameHostEvent>;
  LIndex: Integer;
begin
  LContent := Default(TWarSaveContent);
  SetLength(LEvents, WAR_SAVE_MAX_EVENTS_PER_FRAME + 1);
  for LIndex := 0 to High(LEvents) do
    LEvents[LIndex] := TGameHostEvent.Make(hekMouseMotion);
  SetLength(LContent.Frames, 1);
  LContent.Frames[0].Events := LEvents;
  Assert.WillRaise(
    procedure
    begin
      TWarSaveWriter.Write(LContent);
    end, EWarSaveException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarSaveFormat);

end.
