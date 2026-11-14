unit DelphiDoom.Tests.Greed.ScriptMouse;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Input.Types, DelphiDoom.Input.Intf,
  DelphiDoom.Greed.Types, DelphiDoom.Greed.PlayerControl.Intf, DelphiDoom.Greed.CommandState,
  DelphiDoom.Greed.Mouse.Intf, DelphiDoom.Greed.Mouse, DelphiDoom.Greed.MouseControls,
  DelphiDoom.Greed.ScriptMouse, DelphiDoom.Greed.ScriptMouseLine, DelphiDoom.Greed.ApplicationScript,
  DelphiDoom.Greed.ScriptControls, DelphiDoom.Tests.Greed.GameFakes;

type
  [TestFixture]
  [Category('greed')]
  TTestGreedScriptMouse = class(TObject)
  strict private
    FDevice: TGreedScriptMouse;
    FDeviceIntf: IMouseDevice;
    FMouse: IGreedMouse;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeEssereUnaFinestraGrandeQuantoLoSchermoDeiMenu;
    [Test]
    procedure DovrebbeSommareGliSpostamentiFinoAllaLettura;
    [Test]
    procedure DovrebbeTenereIBottoniComeLiLasciaLoScript;
    [Test]
    procedure DovrebbeFareUnClicInQuattroLetture;
    [Test]
    procedure DovrebbeMettereInCodaIClic;
    [Test]
    procedure DovrebbeDareUnClicAlMouseDelGiocoNelPuntoChiesto;
    [Test]
    procedure DovrebbeButtareIClicAllaChiusura;
  end;

  [TestFixture]
  [Category('greed')]
  TTestGreedScriptMouseLine = class(TObject)
  strict private
    function Parse(const AText: string; out ALine: TGreedScriptMouseLine): Boolean;
  public
    [Test]
    procedure DovrebbeRiconoscereLeTreParole;
    [Test]
    procedure DovrebbeLeggereUnoSpostamento;
    [Test]
    procedure DovrebbeLeggereUnBottone;
    [Test]
    procedure DovrebbeLeggereUnClic;
    [Test]
    procedure DovrebbeRifiutareUnaRigaScrittaMale;
    [Test]
    procedure DovrebbeTrovareLeRigheDelMouseInUnoScript;
    [Test]
    procedure DovrebbeApplicareLaRigaAlMouse;
    [Test]
    procedure DovrebbeSollevareSenzaMouse;
  end;

  /// <summary>The lines of the mouse in the two scripts of keys (the one of the program and the one of -play)</summary>
  [TestFixture]
  [Category('greed')]
  TTestGreedScriptsWithMouse = class(TObject)
  strict private
    FLines: TStringList;
    FDevice: TGreedScriptMouse;
    FDeviceIntf: IMouseDevice;
    FScriptMouse: IGreedScriptMouse;
    FMouse: IGreedMouse;
    FInner: IGreedCommandSource;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure IlProgrammaDovrebbeMuovereIlMouseAlTicIndicato;
    [Test]
    procedure IlProgrammaDovrebbePremereUnBottoneDelMouse;
    [Test]
    procedure IlProgrammaDovrebbeFareUnClic;
    [Test]
    procedure IlProgrammaDovrebbeRifiutareUnaRigaDelMouseScrittaMale;
    [Test]
    procedure IlProgrammaDovrebbeRifiutareIlMouseSeNonNeHaUno;
    [Test]
    procedure IComandiDovrebberoMuovereIlMouseAlTicIndicato;
    [Test]
    procedure IComandiDovrebberoPremereUnBottoneDelMouse;
    [Test]
    procedure IComandiDovrebberoRifiutareUnaRigaDelMouseScrittaMale;
    [Test]
    procedure IComandiDovrebberoRifiutareIlMouseSeNonNeHannoUno;
  end;

implementation

{ TTestGreedScriptMouse }

procedure TTestGreedScriptMouse.Setup;
begin
  FDevice := TGreedScriptMouse.Create;
  FDeviceIntf := FDevice;
  FMouse := TGreedMouse.Create(FDeviceIntf, FDevice, nil);
end;

procedure TTestGreedScriptMouse.TearDown;
begin
  FMouse := nil;
  FDeviceIntf := nil;
end;

