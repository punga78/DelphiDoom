{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the recorded games of Greed32: the tape            }
{  (TGreedDemoWriter, TGreedDemoReader), the recorder and the player            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.Demo;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Greed.PlayerControl.Intf,
  DelphiDoom.Greed.CommandState, DelphiDoom.Greed.Level.Intf, DelphiDoom.Greed.Demo.Types,
  DelphiDoom.Greed.Demo.Intf, DelphiDoom.Greed.Demo.Writer, DelphiDoom.Greed.Demo.Reader,
  DelphiDoom.Greed.Demo.Recorder, DelphiDoom.Greed.Demo.Player;

type
  /// <summary>A source of commands that answers what the test says, and counts the readings</summary>
  TDemoFakeSource = class(TInterfacedObject, IGreedCommandSource)
  public
    Pressed: TGreedCommands;
    Buttons: TGreedMouseButtons;
    Typed: string;
    DeltaX, DeltaY: Integer;
    Readings: Integer;
    procedure BeginReading;
    function IsPressed(ACommand: TGreedCommand): Boolean;
    function TakeTyped(out ACharacter: Char): Boolean;
    function IsMousePressed(AButton: TGreedMouseButton): Boolean;
    procedure TakeMouseMove(out ADeltaX, ADeltaY: Integer);
  end;

  TDemoFakeClock = class(TInterfacedObject, IGreedSystemClock)
  public
    Value: Cardinal;
    function Clock: Cardinal;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedDemoTape = class(TObject)
  strict private
    FStream: TMemoryStream;
    function Header: TGreedDemoHeader;
    function Bytes: TBytes;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure LoScrittoreDovrebbeRifiutareIlFlussoNil;
    [Test]
    procedure LIntestazioneDovrebbeEssereGrdmVersioneEDieciNumeri;
    [Test]
    procedure DovrebbeRileggereLIntestazione;
    [Test]
    procedure DovrebbeRileggereUnaLetturaConOgniCampo;
    [Test]
    procedure DovrebbeScrivereUnaLetturaBytePerByte;
    [Test]
    procedure DovrebbeRileggereIGiriELOrologioNellOrdine;
    [Test]
    procedure LeRisposteUgualiDellOrologioDovrebberoEssereUnSoloRecord;
    [Test]
    procedure DopoLaFineNonDovrebbeScriverePiuNulla;
    [Test]
    procedure LaFineDovrebbeRipetersi;
    [Test]
    procedure UnNastroNonChiusoDovrebbeFinireConIlSuoUltimoRecord;
    [Test]
    procedure PeekNonDovrebbeConsumare;
    [Test]
    [TestCase('non GRDM', '0')]
    [TestCase('troppo corto', '1')]
    [TestCase('altra versione', '2')]
    [TestCase('intestazione tagliata', '3')]
    [TestCase('record tagliato', '4')]
    [TestCase('record sconosciuto', '5')]
    procedure DovrebbeRifiutareUnNastroGuasto(ACase: Integer);
    [Test]
    procedure DovrebbeRifiutareTroppiTicOTroppiCaratteri;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedDemoPlayback = class(TObject)
  strict private
    FStream: TMemoryStream;
    FWriter: TGreedDemoWriter;
    FSource: TDemoFakeSource;
    FSourceIntf: IGreedCommandSource;
    FClock: TDemoFakeClock;
    FClockIntf: IGreedSystemClock;
    FReader: TGreedDemoReader;
    function Tape: TBytes;
    function Play(AWaitForClock: Boolean): TGreedDemoPlayer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlRegistratoreDovrebbeRifiutareLeDipendenzeNil;
    [Test]
    procedure IlLettoreDelNastroDovrebbeRifiutareIlNastroNil;
    [Test]
    procedure IlRegistratoreDovrebbeDareAlGiocoCioCheLaSorgenteDice;
    [Test]
    procedure IlRegistratoreDovrebbeLeggereLaSorgenteUnaVoltaPerLettura;
    [Test]
    procedure IlMovimentoDelMouseDovrebbeEssereDatoUnaVolta;
    [Test]
    procedure IlRegistratoreDovrebbeLimitareITicDiUnGiro;
    [Test]
    procedure IlNastroDovrebbeRidareLetturaOrologioEGiri;
    [Test]
    procedure SenzaAspettareLOrologioOgniGiroDovrebbeEssereSubito;
    [Test]
    procedure AspettandoLOrologioIlGiroDovrebbeArrivareQuandoITicCiSono;
    [Test]
    procedure UnaDomandaFuoriOrdineDovrebbeMettereIlNastroFuoriPasso;
    [Test]
    procedure OltreLaFineNonDovrebbeEsserePremutoNulla;
  end;

implementation

{ TDemoFakeSource }

procedure TDemoFakeSource.BeginReading;
begin
  Inc(Readings);
end;

function TDemoFakeSource.IsPressed(ACommand: TGreedCommand): Boolean;
begin
  Result := ACommand in Pressed;
end;

function TDemoFakeSource.TakeTyped(out ACharacter: Char): Boolean;
begin
  Result := Typed <> '';
  if Result then
  begin
    ACharacter := Typed[1];
    Delete(Typed, 1, 1);
  end
  else
    ACharacter := #0;
end;

function TDemoFakeSource.IsMousePressed(AButton: TGreedMouseButton): Boolean;
begin
  Result := AButton in Buttons;
end;

procedure TDemoFakeSource.TakeMouseMove(out ADeltaX, ADeltaY: Integer);
begin
  ADeltaX := DeltaX;
  ADeltaY := DeltaY;
  DeltaX := 0;
  DeltaY := 0;
end;

{ TDemoFakeClock }

function TDemoFakeClock.Clock: Cardinal;
begin
  Result := Value;
end;

{ TTestGreedDemoTape }

procedure TTestGreedDemoTape.Setup;
begin
  FStream := TMemoryStream.Create;
end;

procedure TTestGreedDemoTape.TearDown;
begin
  FStream.Free;
end;

function TTestGreedDemoTape.Header: TGreedDemoHeader;
begin
  Result := Default(TGreedDemoHeader);
  Result.Map := 17;
  Result.Character := 3;
  Result.Difficulty := 4;
  Result.Episode := 3;
  Result.DemoEdition := False;
  Result.LowResolution := True;
  Result.RandomOffset := 201;
  Result.CameraDelay := 35;
  Result.ViewSize := 2;
  Result.Violence := True;
end;

function TTestGreedDemoTape.Bytes: TBytes;
begin
  SetLength(Result, FStream.Size);
  if FStream.Size > 0 then
    Move(FStream.Memory^, Result[0], FStream.Size);
end;

procedure TTestGreedDemoTape.LoScrittoreDovrebbeRifiutareIlFlussoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedDemoWriter.Create(nil, Default(TGreedDemoHeader));
    end, EArgumentNilException);
