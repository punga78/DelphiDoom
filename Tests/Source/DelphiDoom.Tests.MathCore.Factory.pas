{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the math core library - the factory                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MathCore.Factory;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  /// <summary>TMathCoreFactory gives working objects behind the interfaces of the math core</summary>
  [TestFixture]
  [Category('mathcore')]
  TTestMathCoreFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeCreareUnRandomConIlGeneratoreDelRuntime;
    [Test]
    procedure DovrebbeCreareUnRandomConUnaSorgenteData;
    [Test]
    procedure DovrebbeCreareUnaTabellaDiHashVuota;
  end;

implementation

uses
  DelphiDoom.MathCore.Intf, DelphiDoom.MathCore.Factory;

type
  /// <summary>A source that always gives the same number</summary>
  TFixedEntropySource = class(TInterfacedObject, IEntropySource)
  strict private
    FValue: Integer;
  public
    constructor Create(const AValue: Integer);
    function Next(ARange: Integer): Integer;
  end;

{ TFixedEntropySource }

constructor TFixedEntropySource.Create(const AValue: Integer);
begin
  inherited Create;
  FValue := AValue;
end;

function TFixedEntropySource.Next(ARange: Integer): Integer;
begin
  Result := FValue mod ARange;
end;

{ TTestMathCoreFactory }

procedure TTestMathCoreFactory.DovrebbeCreareUnRandomConIlGeneratoreDelRuntime;
var
  LRandom: IGameRandom;
  LSavedSeed, LIndex, LValue: Integer;
begin
  LSavedSeed := RandSeed;
  try
    LRandom := TMathCoreFactory.CreateGameRandom;
    Assert.IsNotNull(LRandom);
    // the table numbers do not depend on the runtime generator
    Assert.AreEqual(0, LRandom.PlayIndex);
    LRandom.NextPlay;
    Assert.AreEqual(1, LRandom.PlayIndex);
    for LIndex := 1 to 100 do
    begin
      LValue := LRandom.NextUnpredictable;
      Assert.IsTrue((LValue >= 0) and (LValue < 256), 'value ' + IntToStr(LValue));
    end;
  finally
    RandSeed := LSavedSeed;
  end;
end;

procedure TTestMathCoreFactory.DovrebbeCreareUnRandomConUnaSorgenteData;
var
  LRandom: IGameRandom;
begin
  LRandom := TMathCoreFactory.CreateGameRandom(TFixedEntropySource.Create(77));
  Assert.AreEqual(77, LRandom.NextUnpredictable);
  Assert.AreEqual(77, LRandom.NextUnpredictable);
end;

procedure TTestMathCoreFactory.DovrebbeCreareUnaTabellaDiHashVuota;
var
  LTable: IStringHashTable;
begin
  LTable := TMathCoreFactory.CreateStringHashTable;
  Assert.IsNotNull(LTable);
  // an empty slot is 0, as the old table: the callers check the answer against their list
  Assert.AreEqual(0, LTable.IndexOf('STARTAN3'));
  LTable.Update('STARTAN3', 5);
  Assert.AreEqual(5, LTable.IndexOf('STARTAN3'));
end;

end.