procedure TTestGreedScriptMouse.DovrebbeEssereUnaFinestraGrandeQuantoLoSchermoDeiMenu;
begin
  Assert.AreEqual(320, FDevice.GetWidth);
  Assert.AreEqual(200, FDevice.GetHeight);
  FDeviceIntf.Initialize;
  Assert.IsFalse(FDevice.IsButtonDown(TMouseButton.Left));
end;

procedure TTestGreedScriptMouse.DovrebbeSommareGliSpostamentiFinoAllaLettura;
var
  LX, LY: Integer;
begin
  FDevice.SetPosition(160, 100);
  FDevice.Move(5, -3);
  FDevice.Move(10, 1);
  FDevice.GetPosition(LX, LY);
  Assert.AreEqual(175, LX);
  Assert.AreEqual(98, LY);
  FDevice.SetPosition(160, 100);
  FDevice.GetPosition(LX, LY);
  Assert.AreEqual(160, LX, 'the game put the cursor back');
end;

procedure TTestGreedScriptMouse.DovrebbeTenereIBottoniComeLiLasciaLoScript;
begin
  FDevice.SetButton(gmbFire, True);
  FDevice.SetButton(gmbNorth, True);
  Assert.IsTrue(FDevice.IsButtonDown(TMouseButton.Left), 'fire is the left button');
  Assert.IsTrue(FDevice.IsButtonDown(TMouseButton.Middle), 'north is the middle button');
  Assert.IsFalse(FDevice.IsButtonDown(TMouseButton.Right));
  FDevice.SetButton(gmbUse, True);
  FDevice.SetButton(gmbFire, False);
  Assert.IsTrue(FDevice.IsButtonDown(TMouseButton.Right), 'use is the right button');
  Assert.IsFalse(FDevice.IsButtonDown(TMouseButton.Left));
end;

procedure TTestGreedScriptMouse.DovrebbeFareUnClicInQuattroLetture;
var
  LX, LY: Integer;
begin
  FDevice.SetPosition(160, 100);
  FDevice.Click(30, 40);
  Assert.AreEqual(4, FDevice.PendingSteps);
  FDevice.GetPosition(LX, LY);
  Assert.AreEqual(160 - 640, LX, 'first far beyond the corner');
  Assert.AreEqual(100 - 400, LY);
  FDevice.SetPosition(160, 100);
  FDevice.GetPosition(LX, LY);
  Assert.AreEqual(190, LX, 'then the distance of the pixel from the corner');
  Assert.AreEqual(140, LY);
  Assert.IsFalse(FDevice.IsButtonDown(TMouseButton.Left));
  FDevice.SetPosition(160, 100);
  FDevice.GetPosition(LX, LY);
  Assert.AreEqual(160, LX);
  Assert.IsTrue(FDevice.IsButtonDown(TMouseButton.Left), 'then the button down');
  FDevice.GetPosition(LX, LY);
  Assert.IsFalse(FDevice.IsButtonDown(TMouseButton.Left), 'then up');
  Assert.AreEqual(0, FDevice.PendingSteps);
end;

procedure TTestGreedScriptMouse.DovrebbeMettereInCodaIClic;
begin
  FDevice.Click(1, 2);
  FDevice.Click(3, 4);
  Assert.AreEqual(8, FDevice.PendingSteps);
end;

procedure TTestGreedScriptMouse.DovrebbeDareUnClicAlMouseDelGiocoNelPuntoChiesto;
var
  LX, LY, LReading: Integer;
  LClicked: Boolean;
begin
  FMouse.Show;
  FMouse.Read;
  FDevice.Click(190, 50);
  LClicked := False;
  for LReading := 1 to 6 do
  begin
    FMouse.Read;
    if FMouse.TakeClick(LX, LY) then
    begin
      Assert.IsFalse(LClicked, 'one click only');
      LClicked := True;
      Assert.AreEqual(190, LX);
      Assert.AreEqual(50, LY);
    end;
  end;
  Assert.IsTrue(LClicked);
  Assert.IsFalse(FMouse.IsDown(gmbFire), 'the button was released');
  // from wherever the pointer is: the second click does not depend on the first
  FDevice.Click(0, 199);
  for LReading := 1 to 4 do
    FMouse.Read;
  Assert.IsTrue(FMouse.TakeClick(LX, LY));
  Assert.AreEqual(0, LX);
  Assert.AreEqual(199, LY);
