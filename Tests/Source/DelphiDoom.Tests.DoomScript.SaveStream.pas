{******************************************************************************}
{                                                                              }
{  DelphiDoom: unit tests of the Doom script library - TDoomScriptSaveStream   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.DoomScript.SaveStream;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.Scanner.IdDict,
  DelphiDoom.DoomScript.Types, DelphiDoom.DoomScript.SaveStream, DelphiDoom.Tests.DoomScript.Support;

type
  [TestFixture]
  [Category('DoomScript')]
  TTestDoomScriptSaveStream = class
  private
    FStream: TMemoryStream;
    procedure Rewind;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScrivereGliInteriInLittleEndian;
    [Test]
    procedure DovrebbeRileggereOgniPrimitiva;
    [Test]
    procedure DovrebbeScrivereUnaStringaComeLunghezzaEByte;
    [Test]
    procedure DovrebbeRileggereUnDizionario;
    [Test]
    procedure DovrebbeScrivereMenoUnoPerUnDizionarioAssente;
    [Test]
    procedure DovrebbeSvuotareIlDizionarioSeIlNumeroEMenoUno;
    [Test]
    procedure DovrebbeDareErroreLeggendoOltreLaFine;
    [Test]
    procedure DovrebbeDareErrorePerUnaLunghezzaNegativa;
    [Test]
    procedure DovrebbeDareErrorePerUnaStringaPiuLungaDelFlusso;
    [Test]
    procedure DovrebbeIgnorareIBlocchiVuoti;
  end;

implementation

const
  SReadPastEnd = 'idRestoreGame: read past the end of the save data';

procedure TTestDoomScriptSaveStream.Setup;
begin
  FStream := TMemoryStream.Create;
end;

procedure TTestDoomScriptSaveStream.TearDown;
begin
  FStream.Free;
end;

procedure TTestDoomScriptSaveStream.Rewind;
begin
  FStream.Position := 0;
end;

procedure TTestDoomScriptSaveStream.DovrebbeScrivereGliInteriInLittleEndian;
var
  LBytes: PByte;
begin
  TDoomScriptSaveStream.WriteInt(FStream, $01020304);
  Assert.AreEqual<Int64>(4, FStream.Size);
  LBytes := FStream.Memory;
  Assert.AreEqual(4, Integer(LBytes[0]));
  Assert.AreEqual(1, Integer(LBytes[3]));
end;

procedure TTestDoomScriptSaveStream.DovrebbeRileggereOgniPrimitiva;
var
  LFloat: Single;
  LVector: TIdVec3;
  LData: array[0..2] of Byte;
  LRead: array[0..2] of Byte;
begin
  LFloat := 1.5;
  LData[0] := 7;
  LData[1] := 8;
  LData[2] := 9;
  TDoomScriptSaveStream.WriteInt(FStream, -123456);
  TDoomScriptSaveStream.WriteByte(FStream, 200);
  TDoomScriptSaveStream.WriteBool(FStream, True);
  TDoomScriptSaveStream.WriteBool(FStream, False);
  TDoomScriptSaveStream.WriteFloat(FStream, LFloat);
  TDoomScriptSaveStream.WriteVec3(FStream, TIdVec3.Create(1, -2, 3.25));
  TDoomScriptSaveStream.WriteString(FStream, 'hello');
  TDoomScriptSaveStream.WriteString(FStream, '');
  TDoomScriptSaveStream.WriteBytes(FStream, @LData[0], 3);
  Assert.AreEqual<Int64>(4 + 1 + 1 + 1 + 4 + 12 + 4 + 5 + 4 + 3, FStream.Size);
  Rewind;
  Assert.AreEqual(-123456, TDoomScriptSaveStream.ReadInt(FStream));
  Assert.AreEqual(200, Integer(TDoomScriptSaveStream.ReadByte(FStream)));
  Assert.IsTrue(TDoomScriptSaveStream.ReadBool(FStream));
  Assert.IsFalse(TDoomScriptSaveStream.ReadBool(FStream));
  Assert.IsTrue(TDoomScriptSaveStream.ReadFloat(FStream) = LFloat);
  LVector := TDoomScriptSaveStream.ReadVec3(FStream);
  Assert.IsTrue((LVector.X = 1) and (LVector.Y = -2) and (LVector.Z = 3.25));
  Assert.AreEqual('hello', string(TDoomScriptSaveStream.ReadString(FStream)));
  Assert.AreEqual('', string(TDoomScriptSaveStream.ReadString(FStream)));
  TDoomScriptSaveStream.ReadBytes(FStream, @LRead[0], 3);
  Assert.AreEqual(7, Integer(LRead[0]));
  Assert.AreEqual(9, Integer(LRead[2]));
  Assert.AreEqual<Int64>(FStream.Size, FStream.Position);
end;

procedure TTestDoomScriptSaveStream.DovrebbeScrivereUnaStringaComeLunghezzaEByte;
var
  LBytes: PByte;
begin
  TDoomScriptSaveStream.WriteString(FStream, 'ab');
  Assert.AreEqual<Int64>(6, FStream.Size);
  LBytes := FStream.Memory;
  Assert.AreEqual(2, Integer(LBytes[0]));
  Assert.AreEqual(0, Integer(LBytes[3]));
  Assert.AreEqual(Ord('a'), Integer(LBytes[4]));
  Assert.AreEqual(Ord('b'), Integer(LBytes[5]));
end;

procedure TTestDoomScriptSaveStream.DovrebbeRileggereUnDizionario;
var
  LDict: TIdDict;
  LRead: TIdDict;
begin
  LDict := TIdDict.Create;
  LRead := TIdDict.Create;
  try
    LDict.SetValue('classname', 'monster');
    LDict.SetValue('origin', '1 2 3');
    LRead.SetValue('old', 'value');
    TDoomScriptSaveStream.WriteDict(FStream, LDict);
    Rewind;
    Assert.AreEqual(2, TDoomScriptSaveStream.ReadInt(FStream));
    Rewind;
    TDoomScriptSaveStream.ReadDict(FStream, LRead);
    Assert.AreEqual(2, LRead.GetNumKeyVals);
    Assert.AreEqual('monster', string(LRead.GetString('classname')));
    Assert.AreEqual('1 2 3', string(LRead.GetString('origin')));
    Assert.AreEqual('', string(LRead.GetString('old')));
  finally
    LRead.Free;
    LDict.Free;
  end;
end;

procedure TTestDoomScriptSaveStream.DovrebbeScrivereMenoUnoPerUnDizionarioAssente;
begin
  TDoomScriptSaveStream.WriteDict(FStream, nil);
  Assert.AreEqual<Int64>(4, FStream.Size);
  Rewind;
  Assert.AreEqual(-1, TDoomScriptSaveStream.ReadInt(FStream));
end;

procedure TTestDoomScriptSaveStream.DovrebbeSvuotareIlDizionarioSeIlNumeroEMenoUno;
var
  LDict: TIdDict;
begin
  LDict := TIdDict.Create;
  try
    LDict.SetValue('old', 'value');
    TDoomScriptSaveStream.WriteDict(FStream, nil);
    Rewind;
    TDoomScriptSaveStream.ReadDict(FStream, LDict);
    Assert.AreEqual(0, LDict.GetNumKeyVals);
  finally
    LDict.Free;
  end;
end;

procedure TTestDoomScriptSaveStream.DovrebbeDareErroreLeggendoOltreLaFine;
var
  LDict: TIdDict;
begin
  TDoomScriptSaveStream.WriteByte(FStream, 1);
  TDoomScriptSaveStream.WriteByte(FStream, 2);
  Rewind;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptSaveStream.ReadInt(FStream);
    end, EDoomScriptError, SReadPastEnd);
  FStream.Position := FStream.Size;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptSaveStream.ReadByte(FStream);
    end, EDoomScriptError, SReadPastEnd);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptSaveStream.ReadFloat(FStream);
    end, EDoomScriptError, SReadPastEnd);
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptSaveStream.ReadVec3(FStream);
    end, EDoomScriptError, SReadPastEnd);
  // a dictionary that says it has more pairs than the stream holds
  FStream.Clear;
  TDoomScriptSaveStream.WriteInt(FStream, 3);
  TDoomScriptSaveStream.WriteString(FStream, 'key');
  Rewind;
  LDict := TIdDict.Create;
  try
    TDoomScriptTestSupport.ExpectError(
      procedure
      begin
        TDoomScriptSaveStream.ReadDict(FStream, LDict);
      end, EDoomScriptError, SReadPastEnd);
  finally
    LDict.Free;
  end;