end;

procedure TTestGreedDemoTape.LIntestazioneDovrebbeEssereGrdmVersioneEDieciNumeri;
var
  LWriter: TGreedDemoWriter;
  LBytes: TBytes;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  try
    LBytes := Bytes;
    Assert.AreEqual(GREED_DEMO_HEADER_BYTES, Integer(Length(LBytes)));
    Assert.AreEqual(Ord('G'), Integer(LBytes[0]));
    Assert.AreEqual(Ord('R'), Integer(LBytes[1]));
    Assert.AreEqual(Ord('D'), Integer(LBytes[2]));
    Assert.AreEqual(Ord('M'), Integer(LBytes[3]));
    // little endian: the version, then the map
    Assert.AreEqual(GREED_DEMO_VERSION, Integer(LBytes[4]));
    Assert.AreEqual(0, Integer(LBytes[5]));
    Assert.AreEqual(17, Integer(LBytes[8]));
    Assert.AreEqual(0, Integer(LBytes[11]));
    Assert.AreEqual(201, Integer(LBytes[32]), 'the random offset is the seventh number');
    Assert.AreEqual(1, Integer(LBytes[44]), 'the violence is the last');
  finally
    LWriter.Free;
  end;
end;

procedure TTestGreedDemoTape.DovrebbeRileggereLIntestazione;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
  LHeader: TGreedDemoHeader;
