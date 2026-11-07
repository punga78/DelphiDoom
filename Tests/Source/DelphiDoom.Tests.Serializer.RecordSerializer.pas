{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the serializer library - the table and the stream      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.RecordSerializer;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Serializer.Types,
  DelphiDoom.Serializer.Intf, DelphiDoom.Tests.Serializer.Fakes;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerRecordSerializer = class(TObject)
  private
    FResolver: TFakeResolver;
    FResolverIntf: ISerializerStateResolver;
    FSerializer: ISerializer;
    FBuffer: TBytes;
    function Fresh: TGoldenRecord;
    function Save(var ARecord: TGoldenRecord): Integer;
    function Load(var ARecord: TGoldenRecord; ASize: Integer): Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeAvereUnaDimensioneIndipendenteDa32E64Bit;
    [Test]
    procedure DovrebbeContareICampiAggiunti;
    [Test]
    procedure DovrebbeSvuotareLaTabellaConClear;
    [Test]
    procedure DovrebbeScrivereSoloIlTerminatoreESeStessiITestoSeTuttoEAlDefault;
    [Test]
    procedure DovrebbeNonScrivereUnBloccoGenericoTuttoAZero;
    [Test]
    procedure DovrebbeScrivereUnBloccoGenericoNonAZero;
    [Test]
    procedure DovrebbeRileggereTuttiICampiScrittiIdenticiAlLoroValore;
    [Test]
    procedure DovrebbeRileggereUnTestoNonVuotoCarattereDopoCarattere;
    [Test]
    procedure DovrebbeRimettereIDefaultNeiCampiNonPresentiNelFlusso;
    [Test]
    procedure DovrebbeScrivereGliRiferimentiComeIndiceChiaveENumero;
    [Test]
    procedure DovrebbeNonScrivereUnMobjSenzaChiaveEUnRiferimentoNil;
    [Test]
    procedure DovrebbeLasciareILNumeriGrezziNelloSlotFinoAResolvePointers;
    [Test]
    procedure DovrebbeRisolvereIRiferimentiConResolvePointers;
    [Test]
    procedure DovrebbeRisolvereUnoStatoAssenteNelloStato0EIlGiocatoreAssenteInNil;
    [Test]
    procedure DovrebbeChiamareLaProceduraDopoLaLetturaDiOgniCampoPresente;
    [Test]
    procedure DovrebbeDareEccezioneConUnNumeroDiCampoSconosciuto;
    [Test]
    procedure DovrebbeDareEccezioneConUnFlussoTroncato;
    [Test]
    procedure DovrebbeDareEccezioneSeLaMemoriaNonBasta;
    [Test]
    procedure DovrebbeContareIByteScrittiELettiSulloStreamDaUnaPosizioneQualsiasi;
    [Test]
    procedure DovrebbeTroncareUnDefaultDiTestoOltre255Caratteri;
    [Test]
    procedure DovrebbeConfrontareIFloatConSegnoENonConDifferenzaMinima;
  end;

implementation

uses
  DelphiDoom.Serializer.Factory;

{ TTestSerializerRecordSerializer }

procedure TTestSerializerRecordSerializer.Setup;
begin
  FResolver := TFakeResolver.Create;
  FResolverIntf := FResolver;
  FSerializer := TSerializerFactory.Create(FResolver, FResolver, FResolver).CreateSerializer;
  FillGoldenTable(FSerializer);
  SetLength(FBuffer, 4096);
end;

procedure TTestSerializerRecordSerializer.TearDown;
begin
  FSerializer := nil;
  FResolverIntf := nil;
  FResolver := nil;
end;

function TTestSerializerRecordSerializer.Fresh: TGoldenRecord;
begin
  FillChar(Result, SizeOf(Result), 0);
  // the defaults of the table
  Result.Byte1 := 9;
  Result.ShortInt1 := -5;
  Result.Word1 := 300;
  Result.SmallInt1 := -2;
  Result.LongWord1 := 4000000000;
  Result.Integer1 := -1;
  Result.Int641 := Int64(1) shl 40;
  Result.Float1 := 1.5;
  Result.Text1 := 'abc';
end;

function TTestSerializerRecordSerializer.Save(var ARecord: TGoldenRecord): Integer;
begin
  Result := FSerializer.SaveToMemory(@FBuffer[0], @ARecord, Length(FBuffer));
end;

function TTestSerializerRecordSerializer.Load(var ARecord: TGoldenRecord; ASize: Integer): Integer;
begin
  Result := FSerializer.LoadFromMemory(@FBuffer[0], @ARecord, ASize);
end;

procedure TTestSerializerRecordSerializer.DovrebbeAvereUnaDimensioneIndipendenteDa32E64Bit;
begin
  // what goes in the stream has a fixed size on both platforms
  Assert.AreEqual(SizeOf(Byte), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.UnsignedByte]);
  Assert.AreEqual(SizeOf(ShortInt), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.SignedByte]);
  Assert.AreEqual(SizeOf(Word), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.UnsignedWord]);
  Assert.AreEqual(SizeOf(SmallInt), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.SignedWord]);
  Assert.AreEqual(SizeOf(Cardinal), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.UnsignedLong]);
  Assert.AreEqual(SizeOf(Integer), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.SignedLong]);
  Assert.AreEqual(SizeOf(Int64), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.SignedQuad]);
  Assert.AreEqual(SizeOf(Single), SERIALIZER_FIELD_SIZES[TSerializerFieldKind.Float]);
  Assert.AreEqual(4, SERIALIZER_FIELD_SIZES[TSerializerFieldKind.State]);
  Assert.AreEqual(4, SERIALIZER_FIELD_SIZES[TSerializerFieldKind.Mobj]);
  Assert.AreEqual(4, SERIALIZER_FIELD_SIZES[TSerializerFieldKind.Player]);
  Assert.AreEqual(255, SERIALIZER_FIELD_SIZES[TSerializerFieldKind.Text]);
  // the test record: only the three references change with the pointer
  Assert.AreEqual(58 + 3 * SizeOf(Pointer) + 256 + 256 + 4, SizeOf(TGoldenRecord));
