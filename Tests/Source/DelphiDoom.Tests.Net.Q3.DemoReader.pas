{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the demo reader of Quake III (DUnitX)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Net.Q3.DemoReader;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Net.Q3.Types, DelphiDoom.Net.Q3.DemoReader,
  DelphiDoom.Net.Q3.Factory, DelphiDoom.Tests.Net.Q3Fakes;

type
  /// <summary>The container of a demo: sequence, length and bytes of every message, the length -1 at the end</summary>
  [TestFixture]
  [Category('net')]
  TTestQ3DemoReader = class
  strict private
    FStream: TMemoryStream;
    FLog: TFakeQ3Log;
    FLogIntf: IInterface;
    procedure WriteInteger(AValue: Integer);
    procedure WriteMessage(ASequence: Integer; const ABytes: array of Byte);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeRifiutareUnFlussoNil;
    [Test]
    procedure DovrebbeLeggereIMessaggiInOrdine;
    [Test]
    procedure DovrebbeFinireConLaLunghezzaMenoUno;
    [Test]
    procedure DovrebbeFinireSenzaDatiInFondo;
    [Test]
    procedure DovrebbeFinireSeLaLunghezzaMancaDelTutto;
    [Test]
    procedure DovrebbeLeggereUnMessaggioVuoto;
    [Test]
    procedure DovrebbeSegnalareUnMessaggioTroncatoEAvvisare;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaOltreIlMassimo;
    [Test]
    procedure DovrebbeRifiutareUnaLunghezzaNegativaDiversaDaMenoUno;
    [Test]
    procedure DovrebbeCrearsiDallaFabbrica;
  end;

implementation

procedure TTestQ3DemoReader.Setup;
begin
  FStream := TMemoryStream.Create;
  FLog := TFakeQ3Log.Create;
  FLogIntf := FLog;
end;

procedure TTestQ3DemoReader.TearDown;
begin
  FLogIntf := nil;
  FStream.Free;
end;

procedure TTestQ3DemoReader.WriteInteger(AValue: Integer);
begin
  FStream.WriteBuffer(AValue, 4);
end;

procedure TTestQ3DemoReader.WriteMessage(ASequence: Integer; const ABytes: array of Byte);
begin
  WriteInteger(ASequence);
  WriteInteger(Length(ABytes));
  if Length(ABytes) > 0 then
    FStream.WriteBuffer(ABytes[0], Length(ABytes));
end;

procedure TTestQ3DemoReader.DovrebbeRifiutareUnFlussoNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TQ3DemoReader.Create(nil).Free;
    end,
    EArgumentNilException);
end;

procedure TTestQ3DemoReader.DovrebbeLeggereIMessaggiInOrdine;
var
  LReader: TQ3DemoReader;
  LSequence: Integer;
  LData: TBytes;
begin
  WriteMessage(7, [1, 2, 3]);
  WriteMessage(8, [9]);
  WriteInteger(0);
  WriteInteger(-1);
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.AreEqual(Ord(drMessage), Ord(LReader.ReadMessage(LSequence, LData)));
    Assert.AreEqual(7, LSequence);
    Assert.AreEqual<Integer>(3, Length(LData));
    Assert.AreEqual(Byte(3), LData[2]);
    Assert.AreEqual(Ord(drMessage), Ord(LReader.ReadMessage(LSequence, LData)));
    Assert.AreEqual(8, LSequence);
    Assert.AreEqual(Byte(9), LData[0]);
    Assert.AreEqual(Ord(drEnd), Ord(LReader.ReadMessage(LSequence, LData)));
    Assert.AreEqual(2, LReader.MessageCount);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeFinireConLaLunghezzaMenoUno;
var
  LReader: TQ3DemoReader;
  LSequence: Integer;
  LData: TBytes;
begin
  WriteInteger(5);
  WriteInteger(-1);
  WriteMessage(6, [1]);
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.AreEqual(Ord(drEnd), Ord(LReader.ReadMessage(LSequence, LData)));
    Assert.AreEqual<Integer>(0, Length(LData));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeFinireSenzaDatiInFondo;
var
  LReader: TQ3DemoReader;
  LSequence: Integer;
  LData: TBytes;
begin
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.AreEqual(Ord(drEnd), Ord(LReader.ReadMessage(LSequence, LData)));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeFinireSeLaLunghezzaMancaDelTutto;
var
  LReader: TQ3DemoReader;
  LSequence: Integer;
  LData: TBytes;
begin
  WriteInteger(3);
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.AreEqual(Ord(drEnd), Ord(LReader.ReadMessage(LSequence, LData)));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeLeggereUnMessaggioVuoto;
var
  LReader: TQ3DemoReader;
  LSequence: Integer;
  LData: TBytes;
begin
  WriteMessage(4, []);
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.AreEqual(Ord(drMessage), Ord(LReader.ReadMessage(LSequence, LData)));
    Assert.AreEqual(4, LSequence);
    Assert.AreEqual<Integer>(0, Length(LData));
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeSegnalareUnMessaggioTroncatoEAvvisare;
var
  LReader: TQ3DemoReader;
  LSequence: Integer;
  LData: TBytes;
begin
  WriteInteger(1);
  WriteInteger(10);
  WriteInteger(0); // only 4 of the 10 bytes
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream, FLog);
  try
    Assert.AreEqual(Ord(drTruncated), Ord(LReader.ReadMessage(LSequence, LData)));
    Assert.AreEqual(SQ3DemoTruncated, FLog.Infos[0]);
    Assert.AreEqual(0, LReader.MessageCount);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeRifiutareUnaLunghezzaOltreIlMassimo;
var
  LReader: TQ3DemoReader;
begin
  WriteInteger(1);
  WriteInteger(Q3_MAX_MSGLEN + 1);
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.WillRaise(
      procedure
      var
        LSequence: Integer;
        LData: TBytes;
      begin
        LReader.ReadMessage(LSequence, LData);
      end,
      EQ3DemoException);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeRifiutareUnaLunghezzaNegativaDiversaDaMenoUno;
var
  LReader: TQ3DemoReader;
begin
  WriteInteger(1);
  WriteInteger(-2);
  FStream.Position := 0;
  LReader := TQ3DemoReader.Create(FStream);
  try
    Assert.WillRaise(
      procedure
      var
        LSequence: Integer;
        LData: TBytes;
      begin
        LReader.ReadMessage(LSequence, LData);
      end,
      EQ3DemoException);
  finally
    LReader.Free;
  end;
end;

procedure TTestQ3DemoReader.DovrebbeCrearsiDallaFabbrica;
var
  LReader: TQ3DemoReader;
begin
  LReader := TQ3NetFactory.CreateDemoReader(FStream);
  try
    Assert.IsNotNull(LReader);
  finally
    LReader.Free;
  end;
end;

end.