begin
  LHeader := Header;
  LHeader.RandomOffset := -5;
  LWriter := TGreedDemoWriter.Create(FStream, LHeader);
  LWriter.Close;
  LWriter.Free;
  LReader := TGreedDemoReader.Create(Bytes);
  try
    Assert.AreEqual(17, LReader.Header.Map);
    Assert.AreEqual(3, LReader.Header.Character);
    Assert.AreEqual(4, LReader.Header.Difficulty);
    Assert.AreEqual(3, LReader.Header.Episode);
    Assert.IsFalse(LReader.Header.DemoEdition);
    Assert.IsTrue(LReader.Header.LowResolution);
    Assert.AreEqual(-5, LReader.Header.RandomOffset, 'a negative number');
    Assert.AreEqual(35, LReader.Header.CameraDelay);
    Assert.AreEqual(2, LReader.Header.ViewSize);
    Assert.IsTrue(LReader.Header.Violence);
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.PeekKind));
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.DovrebbeRileggereUnaLetturaConOgniCampo;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
  LReading: TGreedDemoReading;
  LRecord: TGreedDemoRecord;
begin
  LReading := Default(TGreedDemoReading);
  // the first and the last command, and one in each byte of the bits
  LReading.Commands := [gcNorth, gcRearView, gcMenu, gcNewSong, gcPause, gcGoalItem, gcWeapon5];
  LReading.MouseButtons := [gmbFire, gmbNorth];
  LReading.MouseDeltaX := -123456;
  LReading.MouseDeltaY := 70000;
  LReading.Typed := 'A1' + #127;
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.WriteReading(LReading);
  LWriter.WriteReading(Default(TGreedDemoReading));
  LWriter.Close;
  Assert.AreEqual(2, LWriter.Records);
  LWriter.Free;
  LReader := TGreedDemoReader.Create(Bytes);
  try
    LRecord := LReader.Next;
    Assert.AreEqual(Ord(gdrReading), Ord(LRecord.Kind));
    Assert.IsTrue(LRecord.Reading.Commands = LReading.Commands);
    Assert.IsTrue(LRecord.Reading.MouseButtons = LReading.MouseButtons);
    Assert.AreEqual(-123456, LRecord.Reading.MouseDeltaX);
    Assert.AreEqual(70000, LRecord.Reading.MouseDeltaY);
    Assert.AreEqual('A1' + #127, LRecord.Reading.Typed);
    LRecord := LReader.Next;
    Assert.AreEqual(Ord(gdrReading), Ord(LRecord.Kind));
    Assert.IsTrue(LRecord.Reading.Commands = []);
    Assert.IsTrue(LRecord.Reading.MouseButtons = []);
    Assert.AreEqual('', LRecord.Reading.Typed);
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.Next.Kind));
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.DovrebbeScrivereUnaLetturaBytePerByte;
var
  LWriter: TGreedDemoWriter;
  LReading: TGreedDemoReading;
  LBytes: TBytes;
  LStart: Integer;