end;

procedure TTestSerializerRecordSerializer.DovrebbeContareICampiAggiunti;
begin
  Assert.AreEqual(GOLDEN_FIELD_COUNT, FSerializer.Count);
end;

procedure TTestSerializerRecordSerializer.DovrebbeSvuotareLaTabellaConClear;
var
  LRecord: TGoldenRecord;
begin
  FSerializer.Clear;
  Assert.AreEqual(0, FSerializer.Count);
  LRecord := Fresh;
  // only the end marker
  Assert.AreEqual(2, Save(LRecord));
  Assert.AreEqual(0, Integer(FBuffer[0]) + Integer(FBuffer[1]));
end;

procedure TTestSerializerRecordSerializer.DovrebbeScrivereSoloIlTerminatoreESeStessiITestoSeTuttoEAlDefault;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  // field 21 (id $15) is Text0 (empty), field 22 (id $16) is Text1 ('abc'), then the marker
  Assert.AreEqual(11, Save(LRecord));
  Assert.AreEqual<Integer>($15, FBuffer[0]);
  Assert.AreEqual<Integer>(0, FBuffer[1]);
  Assert.AreEqual<Integer>(0, FBuffer[2]);
  Assert.AreEqual<Integer>($16, FBuffer[3]);
  Assert.AreEqual<Integer>(0, FBuffer[4]);
  Assert.AreEqual<Integer>(3, FBuffer[5]);
  Assert.AreEqual<Integer>(Ord('a'), FBuffer[6]);
  Assert.AreEqual<Integer>(Ord('c'), FBuffer[8]);
  Assert.AreEqual<Integer>(0, FBuffer[9] + FBuffer[10]);
end;

procedure TTestSerializerRecordSerializer.DovrebbeNonScrivereUnBloccoGenericoTuttoAZero;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  LRecord.Generic6[3] := 0;
  Assert.AreEqual(11, Save(LRecord));
end;

procedure TTestSerializerRecordSerializer.DovrebbeScrivereUnBloccoGenericoNonAZero;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  LRecord.Generic6[3] := 7;
  // id (2) + 6 bytes more than the all default stream
  Assert.AreEqual(11 + 8, Save(LRecord));
  Assert.AreEqual<Integer>(1, FBuffer[0]);
  Assert.AreEqual<Integer>(7, FBuffer[2 + 3]);
end;

procedure TTestSerializerRecordSerializer.DovrebbeRileggereTuttiICampiScrittiIdenticiAlLoroValore;
var
  LRecord, LRead: TGoldenRecord;
  LSize: Integer;
