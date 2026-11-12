{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the repeatable entropy            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.SwitchEntropy;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.MathCore.Intf,
  DelphiDoom.Parity.SwitchEntropy,
  DelphiDoom.Tests.Parity.Fakes;

type
  [TestFixture]
  [Category('parity')]
  TTestParitySwitchEntropy = class(TObject)
  strict private
    FSwitch: TFakeParitySwitch;
    FSwitchRef: IInterface;
    function Create(ASeed: Cardinal): IEntropySource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRifiutareUnaSorgenteNil;
    [Test]
    procedure DovrebbeRifiutareUnInterruttoreNil;
    [Test]
    procedure ConLInterruttoreSpentoDovrebbeDareLaSorgenteVera;
    [Test]
    procedure ConLInterruttoreAccesoDovrebbeDareNumeriRipetibili;
    [Test]
    procedure ConLInterruttoreAccesoDovrebbeRestareNelLimite;
    [Test]
    procedure ConLInterruttoreAccesoLaSorgenteVeraNonDovrebbeEssereUsata;
  end;

implementation

procedure TTestParitySwitchEntropy.Setup;
begin
  FSwitch := TFakeParitySwitch.Create;
  FSwitchRef := FSwitch;
end;

procedure TTestParitySwitchEntropy.TearDown;
begin
  FSwitch := nil;
  FSwitchRef := nil;
end;

function TTestParitySwitchEntropy.Create(ASeed: Cardinal): IEntropySource;
begin
  Result := TParitySwitchEntropy.Create(TFakeEntropySource.Create(77), FSwitch, ASeed);
end;

procedure TTestParitySwitchEntropy.DovrebbeRifiutareUnaSorgenteNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TParitySwitchEntropy.Create(nil, FSwitch, 1);
    end, EArgumentNilException);
end;

procedure TTestParitySwitchEntropy.DovrebbeRifiutareUnInterruttoreNil;
begin
  Assert.WillRaise(
    procedure
    begin
      TParitySwitchEntropy.Create(TFakeEntropySource.Create(1), nil, 1);
    end, EArgumentNilException);
end;

procedure TTestParitySwitchEntropy.ConLInterruttoreSpentoDovrebbeDareLaSorgenteVera;
begin
  Assert.AreEqual(77, Create(1).Next(256));
end;

procedure TTestParitySwitchEntropy.ConLInterruttoreAccesoDovrebbeDareNumeriRipetibili;
var
  LFirst: IEntropySource;
  LSecond: IEntropySource;
  LIndex: Integer;
begin
  FSwitch.Active := True;
  LFirst := Create(9);
  LSecond := Create(9);
  for LIndex := 1 to 200 do
    Assert.AreEqual(LFirst.Next(256), LSecond.Next(256));
end;

procedure TTestParitySwitchEntropy.ConLInterruttoreAccesoDovrebbeRestareNelLimite;
var
  LSource: IEntropySource;
  LIndex: Integer;
  LValue: Integer;
begin
  FSwitch.Active := True;
  LSource := Create(3);
  for LIndex := 1 to 500 do
  begin
    LValue := LSource.Next(256);
    Assert.IsTrue((LValue >= 0) and (LValue < 256));
  end;
end;

procedure TTestParitySwitchEntropy.ConLInterruttoreAccesoLaSorgenteVeraNonDovrebbeEssereUsata;
var
  LSource: IEntropySource;
  LDifferent: Boolean;
  LIndex: Integer;
begin
  // the fake real source always says 77: the repeatable one does not
  FSwitch.Active := True;
  LSource := Create(3);
  LDifferent := False;
  for LIndex := 1 to 50 do
    if LSource.Next(256) <> 77 then
      LDifferent := True;
  Assert.IsTrue(LDifferent);
end;

end.