begin
  LReading := Default(TGreedDemoReading);
  // gcNorth is the command 0, gcJump the 8, gcWeapon5 the last (45)
  LReading.Commands := [gcNorth, gcJump, gcWeapon5];
  LReading.MouseButtons := [gmbUse];
  LReading.MouseDeltaX := $01020304;
  LReading.MouseDeltaY := -2;
  LReading.Typed := 'Z';
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.WriteReading(LReading);
  LWriter.Free;
  LBytes := Bytes;
  LStart := GREED_DEMO_HEADER_BYTES;
  Assert.AreEqual(LStart + 1 + 6 + 1 + 4 + 4 + 1 + 1, Integer(Length(LBytes)));
  Assert.AreEqual(Ord(gdrReading), Integer(LBytes[LStart]));
  Assert.AreEqual(1, Integer(LBytes[LStart + 1]));
  Assert.AreEqual(1, Integer(LBytes[LStart + 2]));
  Assert.AreEqual(0, Integer(LBytes[LStart + 3]));
  Assert.AreEqual(1 shl (Ord(gcWeapon5) mod 8), Integer(LBytes[LStart + 1 + Ord(gcWeapon5) div 8]));
  Assert.AreEqual(2, Integer(LBytes[LStart + 7]), 'the buttons of the mouse');
  Assert.AreEqual(4, Integer(LBytes[LStart + 8]));
  Assert.AreEqual(3, Integer(LBytes[LStart + 9]));
  Assert.AreEqual(2, Integer(LBytes[LStart + 10]));
  Assert.AreEqual(1, Integer(LBytes[LStart + 11]));
  Assert.AreEqual($FE, Integer(LBytes[LStart + 12]));
  Assert.AreEqual($FF, Integer(LBytes[LStart + 15]));
  Assert.AreEqual(1, Integer(LBytes[LStart + 16]));
  Assert.AreEqual(Ord('Z'), Integer(LBytes[LStart + 17]));
end;

procedure TTestGreedDemoTape.DovrebbeRileggereIGiriELOrologioNellOrdine;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
  LRecord: TGreedDemoRecord;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.WriteFrame(0);
  LWriter.WriteClock($FFFFFFF0);
  LWriter.WriteFrame(255);
  LWriter.WriteClock(7);
  LWriter.Close;
  LWriter.Free;
  LReader := TGreedDemoReader.Create(Bytes);
  try
    LRecord := LReader.Next;
    Assert.AreEqual(Ord(gdrFrame), Ord(LRecord.Kind));
    Assert.AreEqual(0, LRecord.Tics);
    LRecord := LReader.Next;
    Assert.AreEqual(Ord(gdrClock), Ord(LRecord.Kind));
    Assert.AreEqual(Cardinal($FFFFFFF0), LRecord.Clock);
    LRecord := LReader.Next;
    Assert.AreEqual(Ord(gdrFrame), Ord(LRecord.Kind));
    Assert.AreEqual(255, LRecord.Tics);
    LRecord := LReader.Next;
    Assert.AreEqual(Ord(gdrClock), Ord(LRecord.Kind));
    Assert.AreEqual(Cardinal(7), LRecord.Clock);
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.Next.Kind));
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.LeRisposteUgualiDellOrologioDovrebberoEssereUnSoloRecord;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
  LIndex: Integer;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  for LIndex := 1 to 1000 do
    LWriter.WriteClock(42);
  LWriter.WriteClock(43);
  LWriter.WriteFrame(2);
  LWriter.WriteClock(43);
  LWriter.Close;
  Assert.AreEqual(4, LWriter.Records, 'a thousand answers are one record');
  LWriter.Free;
  // 9 bytes for each clock record, 2 for the frame, 1 for the end
  Assert.AreEqual(Int64(GREED_DEMO_HEADER_BYTES + 3 * 9 + 2 + 1), FStream.Size);
  LReader := TGreedDemoReader.Create(Bytes);
  try
    for LIndex := 1 to 1000 do
    begin
      Assert.AreEqual(Ord(gdrClock), Ord(LReader.PeekKind));
      Assert.AreEqual(Cardinal(42), LReader.Next.Clock);
    end;
    Assert.AreEqual(Cardinal(43), LReader.Next.Clock);
    Assert.AreEqual(Ord(gdrFrame), Ord(LReader.Next.Kind));
    Assert.AreEqual(Cardinal(43), LReader.Next.Clock);
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.Next.Kind));
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.DopoLaFineNonDovrebbeScriverePiuNulla;
var
  LWriter: TGreedDemoWriter;
  LSize: Int64;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  try
    LWriter.WriteFrame(1);
    Assert.IsFalse(LWriter.Closed);
    LWriter.Close;
    Assert.IsTrue(LWriter.Closed);
    LSize := FStream.Size;
    LWriter.WriteFrame(1);
    LWriter.WriteClock(5);
    LWriter.WriteReading(Default(TGreedDemoReading));
    LWriter.Close;
    Assert.AreEqual(LSize, FStream.Size);
    Assert.AreEqual(1, LWriter.Records);
  finally
    LWriter.Free;
  end;