end;

procedure TTestDoomScriptSaveStream.DovrebbeDareErrorePerUnaLunghezzaNegativa;
begin
  TDoomScriptSaveStream.WriteInt(FStream, -5);
  Rewind;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptSaveStream.ReadString(FStream);
    end, EDoomScriptError, 'idRestoreGame::ReadString: invalid length (-5)');
end;

procedure TTestDoomScriptSaveStream.DovrebbeDareErrorePerUnaStringaPiuLungaDelFlusso;
begin
  TDoomScriptSaveStream.WriteInt(FStream, 1000000000);
  TDoomScriptSaveStream.WriteByte(FStream, Ord('x'));
  Rewind;
  TDoomScriptTestSupport.ExpectError(
    procedure
    begin
      TDoomScriptSaveStream.ReadString(FStream);
    end, EDoomScriptError, SReadPastEnd);
end;

procedure TTestDoomScriptSaveStream.DovrebbeIgnorareIBlocchiVuoti;
var
  LByte: Byte;
begin
  LByte := 5;
  TDoomScriptSaveStream.WriteBytes(FStream, @LByte, 0);
  TDoomScriptSaveStream.WriteBytes(FStream, nil, -1);
  Assert.AreEqual<Int64>(0, FStream.Size);
  // nothing is read, so the end of the stream is not an error
  TDoomScriptSaveStream.ReadBytes(FStream, @LByte, 0);
  Assert.AreEqual(5, Integer(LByte));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDoomScriptSaveStream);

end.