end;

procedure TTestGreedScriptMouse.DovrebbeButtareIClicAllaChiusura;
begin
  FDevice.Click(1, 2);
  FDeviceIntf.Shutdown;
  Assert.AreEqual(0, FDevice.PendingSteps);
end;

{ TTestGreedScriptMouseLine }

function TTestGreedScriptMouseLine.Parse(const AText: string; out ALine: TGreedScriptMouseLine): Boolean;
begin
  Result := TGreedScriptMouseLine.TryParse(AText.Split([' '], TStringSplitOptions.ExcludeEmpty), ALine);
end;

procedure TTestGreedScriptMouseLine.DovrebbeRiconoscereLeTreParole;
begin
  Assert.IsTrue(TGreedScriptMouseLine.IsMouseWord('mouse'));
  Assert.IsTrue(TGreedScriptMouseLine.IsMouseWord('MouseButton'));
  Assert.IsTrue(TGreedScriptMouseLine.IsMouseWord('CLICK'));
  Assert.IsFalse(TGreedScriptMouseLine.IsMouseWord('fire'));
  Assert.IsFalse(TGreedScriptMouseLine.IsMouseWord(''));
end;

procedure TTestGreedScriptMouseLine.DovrebbeLeggereUnoSpostamento;
var
  LLine: TGreedScriptMouseLine;
begin
  Assert.IsTrue(Parse('12 mouse -30 7', LLine));
  Assert.AreEqual(Ord(smkMove), Ord(LLine.Kind));
  Assert.AreEqual(-30, LLine.X);
  Assert.AreEqual(7, LLine.Y);
end;

procedure TTestGreedScriptMouseLine.DovrebbeLeggereUnBottone;
var
  LLine: TGreedScriptMouseLine;
begin
  Assert.IsTrue(Parse('5 mousebutton fire down', LLine));
  Assert.AreEqual(Ord(smkButton), Ord(LLine.Kind));
  Assert.AreEqual(Ord(gmbFire), Ord(LLine.Button));
  Assert.IsTrue(LLine.Down);
  Assert.IsTrue(Parse('5 MOUSEBUTTON Use UP', LLine));
  Assert.AreEqual(Ord(gmbUse), Ord(LLine.Button));
  Assert.IsFalse(LLine.Down);
  Assert.IsTrue(Parse('5 mousebutton north down', LLine));
  Assert.AreEqual(Ord(gmbNorth), Ord(LLine.Button));
end;

procedure TTestGreedScriptMouseLine.DovrebbeLeggereUnClic;
var
  LLine: TGreedScriptMouseLine;
begin
  Assert.IsTrue(Parse('40 click 190 50', LLine));
  Assert.AreEqual(Ord(smkClick), Ord(LLine.Kind));
  Assert.AreEqual(190, LLine.X);
  Assert.AreEqual(50, LLine.Y);
end;

procedure TTestGreedScriptMouseLine.DovrebbeRifiutareUnaRigaScrittaMale;
var
  LLine: TGreedScriptMouseLine;
begin
  Assert.IsFalse(Parse('1 mouse 3', LLine), 'a number is missing');
  Assert.IsFalse(Parse('1 mouse 3 4 5', LLine), 'a word too many');
  Assert.IsFalse(Parse('1 mouse x 4', LLine));
  Assert.IsFalse(Parse('1 click 3 y', LLine));
  Assert.IsFalse(Parse('1 mousebutton left down', LLine), 'the buttons have the names of what they do');
  Assert.IsFalse(Parse('1 mousebutton fire held', LLine));
  Assert.IsFalse(Parse('1 fire down now', LLine), 'not a line of the mouse');
end;

procedure TTestGreedScriptMouseLine.DovrebbeTrovareLeRigheDelMouseInUnoScript;
var
  LScript: TStringList;
