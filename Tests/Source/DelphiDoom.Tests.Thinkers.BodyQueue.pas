{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the queue of the player corpses                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Thinkers.BodyQueue;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Thinkers.BodyQueue;

type
  [TestFixture]
  [Category('thinkers')]
  TTestThinkersBodyQueue = class
  strict private
    FQueue: TBodyQueue;
    FItems: array[0..199] of Byte;
    function Item(const AIndex: Integer): Pointer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeNonRestituireNullaFinoAlTrentaduesimo;
    [Test]
    procedure DovrebbeRestituireIlPiuVecchioQuandoEPiena;
    [Test]
    procedure DovrebbeSvuotarsiConClear;
    [Test]
    procedure DovrebbeContareGliInserimenti;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceSuUnaSequenzaLunga;
  end;

implementation

{ TTestThinkersBodyQueue }

procedure TTestThinkersBodyQueue.Setup;
begin
  FQueue := TBodyQueue.Create;
end;

procedure TTestThinkersBodyQueue.TearDown;
begin
  FQueue.Free;
end;

function TTestThinkersBodyQueue.Item(const AIndex: Integer): Pointer;
begin
  Result := @FItems[AIndex];
end;

procedure TTestThinkersBodyQueue.DovrebbeNonRestituireNullaFinoAlTrentaduesimo;
var
  LIndex: Integer;
begin
  for LIndex := 0 to BODY_QUEUE_SIZE - 1 do
    Assert.IsNull(FQueue.Add(Item(LIndex)));
end;

procedure TTestThinkersBodyQueue.DovrebbeRestituireIlPiuVecchioQuandoEPiena;
var
  LIndex: Integer;
begin
  for LIndex := 0 to BODY_QUEUE_SIZE - 1 do
    FQueue.Add(Item(LIndex));
  Assert.AreEqual(NativeInt(Item(0)), NativeInt(FQueue.Add(Item(100))));
  Assert.AreEqual(NativeInt(Item(1)), NativeInt(FQueue.Add(Item(101))));
end;

procedure TTestThinkersBodyQueue.DovrebbeSvuotarsiConClear;
var
  LIndex: Integer;
begin
  for LIndex := 0 to BODY_QUEUE_SIZE do
    FQueue.Add(Item(LIndex));
  FQueue.Clear;
  Assert.AreEqual(0, FQueue.Count);
  for LIndex := 0 to BODY_QUEUE_SIZE - 1 do
    Assert.IsNull(FQueue.Add(Item(LIndex)));
end;

procedure TTestThinkersBodyQueue.DovrebbeContareGliInserimenti;
begin
  FQueue.Add(Item(1));
  FQueue.Add(Item(2));
  Assert.AreEqual(2, FQueue.Count);
end;

// The old code of g_game, copied as it was (bodyque, bodyqueslot)
procedure TTestThinkersBodyQueue.DovrebbeEssereUgualeAlVecchioCodiceSuUnaSequenzaLunga;
var
  LOldQueue: array[0..BODY_QUEUE_SIZE - 1] of Pointer;
  LOldSlot: Integer;
  LOldEvicted: Pointer;
  LNew: Pointer;
  LIndex: Integer;
begin
  LOldSlot := 0;
  for LIndex := 0 to High(FItems) do
  begin
    LOldEvicted := nil;
    if LOldSlot >= BODY_QUEUE_SIZE then
      LOldEvicted := LOldQueue[LOldSlot mod BODY_QUEUE_SIZE];
    LOldQueue[LOldSlot mod BODY_QUEUE_SIZE] := Item(LIndex);
    Inc(LOldSlot);

    LNew := FQueue.Add(Item(LIndex));
    Assert.AreEqual(NativeInt(LOldEvicted), NativeInt(LNew), 'inserimento ' + IntToStr(LIndex));
  end;
end;

end.