end;

procedure TTestGreedDemoTape.LaFineDovrebbeRipetersi;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.Close;
  LWriter.Free;
  // what comes after the end is not read
  FStream.WriteData(Byte(200));
  LReader := TGreedDemoReader.Create(Bytes);
  try
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.Next.Kind));
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.Next.Kind));
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.PeekKind));
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.UnNastroNonChiusoDovrebbeFinireConIlSuoUltimoRecord;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.WriteFrame(3);
  LWriter.Free;
  LReader := TGreedDemoReader.Create(Bytes);
  try
    Assert.AreEqual(3, LReader.Next.Tics);
    Assert.AreEqual(Ord(gdrEnd), Ord(LReader.Next.Kind));
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.PeekNonDovrebbeConsumare;
var
  LWriter: TGreedDemoWriter;
  LReader: TGreedDemoReader;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.WriteFrame(9);
  LWriter.WriteFrame(8);
  LWriter.Close;
  LWriter.Free;
  LReader := TGreedDemoReader.Create(Bytes);
  try
    Assert.AreEqual(9, LReader.Peek.Tics);
    Assert.AreEqual(9, LReader.Peek.Tics);
    Assert.AreEqual(9, LReader.Next.Tics);
    Assert.AreEqual(8, LReader.Peek.Tics);
  finally
    LReader.Free;
  end;
end;

procedure TTestGreedDemoTape.DovrebbeRifiutareUnNastroGuasto(ACase: Integer);
var
  LWriter: TGreedDemoWriter;
  LBytes: TBytes;
  LReader: TGreedDemoReader;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  LWriter.WriteReading(Default(TGreedDemoReading));
  LWriter.Free;
  LBytes := Bytes;
  case ACase of
    0: LBytes[0] := Ord('X');
    1: SetLength(LBytes, 3);
    2: LBytes[4] := GREED_DEMO_VERSION + 1;
    3: SetLength(LBytes, GREED_DEMO_HEADER_BYTES - 2);
    4: SetLength(LBytes, Length(LBytes) - 3);
    5: LBytes[GREED_DEMO_HEADER_BYTES] := 99;
  end;
  Assert.WillRaise(
    procedure
    begin
      LReader := TGreedDemoReader.Create(LBytes);
      try
        LReader.Next;
      finally
        LReader.Free;
      end;
    end, EGreedDemoException);
end;

procedure TTestGreedDemoTape.DovrebbeRifiutareTroppiTicOTroppiCaratteri;
var
  LWriter: TGreedDemoWriter;
  LReading: TGreedDemoReading;
begin
  LWriter := TGreedDemoWriter.Create(FStream, Header);
  try
    Assert.WillRaise(
      procedure
      begin
        LWriter.WriteFrame(256);
      end, EGreedDemoException);
    Assert.WillRaise(
      procedure
      begin
        LWriter.WriteFrame(-1);
      end, EGreedDemoException);
    LReading := Default(TGreedDemoReading);
    LReading.Typed := StringOfChar('A', 256);
    Assert.WillRaise(
      procedure
      begin
        LWriter.WriteReading(LReading);
      end, EGreedDemoException);
    Assert.AreEqual(0, LWriter.Records);
  finally
    LWriter.Free;
  end;
end;

{ TTestGreedDemoPlayback }

procedure TTestGreedDemoPlayback.Setup;
begin
  FStream := TMemoryStream.Create;
  FWriter := TGreedDemoWriter.Create(FStream, Default(TGreedDemoHeader));
  FSource := TDemoFakeSource.Create;
  FSourceIntf := FSource;
  FClock := TDemoFakeClock.Create;
  FClockIntf := FClock;
  FReader := nil;
