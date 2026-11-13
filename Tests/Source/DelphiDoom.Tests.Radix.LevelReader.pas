{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TRadixLevelReader and of the records of a level        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Radix.LevelReader;

interface

uses
  System.SysUtils, DUnitX.TestFramework,
  DelphiDoom.Radix.Types, DelphiDoom.Radix.Level.Types, DelphiDoom.Radix.Level.Data,
  DelphiDoom.Radix.Level.Intf, DelphiDoom.Radix.Level.Reader, DelphiDoom.Tests.Radix.LevelBuilder;

type
  [TestFixture]
  [Category('radix')]
  TTestRadixLevelReader = class(TObject)
  strict private
    FReader: IRadixLevelReader;
    FBuilder: TRadixLevelBuilder;
    FLevel: TRadixLevelData;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiRecordDelFile;
    [Test]
    procedure DovrebbeAvereLeDimensioniDeiRecordDiDoom;
    [Test]
    procedure DovrebbeDareNilSeIlNumeroMagicoNonC;
    [Test]
    procedure DovrebbeDareNilSeMancaLIntestazione;
    [Test]
    procedure DovrebbeSollevareSeIlLivelloEPiuCortoDelDichiarato;
    [Test]
    procedure DovrebbeLeggereSettoriMuriECose;
    [Test]
    procedure DovrebbeLeggereLaGrigliaDeiTrigger;
    [Test]
    procedure DovrebbeLeggereLaGrigliaDi1280x32SeLaMappaNonEOrtogonale;
    [Test]
    procedure DovrebbeLeggereIParametriDelleAzioni;
    [Test]
    procedure DovrebbeLeggereLeAzioniDeiTrigger;
    [Test]
    procedure DovrebbeLeggereLePartenzeDeiGiocatori;
    [Test]
    procedure DovrebbeRifiutareUnTriggerConTroppeAzioni;
  end;

implementation

{ TTestRadixLevelReader }

procedure TTestRadixLevelReader.Setup;
begin
  FReader := TRadixLevelReader.Create;
  FBuilder := TRadixLevelBuilder.Create;
  FLevel := nil;
end;

procedure TTestRadixLevelReader.TearDown;
begin
  FLevel.Free;
  FBuilder.Free;
end;

procedure TTestRadixLevelReader.DovrebbeAvereLeDimensioniDeiRecordDelFile;
begin
  Assert.AreEqual(73, SizeOf(TRadixLevelHeader));
  Assert.AreEqual(142, SizeOf(TRadixLevelSector));
  Assert.AreEqual(86, SizeOf(TRadixLevelWall));
  Assert.AreEqual(34, SizeOf(TRadixLevelThing));
  Assert.AreEqual(168, SizeOf(TRadixLevelAction));
  Assert.AreEqual(12, SizeOf(TRadixLevelTriggerAction));
  Assert.AreEqual(34 + 150 * 12, SizeOf(TRadixLevelTrigger));
  Assert.AreEqual(13, SizeOf(TRadixLevelPlayerStart));
  Assert.AreEqual(8 + 2 * RADIX_GRID_SIZE, SizeOf(TRadixLevelGrid));
  Assert.AreEqual(4 * RADIX_GRID_SIZE, SizeOf(TRadixLevelMapPoints));
end;

procedure TTestRadixLevelReader.DovrebbeAvereLeDimensioniDeiRecordDiDoom;
begin
  Assert.AreEqual(10, SizeOf(TRadixDoomThing));
  Assert.AreEqual(10, SizeOf(TRadixDoomThingExtra));
  Assert.AreEqual(14, SizeOf(TRadixDoomLineDef));
  Assert.AreEqual(30, SizeOf(TRadixDoomSideDef));
  Assert.AreEqual(4, SizeOf(TRadixDoomVertex));
  Assert.AreEqual(26, SizeOf(TRadixDoomSector));
end;

procedure TTestRadixLevelReader.DovrebbeDareNilSeIlNumeroMagicoNonC;
var
  LBytes: TBytes;
begin
  LBytes := FBuilder.ToBytes;
  LBytes[0] := LBytes[0] xor 1;
  Assert.IsNull(FReader.TryRead('E1M1', LBytes));
end;

procedure TTestRadixLevelReader.DovrebbeDareNilSeMancaLIntestazione;
begin
  Assert.IsNull(FReader.TryRead('E1M1', [1, 2, 3]));
end;

procedure TTestRadixLevelReader.DovrebbeSollevareSeIlLivelloEPiuCortoDelDichiarato;
var
  LBytes: TBytes;
begin
  FBuilder.AddSector(0, 128, 0, 0, 10, 0);
  LBytes := FBuilder.ToBytes;
  SetLength(LBytes, 100);
  Assert.WillRaise(
    procedure
    begin
      FReader.TryRead('E1M1', LBytes);
    end, ERadixException);
end;

procedure TTestRadixLevelReader.DovrebbeLeggereSettoriMuriECose;
begin
  FBuilder.AddSector(0, 128, 3, 4, 10, RSF_FOG);
  FBuilder.AddSector(16, 256, 5, 6, 20, 0);
  FBuilder.AddWall(100, 200, 300, 400, 0, 1, RWF_SINGLESIDED);
  FBuilder.AddThing(500, 600, 7, 9, 2, 64);
  FLevel := FReader.TryRead('E1M1', FBuilder.ToBytes);
  Assert.IsNotNull(FLevel);
  Assert.AreEqual('E1M1', FLevel.Name);
  Assert.AreEqual<Integer>(2, Length(FLevel.Sectors));
  Assert.AreEqual(Integer(128), Integer(FLevel.Sectors[0].CeilingHeight));
  Assert.AreEqual(Integer(5), Integer(FLevel.Sectors[1].FloorTexture));
  Assert.AreEqual<Integer>(1, Length(FLevel.Walls));
  Assert.AreEqual(300, FLevel.Walls[0].V2X);
  Assert.AreEqual(Integer(1), Integer(FLevel.Walls[0].BackSector));
  Assert.AreEqual<Integer>(1, Length(FLevel.Things));
  Assert.AreEqual(600, FLevel.Things[0].Y);
  Assert.AreEqual(7, FLevel.Things[0].RadixType);
  Assert.AreEqual(Integer(9), Integer(FLevel.Things[0].ThingKey));
end;

procedure TTestRadixLevelReader.DovrebbeLeggereLaGrigliaDeiTrigger;
begin
  FBuilder.TriggerGridValue := 7;
  FLevel := FReader.TryRead('E1M1', FBuilder.ToBytes);
  Assert.AreEqual(320, FLevel.GridWidth);
  Assert.AreEqual(128, FLevel.GridHeight);
  Assert.AreEqual(320, FLevel.TriggerGrid.X);
  Assert.AreEqual(Integer(7), Integer(FLevel.TriggerGrid.Cells[0]));
  Assert.AreEqual(Integer(7), Integer(FLevel.TriggerGrid.Cells[319]));
  Assert.AreEqual(Integer(0), Integer(FLevel.TriggerGrid.Cells[320]));
  Assert.AreEqual(Integer(0), Integer(FLevel.TriggerGrid.Cells[RADIX_GRID_SIZE - 1]));
end;

procedure TTestRadixLevelReader.DovrebbeLeggereLaGrigliaDi1280x32SeLaMappaNonEOrtogonale;
begin
  FBuilder.Orthogonal := False;
  FBuilder.TriggerGridValue := 3;
  FLevel := FReader.TryRead('E1M1', FBuilder.ToBytes);
  Assert.AreEqual(1280, FLevel.GridWidth);
  Assert.AreEqual(32, FLevel.GridHeight);
  Assert.AreEqual(Integer(3), Integer(FLevel.TriggerGrid.Cells[1279]));
  Assert.AreEqual(Integer(0), Integer(FLevel.TriggerGrid.Cells[1280]));
end;

procedure TTestRadixLevelReader.DovrebbeLeggereIParametriDelleAzioni;
begin
  FBuilder.AddAction([11, 22, 33]);
  FBuilder.AddAction([44]);
  FLevel := FReader.TryRead('E1M1', FBuilder.ToBytes);
  Assert.AreEqual<Integer>(2, Length(FLevel.Actions));
  Assert.AreEqual(Integer(22), Integer(FLevel.Actions[0].Params[1]));
  Assert.AreEqual(Integer(33), Integer(FLevel.Actions[0].Params[2]));
  Assert.AreEqual(Integer(0), Integer(FLevel.Actions[0].Params[3]));
  Assert.AreEqual(Integer(44), Integer(FLevel.Actions[1].Params[0]));
  Assert.AreEqual(Integer(1), Integer(FLevel.Actions[1].ActionType));
end;

procedure TTestRadixLevelReader.DovrebbeLeggereLeAzioniDeiTrigger;
begin
  FBuilder.AddTrigger(2);
  FBuilder.AddTrigger(0);
  FLevel := FReader.TryRead('E1M1', FBuilder.ToBytes);
  Assert.AreEqual<Integer>(2, Length(FLevel.Triggers));
  Assert.AreEqual(2, FLevel.Triggers[0].NumActions);
  Assert.AreEqual(Integer(1), Integer(FLevel.Triggers[0].Actions[0].ActionId));
  Assert.AreEqual(Integer(2), Integer(FLevel.Triggers[0].Actions[1].ActionId));
  Assert.AreEqual(Integer(0), Integer(FLevel.Triggers[0].Actions[2].ActionId));
  Assert.AreEqual(0, FLevel.Triggers[1].NumActions);
end;

procedure TTestRadixLevelReader.DovrebbeLeggereLePartenzeDeiGiocatori;
begin
  FBuilder.SetPlayerStart(0, 10, 20, 30, 64);
  FBuilder.SetPlayerStart(7, -5, -6, -7, 255);
  FLevel := FReader.TryRead('E1M1', FBuilder.ToBytes);
  Assert.AreEqual(10, FLevel.PlayerStarts[0].X);
  Assert.AreEqual(30, FLevel.PlayerStarts[0].Z);
  Assert.AreEqual(Integer(64), Integer(FLevel.PlayerStarts[0].Angle));
  Assert.AreEqual(-6, FLevel.PlayerStarts[7].Y);
  Assert.AreEqual(Integer(255), Integer(FLevel.PlayerStarts[7].Angle));
end;

procedure TTestRadixLevelReader.DovrebbeRifiutareUnTriggerConTroppeAzioni;
var
  LBytes: TBytes;
  LPosition: Integer;
begin
  FBuilder.AddTrigger(0);
  LBytes := FBuilder.ToBytes;
  // the trigger is the last record before the player starts: its number of actions is 28 bytes in
  LPosition := Length(LBytes) - SizeOf(TRadixLevelPlayerStart) * RADIX_PLAYER_STARTS - RADIX_TRIGGER_HEADER_SIZE + 28;
  LBytes[LPosition] := $FF;
  LBytes[LPosition + 1] := $7F;
  Assert.WillRaise(
    procedure
    begin
      FReader.TryRead('E1M1', LBytes);
    end, ERadixException);
end;

end.