begin
  LRecord := Fresh;
  LRecord.Generic6[0] := 1;
  LRecord.Generic6[5] := 6;
  LRecord.Byte0 := 200;
  LRecord.Byte1 := 1;
  LRecord.ShortInt0 := -100;
  LRecord.ShortInt1 := 3;
  LRecord.Word0 := 65000;
  LRecord.Word1 := 1;
  LRecord.SmallInt0 := -30000;
  LRecord.SmallInt1 := 4;
  LRecord.LongWord0 := 4294967295;
  LRecord.LongWord1 := 0;
  LRecord.Integer0 := -2147483647;
  LRecord.Integer1 := 12345;
  LRecord.Int640 := -9000000000;
  LRecord.Int641 := 0;
  LRecord.Float0 := 3.25;
  LRecord.Float1 := -0.5;
  LRecord.Generic4[3] := 9;
  LSize := Save(LRecord);

  FillChar(LRead, SizeOf(LRead), $CC);
  Assert.AreEqual(LSize, Load(LRead, LSize));
  Assert.IsTrue(CompareMem(@LRecord.Generic6, @LRead.Generic6, 6));
  Assert.AreEqual<Integer>(200, LRead.Byte0);
  Assert.AreEqual<Integer>(1, LRead.Byte1);
  Assert.AreEqual<Integer>(-100, LRead.ShortInt0);
  Assert.AreEqual<Integer>(3, LRead.ShortInt1);
  Assert.AreEqual<Integer>(65000, LRead.Word0);
  Assert.AreEqual<Integer>(1, LRead.Word1);
  Assert.AreEqual<Integer>(-30000, LRead.SmallInt0);
  Assert.AreEqual<Integer>(4, LRead.SmallInt1);
  Assert.AreEqual<Cardinal>(4294967295, LRead.LongWord0);
  Assert.AreEqual<Cardinal>(0, LRead.LongWord1);
  Assert.AreEqual(-2147483647, LRead.Integer0);
  Assert.AreEqual(12345, LRead.Integer1);
  Assert.AreEqual<Int64>(-9000000000, LRead.Int640);
  Assert.AreEqual<Int64>(0, LRead.Int641);
  Assert.AreEqual<Single>(3.25, LRead.Float0);
  Assert.AreEqual<Single>(-0.5, LRead.Float1);
  Assert.AreEqual<Integer>(9, LRead.Generic4[3]);
end;

procedure TTestSerializerRecordSerializer.DovrebbeRileggereUnTestoNonVuotoCarattereDopoCarattere;
var
  LRecord, LRead: TGoldenRecord;
  LSize: Integer;
begin
  // regression: the old reader took 2 bytes (a Char) for each character of the text
  LRecord := Fresh;
  LRecord.Text0 := 'TRANS01';
  LRecord.Text1 := 'hello world';
  LRecord.Integer0 := 77;
  LSize := Save(LRecord);
  FillChar(LRead, SizeOf(LRead), $CC);
  Assert.AreEqual(LSize, Load(LRead, LSize));
  Assert.AreEqual('TRANS01', string(LRead.Text0));
  Assert.AreEqual('hello world', string(LRead.Text1));
  Assert.AreEqual(77, LRead.Integer0);
end;

procedure TTestSerializerRecordSerializer.DovrebbeRimettereIDefaultNeiCampiNonPresentiNelFlusso;
var
  LRecord, LRead: TGoldenRecord;
  LSize: Integer;
begin
  LRecord := Fresh;
  LSize := Save(LRecord);
  FillChar(LRead, SizeOf(LRead), $CC);
  Load(LRead, LSize);
  Assert.AreEqual<Integer>(0, LRead.Byte0);
  Assert.AreEqual<Integer>(9, LRead.Byte1);
  Assert.AreEqual<Integer>(-5, LRead.ShortInt1);
  Assert.AreEqual<Integer>(300, LRead.Word1);
  Assert.AreEqual<Integer>(-2, LRead.SmallInt1);
  Assert.AreEqual<Cardinal>(4000000000, LRead.LongWord1);
  Assert.AreEqual(-1, LRead.Integer1);
  Assert.AreEqual<Int64>(Int64(1) shl 40, LRead.Int641);
  Assert.AreEqual<Single>(1.5, LRead.Float1);
  Assert.IsNull(LRead.State);
  Assert.IsNull(LRead.Mobj);
  Assert.IsNull(LRead.Player);
  Assert.AreEqual<Integer>(0, LRead.Generic6[2]);
end;

