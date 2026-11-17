{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the session block of a saved game                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.SaveGameSessionBlock;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Serializer.SaveGameSessionBlock;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerSaveGameSessionBlock = class
  strict private
    // the text of the old G_DoSaveGameInFile (Doom), copied as it was
    procedure OldWrite(const ADestination: PByte; const ASkill, AEpisode, AMap: Byte;
      const AHasEpisode: Boolean; const APlayers: array of Boolean);
  public
    [Test]
    procedure DovrebbeScrivereGliStessiByteDelVecchioCodiceConEpisodio;
    [Test]
    procedure DovrebbeScrivereGliStessiByteDelVecchioCodiceSenzaEpisodio;
    [Test]
    procedure DovrebbeDareLaDimensioneDelBlocco;
    [Test]
    procedure DovrebbeFareIlGiroDelBlocco;
    [Test]
    procedure DovrebbeLeggereUnByteDiversoDaZeroComeGiocatorePresente;
    [Test]
    procedure DovrebbeLasciareZeroLEpisodioSeNonCe;
  end;

implementation

{ TTestSerializerSaveGameSessionBlock }

procedure TTestSerializerSaveGameSessionBlock.OldWrite(const ADestination: PByte;
  const ASkill, AEpisode, AMap: Byte; const AHasEpisode: Boolean;
  const APlayers: array of Boolean);
var
  LPointer: PByteArray;
  LIndex: Integer;
begin
  LPointer := PByteArray(ADestination);
  LPointer[0] := ASkill;
  LPointer := PByteArray(NativeInt(LPointer) + 1);
  if AHasEpisode then
  begin
    LPointer[0] := AEpisode;
    LPointer := PByteArray(NativeInt(LPointer) + 1);
  end;
  LPointer[0] := AMap;
  LPointer := PByteArray(NativeInt(LPointer) + 1);
  for LIndex := 0 to High(APlayers) do
  begin
    LPointer[0] := Ord(APlayers[LIndex]);
    LPointer := PByteArray(NativeInt(LPointer) + 1);
  end;
end;

procedure TTestSerializerSaveGameSessionBlock.DovrebbeScrivereGliStessiByteDelVecchioCodiceConEpisodio;
var
  LOld, LNew: array[0..15] of Byte;
  LPlayers: array[0..3] of Boolean;
  LSkill: Integer;
begin
  LPlayers[0] := True;
  LPlayers[1] := False;
  LPlayers[2] := True;
  LPlayers[3] := False;
  for LSkill := 0 to 4 do
  begin
    FillChar(LOld, SizeOf(LOld), $AA);
    FillChar(LNew, SizeOf(LNew), $AA);
    OldWrite(@LOld[0], LSkill, 3, 17, True, LPlayers);
    TSaveGameSessionBlock.Write(@LNew[0], LSkill, 3, 17, True, LPlayers);
    Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], SizeOf(LOld)));
  end;
end;

procedure TTestSerializerSaveGameSessionBlock.DovrebbeScrivereGliStessiByteDelVecchioCodiceSenzaEpisodio;
var
  LOld, LNew: array[0..15] of Byte;
  LPlayers: array[0..3] of Boolean;
begin
  LPlayers[0] := True;
  LPlayers[1] := True;
  LPlayers[2] := False;
  LPlayers[3] := True;
  FillChar(LOld, SizeOf(LOld), $AA);
  FillChar(LNew, SizeOf(LNew), $AA);
  OldWrite(@LOld[0], 2, 9, 33, False, LPlayers);
  TSaveGameSessionBlock.Write(@LNew[0], 2, 9, 33, False, LPlayers);
  Assert.IsTrue(CompareMem(@LOld[0], @LNew[0], SizeOf(LOld)));
end;

procedure TTestSerializerSaveGameSessionBlock.DovrebbeDareLaDimensioneDelBlocco;
begin
  Assert.AreEqual<Integer>(7, TSaveGameSessionBlock.BlockSize(4, True));
  Assert.AreEqual<Integer>(6, TSaveGameSessionBlock.BlockSize(4, False));
end;

procedure TTestSerializerSaveGameSessionBlock.DovrebbeFareIlGiroDelBlocco;
var
  LBuffer: array[0..15] of Byte;
  LWritten, LRead: array[0..3] of Boolean;
  LSkill, LEpisode, LMap: Byte;
  LIndex: Integer;
begin
  LWritten[0] := False;
  LWritten[1] := True;
  LWritten[2] := True;
  LWritten[3] := False;
  TSaveGameSessionBlock.Write(@LBuffer[0], 4, 2, 31, True, LWritten);
  TSaveGameSessionBlock.Read(@LBuffer[0], True, LSkill, LEpisode, LMap, LRead);
  Assert.AreEqual<Integer>(4, LSkill);
  Assert.AreEqual<Integer>(2, LEpisode);
  Assert.AreEqual<Integer>(31, LMap);
  for LIndex := 0 to 3 do
    Assert.AreEqual(LWritten[LIndex], LRead[LIndex]);
end;

procedure TTestSerializerSaveGameSessionBlock.DovrebbeLeggereUnByteDiversoDaZeroComeGiocatorePresente;
var
  LBuffer: array[0..4] of Byte;
  LPlayers: array[0..2] of Boolean;
  LSkill, LEpisode, LMap: Byte;
begin
  LBuffer[0] := 1;
  LBuffer[1] := 5;
  LBuffer[2] := 200;
  LBuffer[3] := 0;
  LBuffer[4] := 1;
  TSaveGameSessionBlock.Read(@LBuffer[0], False, LSkill, LEpisode, LMap, LPlayers);
  Assert.AreEqual<Integer>(5, LMap);
  Assert.IsTrue(LPlayers[0]);
  Assert.IsFalse(LPlayers[1]);
  Assert.IsTrue(LPlayers[2]);
end;

procedure TTestSerializerSaveGameSessionBlock.DovrebbeLasciareZeroLEpisodioSeNonCe;
var
  LBuffer: array[0..4] of Byte;
  LPlayers: array[0..1] of Boolean;
  LSkill, LEpisode, LMap: Byte;
begin
  FillChar(LBuffer, SizeOf(LBuffer), 7);
  TSaveGameSessionBlock.Read(@LBuffer[0], False, LSkill, LEpisode, LMap, LPlayers);
  Assert.AreEqual<Integer>(0, LEpisode);
end;

end.
