{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the corpse queues of a level                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.LevelCorpses;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Thinkers.BodyQueue, DelphiDoom.Thinkers.LevelCorpses;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersLevelCorpses = class
  strict private
    FCorpses: TLevelCorpses;
    FItems: array[0..199] of Byte;
    function Item(const AIndex: Integer): Pointer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeSvuotareLaCodaDeiNemiciAlCambioDiLivello;
    [Test]
    procedure DovrebbeSvuotareLaCodaDeiGiocatoriAlCambioDiLivello;
    [Test]
    procedure DovrebbeNonRestituireCadaveriDelLivelloPrecedenteDopoTrentaduePiuUno;
    [Test]
    procedure DovrebbeTenereDistinteLeDueCode;
  end;

implementation

{ TTestThinkersLevelCorpses }

procedure TTestThinkersLevelCorpses.Setup;
begin
  FCorpses := TLevelCorpses.Create;
end;

procedure TTestThinkersLevelCorpses.TearDown;
begin
  FCorpses.Free;
end;

function TTestThinkersLevelCorpses.Item(const AIndex: Integer): Pointer;
begin
  Result := @FItems[AIndex];
end;

procedure TTestThinkersLevelCorpses.DovrebbeSvuotareLaCodaDeiNemiciAlCambioDiLivello;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 19 do
    FCorpses.Enemies.Add(Item(LIndex));
  FCorpses.Clear;
  Assert.AreEqual<Integer>(0, FCorpses.Enemies.Count);
end;

procedure TTestThinkersLevelCorpses.DovrebbeSvuotareLaCodaDeiGiocatoriAlCambioDiLivello;
var
  LIndex: Integer;
begin
  for LIndex := 0 to 19 do
    FCorpses.Players.Add(Item(LIndex));
  FCorpses.Clear;
  Assert.AreEqual<Integer>(0, FCorpses.Players.Count);
end;

procedure TTestThinkersLevelCorpses.DovrebbeNonRestituireCadaveriDelLivelloPrecedenteDopoTrentaduePiuUno;
var
  LIndex: Integer;
  LEvicted: Pointer;
begin
  // level 1: 20 corpses; level 2: 20 corpses (the objects of level 1 are freed)
  for LIndex := 0 to 19 do
    FCorpses.Enemies.Add(Item(LIndex));
  FCorpses.Clear;
  for LIndex := 20 to 39 do
  begin
    LEvicted := FCorpses.Enemies.Add(Item(LIndex));
    Assert.IsNull(LEvicted, 'a corpse of the previous level was handed back');
  end;
end;

procedure TTestThinkersLevelCorpses.DovrebbeTenereDistinteLeDueCode;
begin
  FCorpses.Players.Add(Item(0));
  Assert.AreEqual<Integer>(1, FCorpses.Players.Count);
  Assert.AreEqual<Integer>(0, FCorpses.Enemies.Count);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestThinkersLevelCorpses);

end.