procedure TTestSerializerRecordSerializer.DovrebbeScrivereGliRiferimentiComeIndiceChiaveENumero;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  LRecord.State := TFakeResolver.StatePointer(300);
  LRecord.Mobj := TFakeResolver.MobjPointer(1000);
  LRecord.Player := TFakeResolver.PlayerPointer(3);
  // state: id 18 ($12), mobj: $13, player: $14, each followed by 4 bytes; then the all default stream
  Assert.AreEqual(11 + 3 * 6, Save(LRecord));
  Assert.AreEqual<Integer>($12, FBuffer[0]);
  Assert.AreEqual<Integer>(300 and $FF, FBuffer[2]);
  Assert.AreEqual<Integer>(300 shr 8, FBuffer[3]);
  Assert.AreEqual<Integer>($13, FBuffer[6]);
  Assert.AreEqual<Integer>(1000 and $FF, FBuffer[8]);
  Assert.AreEqual<Integer>($14, FBuffer[12]);
  Assert.AreEqual<Integer>(3, FBuffer[14]);
end;

procedure TTestSerializerRecordSerializer.DovrebbeNonScrivereUnMobjSenzaChiaveEUnRiferimentoNil;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  // a mobj whose key is 0 is not written
  LRecord.Mobj := TFakeResolver.MobjPointer(0);
  Assert.AreEqual(11, Save(LRecord));
  LRecord.Mobj := nil;
  Assert.AreEqual(11, Save(LRecord));
end;

procedure TTestSerializerRecordSerializer.DovrebbeLasciareILNumeriGrezziNelloSlotFinoAResolvePointers;
var
  LRecord, LRead: TGoldenRecord;
  LSize: Integer;
begin
  LRecord := Fresh;
  LRecord.State := TFakeResolver.StatePointer(300);
  LRecord.Mobj := TFakeResolver.MobjPointer(1000);
  LRecord.Player := TFakeResolver.PlayerPointer(3);
  LSize := Save(LRecord);
  FillChar(LRead, SizeOf(LRead), $CC);
  Load(LRead, LSize);
  Assert.AreEqual<Cardinal>(300, PCardinal(@LRead.State)^);
  Assert.AreEqual<Cardinal>(1000, PCardinal(@LRead.Mobj)^);
  Assert.AreEqual<Cardinal>(3, PCardinal(@LRead.Player)^);
  Assert.AreEqual<Integer>(0, Length(FResolver.Asked));
end;

procedure TTestSerializerRecordSerializer.DovrebbeRisolvereIRiferimentiConResolvePointers;
var
  LRecord, LRead: TGoldenRecord;
  LSize: Integer;
begin
  LRecord := Fresh;
  LRecord.State := TFakeResolver.StatePointer(300);
  LRecord.Mobj := TFakeResolver.MobjPointer(1000);
  LRecord.Player := TFakeResolver.PlayerPointer(3);
  LSize := Save(LRecord);
  FillChar(LRead, SizeOf(LRead), $CC);
  Load(LRead, LSize);
  FSerializer.ResolvePointers(@LRead);
  Assert.AreEqual<NativeUInt>(NativeUInt(LRecord.State), NativeUInt(LRead.State));
  Assert.AreEqual<NativeUInt>(NativeUInt(LRecord.Mobj), NativeUInt(LRead.Mobj));
  Assert.AreEqual<NativeUInt>(NativeUInt(LRecord.Player), NativeUInt(LRead.Player));
end;

procedure TTestSerializerRecordSerializer.DovrebbeRisolvereUnoStatoAssenteNelloStato0EIlGiocatoreAssenteInNil;
var
  LRecord, LRead: TGoldenRecord;
  LSize: Integer;
begin
  // as the old ResolvePointers: the state is always asked, the player only when it is not 0
  LRecord := Fresh;
  LSize := Save(LRecord);
  FillChar(LRead, SizeOf(LRead), $CC);
  Load(LRead, LSize);
  FSerializer.ResolvePointers(@LRead);
  Assert.AreEqual<NativeUInt>(NativeUInt(TFakeResolver.StatePointer(0)), NativeUInt(LRead.State));
  Assert.IsNull(LRead.Mobj);
  Assert.IsNull(LRead.Player);
end;

procedure TTestSerializerRecordSerializer.DovrebbeChiamareLaProceduraDopoLaLetturaDiOgniCampoPresente;
var
  LSerializer: ISerializer;
  LRecord: PGoldenRecord;
  LCalls: Integer;
  LLast: Pointer;
  LStruct: TGoldenRecord;
  LSize: Integer;