end;

procedure TTestGreedDemoPlayback.TearDown;
begin
  FReader.Free;
  FClockIntf := nil;
  FSourceIntf := nil;
  FWriter.Free;
  FStream.Free;
end;

function TTestGreedDemoPlayback.Tape: TBytes;
begin
  FWriter.Close;
  SetLength(Result, FStream.Size);
  Move(FStream.Memory^, Result[0], FStream.Size);
end;

function TTestGreedDemoPlayback.Play(AWaitForClock: Boolean): TGreedDemoPlayer;
begin
  FReader := TGreedDemoReader.Create(Tape);
  Result := TGreedDemoPlayer.Create(FReader, AWaitForClock);
end;

procedure TTestGreedDemoPlayback.IlRegistratoreDovrebbeRifiutareLeDipendenzeNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedDemoRecorder.Create(nil, FSourceIntf, FClockIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedDemoRecorder.Create(FWriter, nil, FClockIntf);
    end, EArgumentNilException);
  Assert.WillRaise(
    procedure
    begin
      TGreedDemoRecorder.Create(FWriter, FSourceIntf, nil);
    end, EArgumentNilException);
end;

procedure TTestGreedDemoPlayback.IlLettoreDelNastroDovrebbeRifiutareIlNastroNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TGreedDemoPlayer.Create(nil, False);
    end, EArgumentNilException);
end;

procedure TTestGreedDemoPlayback.IlRegistratoreDovrebbeDareAlGiocoCioCheLaSorgenteDice;
var
  LRecorder: IGreedCommandSource;
  LCharacter: Char;