begin
  Assert.IsFalse(TGreedScriptMouseLine.AnyIn(nil));
  LScript := TStringList.Create;
  try
    LScript.Add('# 3 mouse 1 1');
    LScript.Add('');
    LScript.Add('10 fire down');
    LScript.Add('12 type MOUSE');
    Assert.IsFalse(TGreedScriptMouseLine.AnyIn(LScript), 'keys, a comment and a text that says mouse');
    LScript.Add('  14   click 10');
    Assert.IsTrue(TGreedScriptMouseLine.AnyIn(LScript), 'a line of the mouse, even if it is not complete');
  finally
    LScript.Free;
  end;
end;

procedure TTestGreedScriptMouseLine.DovrebbeApplicareLaRigaAlMouse;
var
  LDevice: TGreedScriptMouse;
  LMouse: IGreedScriptMouse;
  LLine: TGreedScriptMouseLine;
  LX, LY: Integer;
begin
  LDevice := TGreedScriptMouse.Create;
  LMouse := LDevice;
  Assert.IsTrue(Parse('1 mouse 4 -9', LLine));
  LLine.ApplyTo(LMouse);
  LDevice.GetPosition(LX, LY);
  Assert.AreEqual(4, LX);
  Assert.AreEqual(-9, LY);
  Assert.IsTrue(Parse('1 mousebutton use down', LLine));
  LLine.ApplyTo(LMouse);
  Assert.IsTrue(LDevice.IsButtonDown(TMouseButton.Right));
  Assert.IsTrue(Parse('1 click 7 8', LLine));
  LLine.ApplyTo(LMouse);
  Assert.AreEqual(4, LDevice.PendingSteps);
end;

procedure TTestGreedScriptMouseLine.DovrebbeSollevareSenzaMouse;
var
  LLine: TGreedScriptMouseLine;
begin
  Assert.IsTrue(Parse('1 mouse 4 -9', LLine));
  Assert.WillRaise(
    procedure
    begin
      LLine.ApplyTo(nil);
    end, EArgumentNilException);
end;

{ TTestGreedScriptsWithMouse }

procedure TTestGreedScriptsWithMouse.Setup;
begin
  FLines := TStringList.Create;
  FDevice := TGreedScriptMouse.Create;
  FDeviceIntf := FDevice;
  FScriptMouse := FDevice;
  FMouse := TGreedMouse.Create(FDeviceIntf, FDevice, nil);
  FInner := TGreedMouseControls.Create(TFakeCommandSource.Create, FMouse);
end;

procedure TTestGreedScriptsWithMouse.TearDown;
begin
  FInner := nil;
  FMouse := nil;
  FScriptMouse := nil;
  FDeviceIntf := nil;
  FLines.Free;
end;

procedure TTestGreedScriptsWithMouse.IlProgrammaDovrebbeMuovereIlMouseAlTicIndicato;
var
  LScript: TGreedApplicationScript;
  LSource: IGreedCommandSource;
  LDeltaX, LDeltaY: Integer;
begin
  FLines.Text := '3 mouse 20 -4';
  LScript := TGreedApplicationScript.Create(FLines, FInner, FScriptMouse);
  LSource := LScript;
  LScript.TicStarting(1);
  LSource.BeginReading;
  LSource.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX, 'not yet');
  LScript.TicStarting(3);
  LSource.BeginReading;
  LSource.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(-20, LDeltaX, 'to the right is negative for the game');
  Assert.AreEqual(4, LDeltaY);
  LScript.TicStarting(5);
  LSource.BeginReading;
  LSource.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX, 'a movement is read once');
end;

procedure TTestGreedScriptsWithMouse.IlProgrammaDovrebbePremereUnBottoneDelMouse;
var
  LScript: TGreedApplicationScript;
  LSource: IGreedCommandSource;
begin
  FLines.Text := '1 mousebutton fire down'#13#10'5 mousebutton fire up'#13#10'3 mousebutton north down';
  LScript := TGreedApplicationScript.Create(FLines, FInner, FScriptMouse);
  LSource := LScript;
  LScript.TicStarting(1);
  LSource.BeginReading;
  Assert.IsTrue(LSource.IsMousePressed(gmbFire));
  Assert.IsFalse(LSource.IsMousePressed(gmbNorth));
  LScript.TicStarting(3);
  LSource.BeginReading;
  Assert.IsTrue(LSource.IsMousePressed(gmbNorth));
  LScript.TicStarting(5);
  LSource.BeginReading;
  Assert.IsFalse(LSource.IsMousePressed(gmbFire));
  Assert.IsTrue(LSource.IsMousePressed(gmbNorth));