begin
  LCalls := 0;
  LLast := nil;
  LSerializer := TSerializerFactory.Create(FResolver, FResolver, FResolver).CreateSerializer;
  LRecord := nil;
  LSerializer.AddTyped(NativeInt(@LRecord.Integer0), TSerializerFieldKind.SignedLong, 0,
    procedure(const AStruct: Pointer)
    begin
      Inc(LCalls);
      LLast := AStruct;
    end);
  LSerializer.AddTyped(NativeInt(@LRecord.Integer1), TSerializerFieldKind.SignedLong, 0);
  LStruct := Fresh;
  LStruct.Integer0 := 5;
  LSize := LSerializer.SaveToMemory(@FBuffer[0], @LStruct, Length(FBuffer));
  LSerializer.LoadFromMemory(@FBuffer[0], @LStruct, LSize);
  Assert.AreEqual(1, LCalls);
  Assert.AreEqual<NativeUInt>(NativeUInt(@LStruct), NativeUInt(LLast));
  // a record at its default does not write the field: no call
  LStruct.Integer0 := 0;
  LSize := LSerializer.SaveToMemory(@FBuffer[0], @LStruct, Length(FBuffer));
  LSerializer.LoadFromMemory(@FBuffer[0], @LStruct, LSize);
  Assert.AreEqual(1, LCalls);
end;

procedure TTestSerializerRecordSerializer.DovrebbeDareEccezioneConUnNumeroDiCampoSconosciuto;
var
  LRecord: TGoldenRecord;
begin
  FBuffer[0] := 99;
  FBuffer[1] := 0;
  Assert.WillRaise(
    procedure
    begin
      Load(LRecord, 2);
    end, ESerializerException);
end;

procedure TTestSerializerRecordSerializer.DovrebbeDareEccezioneConUnFlussoTroncato;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  LRecord.Integer0 := 5;
  Save(LRecord);
  // the stream ends in the middle of the value of a field
  Assert.WillRaise(
    procedure
    var
      LRead: TGoldenRecord;
    begin
      Load(LRead, 5);
    end, EReadError);
end;

procedure TTestSerializerRecordSerializer.DovrebbeDareEccezioneSeLaMemoriaNonBasta;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  Assert.WillRaise(
    procedure
    begin
      FSerializer.SaveToMemory(@FBuffer[0], @LRecord, 5);
    end, ESerializerException);
end;

procedure TTestSerializerRecordSerializer.DovrebbeContareIByteScrittiELettiSulloStreamDaUnaPosizioneQualsiasi;
var
  LStream: TBytesStream;
  LRecord, LRead: TGoldenRecord;
  LWritten, LReadBytes: Integer;
begin
  LStream := TBytesStream.Create;
  try
    LStream.WriteBuffer(FBuffer[0], 17);
    LRecord := Fresh;
    LRecord.Integer0 := 1;
    LWritten := FSerializer.SaveToStream(LStream, @LRecord);
    Assert.AreEqual<Int64>(17 + LWritten, LStream.Position);
    LStream.Position := 17;
    LReadBytes := FSerializer.LoadFromStream(LStream, @LRead);
    Assert.AreEqual(LWritten, LReadBytes);
    Assert.AreEqual(1, LRead.Integer0);
  finally
    LStream.Free;
  end;
end;

procedure TTestSerializerRecordSerializer.DovrebbeTroncareUnDefaultDiTestoOltre255Caratteri;
var
  LSerializer: ISerializer;
  LRecord: PGoldenRecord;
  LStruct: TGoldenRecord;
begin
  LSerializer := TSerializerFactory.Create(FResolver, FResolver, FResolver).CreateSerializer;
  LRecord := nil;
  LSerializer.AddText(NativeInt(@LRecord.Text0), AnsiString(StringOfChar('z', 300)));
  FBuffer[0] := 0;
  FBuffer[1] := 0;
  LSerializer.LoadFromMemory(@FBuffer[0], @LStruct, 2);
  Assert.AreEqual(255, Integer(Length(LStruct.Text0)));
end;

procedure TTestSerializerRecordSerializer.DovrebbeConfrontareIFloatConSegnoENonConDifferenzaMinima;
var
  LRecord: TGoldenRecord;
begin
  LRecord := Fresh;
  // -0.0 equals 0.0, so it is not written; a tiny difference is
  LRecord.Float0 := -0.0;
  Assert.AreEqual(11, Save(LRecord));
  LRecord.Float0 := 1.0E-30;
  Assert.AreEqual(11 + 6, Save(LRecord));
end;

end.