begin
  LRecorder := TGreedDemoRecorder.Create(FWriter, FSourceIntf, FClockIntf);
  FSource.Pressed := [gcFire, gcNorth];
  FSource.Buttons := [gmbUse];
  FSource.Typed := 'GO';
  LRecorder.BeginReading;
  Assert.IsTrue(LRecorder.IsPressed(gcFire));
  Assert.IsTrue(LRecorder.IsPressed(gcNorth));
  Assert.IsFalse(LRecorder.IsPressed(gcSouth));
  Assert.IsTrue(LRecorder.IsMousePressed(gmbUse));
  Assert.IsFalse(LRecorder.IsMousePressed(gmbFire));
  Assert.IsTrue(LRecorder.TakeTyped(LCharacter));
  Assert.AreEqual('G', LCharacter);
  Assert.IsTrue(LRecorder.TakeTyped(LCharacter));
  Assert.AreEqual('O', LCharacter);
  Assert.IsFalse(LRecorder.TakeTyped(LCharacter));
  Assert.AreEqual(#0, LCharacter);
  Assert.AreEqual(1, FWriter.Records);
end;

procedure TTestGreedDemoPlayback.IlRegistratoreDovrebbeLeggereLaSorgenteUnaVoltaPerLettura;
var
  LRecorder: IGreedCommandSource;
begin
  LRecorder := TGreedDemoRecorder.Create(FWriter, FSourceIntf, FClockIntf);
  FSource.Pressed := [gcJump];
  LRecorder.BeginReading;
  // the source changes its mind: the reading is the one of the moment it was made
  FSource.Pressed := [];
  Assert.IsTrue(LRecorder.IsPressed(gcJump));
  Assert.AreEqual(1, FSource.Readings);
  LRecorder.BeginReading;
  Assert.IsFalse(LRecorder.IsPressed(gcJump));
  Assert.AreEqual(2, FSource.Readings);
end;

procedure TTestGreedDemoPlayback.IlMovimentoDelMouseDovrebbeEssereDatoUnaVolta;
var
  LRecorder: IGreedCommandSource;
  LX, LY: Integer;
begin
  LRecorder := TGreedDemoRecorder.Create(FWriter, FSourceIntf, FClockIntf);
  FSource.DeltaX := 12;
  FSource.DeltaY := -7;
  LRecorder.BeginReading;
  LRecorder.TakeMouseMove(LX, LY);
  Assert.AreEqual(12, LX);
  Assert.AreEqual(-7, LY);
  LRecorder.TakeMouseMove(LX, LY);
  Assert.AreEqual(0, LX);
  Assert.AreEqual(0, LY);
end;

procedure TTestGreedDemoPlayback.IlRegistratoreDovrebbeLimitareITicDiUnGiro;
var
  LRecorder: TGreedDemoRecorder;
  LPacer: IGreedFramePacer;
  LTics: Integer;
  LPlayer: TGreedDemoPlayer;
  LPlayerPacer: IGreedFramePacer;
begin
  LRecorder := TGreedDemoRecorder.Create(FWriter, FSourceIntf, FClockIntf);
  LPacer := LRecorder;
  Assert.IsFalse(LPacer.Finished);
  LTics := 300;
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(255, LTics);
  LTics := -4;
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(0, LTics);
  LRecorder.Close;
  LPacer := nil;
  LPlayer := Play(False);
  LPlayerPacer := LPlayer;
  LTics := 0;
  LPlayerPacer.NextFrame(LTics);
  Assert.AreEqual(255, LTics);
  LPlayerPacer.NextFrame(LTics);
  Assert.AreEqual(0, LTics);
end;

procedure TTestGreedDemoPlayback.IlNastroDovrebbeRidareLetturaOrologioEGiri;
var
  LRecorder: TGreedDemoRecorder;
  LSource: IGreedCommandSource;
  LClock: IGreedSystemClock;
  LPacer: IGreedFramePacer;
  LPlayer: TGreedDemoPlayer;
  LTics, LX, LY: Integer;
  LCharacter: Char;
begin
  // a short game: a turn of two tics with a reading and two answers of the clock, then a turn without tics
  LRecorder := TGreedDemoRecorder.Create(FWriter, FSourceIntf, FClockIntf);
  LSource := LRecorder;
  LClock := LRecorder;
  LPacer := LRecorder;
  LTics := 2;
  LPacer.NextFrame(LTics);
  FSource.Pressed := [gcEast, gcRun];
  FSource.Typed := 'K';
  FSource.DeltaX := 5;
  FSource.DeltaY := 6;
  LSource.BeginReading;
  FClock.Value := 1000;
  Assert.AreEqual(Cardinal(1000), LClock.Clock);
  FClock.Value := 1014;
  Assert.AreEqual(Cardinal(1014), LClock.Clock);
  LTics := 0;
  LPacer.NextFrame(LTics);
  LSource := nil;
  LClock := nil;
  LPacer := nil;

  LPlayer := Play(False);
  LSource := LPlayer;
  LClock := LPlayer;
  LPacer := LPlayer;
  Assert.IsFalse(LPacer.Finished);
  LTics := 99;
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(2, LTics);
  LSource.BeginReading;
  Assert.IsTrue(LSource.IsPressed(gcEast));
  Assert.IsTrue(LSource.IsPressed(gcRun));
  Assert.IsFalse(LSource.IsPressed(gcWest));
  Assert.IsTrue(LSource.TakeTyped(LCharacter));
  Assert.AreEqual('K', LCharacter);
  LSource.TakeMouseMove(LX, LY);
  Assert.AreEqual(5, LX);
  Assert.AreEqual(6, LY);
  Assert.AreEqual(Cardinal(1000), LClock.Clock);
  Assert.AreEqual(Cardinal(1014), LClock.Clock);
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(0, LTics);
  Assert.IsTrue(LPacer.Finished);
  Assert.IsFalse(LPlayer.Desynchronized);
  Assert.AreEqual(2, LPlayer.Frames);
  Assert.AreEqual(1, LPlayer.Readings);
end;

procedure TTestGreedDemoPlayback.SenzaAspettareLOrologioOgniGiroDovrebbeEssereSubito;
var
  LPlayer: TGreedDemoPlayer;
  LPacer: IGreedFramePacer;
  LTics: Integer;
begin
  FWriter.WriteFrame(7);
  LPlayer := Play(False);
  LPacer := LPlayer;
  LTics := 0;
  Assert.IsTrue(LPacer.NextFrame(LTics), 'the clock is not asked');
  Assert.AreEqual(7, LTics);
end;

procedure TTestGreedDemoPlayback.AspettandoLOrologioIlGiroDovrebbeArrivareQuandoITicCiSono;
var
  LPlayer: TGreedDemoPlayer;
  LPacer: IGreedFramePacer;
  LTics: Integer;
begin
  FWriter.WriteFrame(3);
  FWriter.WriteFrame(0);
  LPlayer := Play(True);
  LPacer := LPlayer;
  LTics := 2;
  Assert.IsFalse(LPacer.NextFrame(LTics), 'the clock is one tic short');
  Assert.AreEqual(0, LPlayer.Frames);
  LTics := 5;
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(3, LTics, 'the tics of the tape, not the ones of the clock');
  LTics := 0;
  Assert.IsTrue(LPacer.NextFrame(LTics), 'a turn without tics does not wait');
  Assert.AreEqual(0, LTics);
  Assert.IsTrue(LPacer.Finished);
end;

procedure TTestGreedDemoPlayback.UnaDomandaFuoriOrdineDovrebbeMettereIlNastroFuoriPasso;
var
  LPlayer: TGreedDemoPlayer;
  LSource: IGreedCommandSource;
  LClock: IGreedSystemClock;
  LPacer: IGreedFramePacer;
  LReading: TGreedDemoReading;
  LTics: Integer;
begin
  LReading := Default(TGreedDemoReading);
  LReading.Commands := [gcFire];
  FWriter.WriteFrame(2);
  FWriter.WriteClock(55);
  FWriter.WriteReading(LReading);
  LPlayer := Play(False);
  LSource := LPlayer;
  LClock := LPlayer;
  LPacer := LPlayer;
  LTics := 0;
  LPacer.NextFrame(LTics);
  // the tape has an answer of the clock next, the game asks for the controls
  LSource.BeginReading;
  Assert.IsTrue(LPlayer.Desynchronized);
  Assert.IsFalse(LSource.IsPressed(gcFire), 'nothing is pressed out of step');
  Assert.IsTrue(LPacer.Finished);
  Assert.AreEqual(Cardinal(0), LClock.Clock);
  LTics := 9;
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(0, LTics);
  Assert.AreEqual(0, LPlayer.Readings);
end;

procedure TTestGreedDemoPlayback.OltreLaFineNonDovrebbeEsserePremutoNulla;
var
  LPlayer: TGreedDemoPlayer;
  LSource: IGreedCommandSource;
  LClock: IGreedSystemClock;
  LPacer: IGreedFramePacer;
  LReading: TGreedDemoReading;
  LTics: Integer;
begin
  LReading := Default(TGreedDemoReading);
  LReading.Commands := [gcUse];
  FWriter.WriteClock(31);
  FWriter.WriteReading(LReading);
  LPlayer := Play(False);
  LSource := LPlayer;
  LClock := LPlayer;
  LPacer := LPlayer;
  Assert.AreEqual(Cardinal(31), LClock.Clock);
  LSource.BeginReading;
  Assert.IsTrue(LSource.IsPressed(gcUse));
  Assert.IsTrue(LPacer.Finished);
  // the game goes on asking: nothing pressed, the last clock, no tics; that is not being out of step
  LSource.BeginReading;
  Assert.IsFalse(LSource.IsPressed(gcUse));
  Assert.AreEqual(Cardinal(31), LClock.Clock);
  LTics := 4;
  Assert.IsTrue(LPacer.NextFrame(LTics));
  Assert.AreEqual(0, LTics);
  Assert.IsFalse(LPlayer.Desynchronized);
end;

end.
