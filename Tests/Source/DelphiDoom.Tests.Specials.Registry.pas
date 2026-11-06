{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the registry of the specials                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Specials.Registry;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Specials.Intf;

type
  [TestFixture]
  [Category('specials')]
  TTestSpecialsRegistry = class(TObject)
  private
    FRegistry: ISpecialRegistry;
    function ContextOf(ANumber: Integer): TSpecialContext;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestUnknownSpecialDoesNothing;
    [Test]
    procedure TestRegisteredSpecialRunsAndGivesItsResult;
    [Test]
    procedure TestHandlerReceivesTheContext;
    [Test]
    procedure TestOnlyTheRightHandlerRuns;
    [Test]
    procedure TestSameNumberTwiceIsAnError;
    [Test]
    procedure TestHandlerThatIsNilIsAnError;
    [Test]
    procedure TestNumbersAreSorted;
    [Test]
    procedure TestContains;
  end;

implementation

uses
  DelphiDoom.Specials.Factory;

{ TTestSpecialsRegistry }

procedure TTestSpecialsRegistry.Setup;
begin
  FRegistry := TSpecialsFactory.CreateRegistry;
end;

procedure TTestSpecialsRegistry.TearDown;
begin
  FRegistry := nil;
end;

function TTestSpecialsRegistry.ContextOf(ANumber: Integer): TSpecialContext;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Special := ANumber;
end;

procedure TTestSpecialsRegistry.TestUnknownSpecialDoesNothing;
begin
  Assert.IsFalse(FRegistry.Execute(ContextOf(77)), 'a special that nobody registered gives false');
end;

procedure TTestSpecialsRegistry.TestRegisteredSpecialRunsAndGivesItsResult;
var
  LCalls: Integer;
begin
  LCalls := 0;
  FRegistry.Register(10,
    function(const AContext: TSpecialContext): Boolean
    begin
      Inc(LCalls);
      Result := True;
    end);
  FRegistry.Register(11,
    function(const AContext: TSpecialContext): Boolean
    begin
      Inc(LCalls);
      Result := False;
    end);
  Assert.IsTrue(FRegistry.Execute(ContextOf(10)));
  Assert.IsFalse(FRegistry.Execute(ContextOf(11)));
  Assert.AreEqual(2, LCalls);
end;

procedure TTestSpecialsRegistry.TestHandlerReceivesTheContext;
var
  LArgs: array[0..4] of Byte;
  LContext: TSpecialContext;
  LSeen: Integer;
  LLine: Integer;
begin
  LArgs[0] := 9;
  LContext := ContextOf(20);
  LContext.Args := @LArgs[0];
  LContext.Side := 1;
  LContext.Line := @LLine;
  LSeen := 0;
  FRegistry.Register(20,
    function(const AContext: TSpecialContext): Boolean
    begin
      LSeen := AContext.Args^ * 100 + AContext.Side * 10;
      if AContext.Line = @LLine then
        Inc(LSeen);
      Result := True;
    end);
  FRegistry.Execute(LContext);
  Assert.AreEqual(911, LSeen);
end;

procedure TTestSpecialsRegistry.TestOnlyTheRightHandlerRuns;
var
  LFirst: Boolean;
  LSecond: Boolean;
begin
  LFirst := False;
  LSecond := False;
  FRegistry.Register(1,
    function(const AContext: TSpecialContext): Boolean
    begin
      LFirst := True;
      Result := True;
    end);
  FRegistry.Register(2,
    function(const AContext: TSpecialContext): Boolean
    begin
      LSecond := True;
      Result := True;
    end);
  FRegistry.Execute(ContextOf(2));
  Assert.IsFalse(LFirst);
  Assert.IsTrue(LSecond);
end;

procedure TTestSpecialsRegistry.TestSameNumberTwiceIsAnError;
var
  LHandler: TSpecialHandler;
begin
  LHandler :=
    function(const AContext: TSpecialContext): Boolean
    begin
      Result := True;
    end;
  FRegistry.Register(5, LHandler);
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Register(5, LHandler);
    end, ESpecialRegistryException);
end;

procedure TTestSpecialsRegistry.TestHandlerThatIsNilIsAnError;
begin
  Assert.WillRaise(
    procedure
    begin
      FRegistry.Register(5, nil);
    end, ESpecialRegistryException);
end;

procedure TTestSpecialsRegistry.TestNumbersAreSorted;
var
  LHandler: TSpecialHandler;
  LNumbers: TArray<Integer>;
begin
  LHandler :=
    function(const AContext: TSpecialContext): Boolean
    begin
      Result := True;
    end;
  FRegistry.Register(30, LHandler);
  FRegistry.Register(2, LHandler);
  FRegistry.Register(140, LHandler);
  LNumbers := FRegistry.Numbers;
  Assert.AreEqual(3, Integer(Length(LNumbers)));
  Assert.AreEqual(2, LNumbers[0]);
  Assert.AreEqual(30, LNumbers[1]);
  Assert.AreEqual(140, LNumbers[2]);
end;

procedure TTestSpecialsRegistry.TestContains;
begin
  Assert.IsFalse(FRegistry.Contains(3));
  FRegistry.Register(3,
    function(const AContext: TSpecialContext): Boolean
    begin
      Result := True;
    end);
  Assert.IsTrue(FRegistry.Contains(3));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSpecialsRegistry);

end.