end;

procedure TTestGreedScriptsWithMouse.IlProgrammaDovrebbeFareUnClic;
var
  LScript: TGreedApplicationScript;
  LKeep: IInterface;
  LX, LY, LTic: Integer;
  LClicked: Boolean;
begin
  FLines.Text := '2 click 60 124';
  LScript := TGreedApplicationScript.Create(FLines, nil, FScriptMouse);
  LKeep := LScript;
  FMouse.Show;
  LClicked := False;
  for LTic := 1 to 12 do
  begin
    LScript.TicStarting(LTic);
    // a menu reads the mouse on the odd tics
    if Odd(LTic) then
    begin
      FMouse.Read;
      if FMouse.TakeClick(LX, LY) then
      begin
        LClicked := True;
        Assert.AreEqual(60, LX);
        Assert.AreEqual(124, LY);
      end;
    end;
  end;
  Assert.IsTrue(LClicked);
end;

procedure TTestGreedScriptsWithMouse.IlProgrammaDovrebbeRifiutareUnaRigaDelMouseScrittaMale;
begin
  FLines.Text := '1 fire down'#13#10'2 mouse 3';
  Assert.WillRaise(
    procedure
    begin
      TGreedApplicationScript.Create(FLines, nil, FScriptMouse);
    end, EGreedException);
end;

procedure TTestGreedScriptsWithMouse.IlProgrammaDovrebbeRifiutareIlMouseSeNonNeHaUno;
begin
  FLines.Text := '2 mouse 3 4';
  Assert.WillRaise(
    procedure
    begin
      TGreedApplicationScript.Create(FLines, nil);
    end, EGreedException);
end;

procedure TTestGreedScriptsWithMouse.IComandiDovrebberoMuovereIlMouseAlTicIndicato;
var
  LSource: IGreedCommandSource;
  LDeltaX, LDeltaY: Integer;
begin
  // the tic of a reading: 1, 3, 5 ...
  FLines.Text := '3 mouse -7 9'#13#10'3 mouse -1 1';
  LSource := TGreedScriptControls.Create(FLines, FInner, FScriptMouse);
  LSource.BeginReading;
  LSource.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(0, LDeltaX);
  LSource.BeginReading;
  LSource.TakeMouseMove(LDeltaX, LDeltaY);
  Assert.AreEqual(8, LDeltaX, 'the two movements of the tic together');
  Assert.AreEqual(-10, LDeltaY);
end;

procedure TTestGreedScriptsWithMouse.IComandiDovrebberoPremereUnBottoneDelMouse;
var
  LSource: IGreedCommandSource;
begin
  FLines.Text := '1 mousebutton use down'#13#10'3 mousebutton use up'#13#10'1 fire down';
  LSource := TGreedScriptControls.Create(FLines, FInner, FScriptMouse);
  LSource.BeginReading;
  Assert.IsTrue(LSource.IsMousePressed(gmbUse));
  Assert.IsTrue(LSource.IsPressed(gcFire), 'the keys of the script as before');
  LSource.BeginReading;
  Assert.IsFalse(LSource.IsMousePressed(gmbUse));
end;

procedure TTestGreedScriptsWithMouse.IComandiDovrebberoRifiutareUnaRigaDelMouseScrittaMale;
begin
  FLines.Text := '2 mousebutton fire';
  Assert.WillRaise(
    procedure
    begin
      TGreedScriptControls.Create(FLines, nil, FScriptMouse);
    end, EGreedException);
  FLines.Text := '2 mousebutton left down';
  Assert.WillRaise(
    procedure
    begin
      TGreedScriptControls.Create(FLines, nil, FScriptMouse);
    end, EGreedException);
end;

procedure TTestGreedScriptsWithMouse.IComandiDovrebberoRifiutareIlMouseSeNonNeHannoUno;
begin
  FLines.Text := '2 mouse 3 4';
  Assert.WillRaise(
    procedure
    begin
      TGreedScriptControls.Create(FLines, nil);
    end, EGreedException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGreedScriptMouse);
  TDUnitX.RegisterTestFixture(TTestGreedScriptMouseLine);
  TDUnitX.RegisterTestFixture(TTestGreedScriptsWithMouse);

end.
