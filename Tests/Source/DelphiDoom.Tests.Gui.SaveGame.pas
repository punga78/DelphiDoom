{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Gui library - the save game of the guis            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Gui.SaveGame;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  [Category('GuiSave')]
  TTestGuiSaveGame = class
  public
    [Test]
    procedure IlRipristinoRidaLoStatoDelleFinestre;
    [Test]
    procedure UnaTransizioneRipristinataContinuaIdenticaAdUnaNonSalvata;
    [Test]
    procedure IlFocusLaCatturaEIlComandoSiRipristinano;
    [Test]
    procedure UnoStreamTroncatoDaUnErroreDedicato;
    [Test]
    procedure UnaLunghezzaNegativaODiTroppoDaUnErrore;
    [Test]
    procedure UnaTransizioneDiUnaFinestraCheNonCe;
    [Test]
    procedure IlFuzzingDelloStreamNonDaAccessViolation;
    [Test]
    procedure ISeiTipiDiDatiTraStringheENumeriSiLeggonoCosiComeSiScrivono;
    [Test]
    procedure IlNomeDeiTastiDelBindVieneDalleAssociazioni;
  end;

implementation

uses
  System.SysUtils, System.Classes, DelphiDoom.IdLib.Math.Vec4, DelphiDoom.Gui.SaveStream, DelphiDoom.Gui.Window,
  DelphiDoom.Gui.Window.Keys, DelphiDoom.Gui.UserInterface, DelphiDoom.Gui.Window.Types,
  DelphiDoom.Tests.Gui.WindowFakes, DelphiDoom.Tests.Gui.WindowDump;

const
  SAVE_GUI = 'windowDef Desktop { rect 0, 0, 640, 480 definefloat counter 5 definevec4 tint 1, 0, 0, 1 ' +
    'onActivate { transition "rect" "0 0 10 10" "100 100 10 10" "1000" } ' +
    'windowDef box { rect 10, 10, 50, 50 backcolor 0.5, 0.5, 0.5, 1 text "gui::label" onAction { set "cmd" "go" } ' +
    'onTime 100 { set "backcolor" "0 1 0 1" } } ' +
    'windowDef plain { rect 100, 100, 20, 20 backcolor 1, 1, 0, 1 } }';

function Dump(const AGui: TGuiUserInterface): string;
var
  LLines: TStringList;
begin
  LLines := TStringList.Create;
  try
    DumpWindow(AGui.Desktop, LLines);
    Result := LLines.Text;
  finally
    LLines.Free;
  end;
end;

procedure SaveTo(const AGui: TGuiUserInterface; const AStream: TMemoryStream);
var
  LWriter: TGuiSaveWriter;
begin
  LWriter := TGuiSaveWriter.Create(AStream);
  try
    AGui.WriteToSaveGame(LWriter);
  finally
    LWriter.Free;
  end;
  AStream.Position := 0;
end;

procedure LoadFrom(const AGui: TGuiUserInterface; const AStream: TStream);
var
  LReader: TGuiSaveReader;
begin
  LReader := TGuiSaveReader.Create(AStream);
  try
    AGui.ReadFromSaveGame(LReader);
  finally
    LReader.Free;
  end;
end;

procedure TTestGuiSaveGame.IlRipristinoRidaLoStatoDelleFinestre;
var
  LFirst, LSecond: TGuiWindowWorld;
  LStream: TMemoryStream;
begin
  LFirst := TGuiWindowWorld.Create;
  LSecond := TGuiWindowWorld.Create;
  LStream := TMemoryStream.Create;
  try
    LFirst.Load(SAVE_GUI);
    LFirst.UserInterface.SetStateString('label', 'saved');
    LFirst.UserInterface.Activate(True, 10);
    LFirst.UserInterface.RunFrame(150);
    LFirst.UserInterface.RunFrame(400);
    SaveTo(LFirst.UserInterface, LStream);
    LSecond.Load(SAVE_GUI);
    LoadFrom(LSecond.UserInterface, LStream);
    Assert.AreEqual(Dump(LFirst.UserInterface), Dump(LSecond.UserInterface));
    Assert.AreEqual('saved', string(LSecond.UserInterface.GetStateString('label')));
    Assert.AreEqual(LFirst.UserInterface.Time, LSecond.UserInterface.Time);
    Assert.AreEqual(LFirst.UserInterface.Active, LSecond.UserInterface.Active);
    Assert.AreEqual(LFirst.UserInterface.Desktop.TransitionCount, LSecond.UserInterface.Desktop.TransitionCount);
  finally
    LStream.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGuiSaveGame.UnaTransizioneRipristinataContinuaIdenticaAdUnaNonSalvata;
var
  LFirst, LSecond: TGuiWindowWorld;
  LStream: TMemoryStream;
begin
  LFirst := TGuiWindowWorld.Create;
  LSecond := TGuiWindowWorld.Create;
  LStream := TMemoryStream.Create;
  try
    LFirst.Load(SAVE_GUI);
    LFirst.UserInterface.Activate(True, 10);
    LFirst.UserInterface.RunFrame(300);
    Assert.AreEqual(1, LFirst.UserInterface.Desktop.TransitionCount);
    SaveTo(LFirst.UserInterface, LStream);
    LSecond.Load(SAVE_GUI);
    LoadFrom(LSecond.UserInterface, LStream);
    Assert.AreEqual(1, LSecond.UserInterface.Desktop.TransitionCount, 'FixupTransitions found the variable again');
    LFirst.UserInterface.RunFrame(600);
    LSecond.UserInterface.RunFrame(600);
    Assert.AreEqual(Dump(LFirst.UserInterface), Dump(LSecond.UserInterface));
    LFirst.UserInterface.RunFrame(1200);
    LSecond.UserInterface.RunFrame(1200);
    Assert.AreEqual(Dump(LFirst.UserInterface), Dump(LSecond.UserInterface));
  finally
    LStream.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGuiSaveGame.IlFocusLaCatturaEIlComandoSiRipristinano;
var
  LFirst, LSecond: TGuiWindowWorld;
  LStream: TMemoryStream;
  LUpdate: Boolean;
begin
  LFirst := TGuiWindowWorld.Create;
  LSecond := TGuiWindowWorld.Create;
  LStream := TMemoryStream.Create;
  try
    LFirst.Load(SAVE_GUI);
    LFirst.UserInterface.RunFrame(20);
    LUpdate := False;
    LFirst.UserInterface.HandleEvent(TGuiSysEvent.Make(GUI_SE_MOUSE, 20, 20), 30, LUpdate);
    LFirst.UserInterface.HandleEvent(TGuiSysEvent.Make(GUI_SE_KEY, GUI_K_MOUSE1, 1), 40, LUpdate);
    Assert.IsNotNull(LFirst.UserInterface.Desktop.FocusedChild);
    SaveTo(LFirst.UserInterface, LStream);
    LSecond.Load(SAVE_GUI);
    LoadFrom(LSecond.UserInterface, LStream);
    Assert.IsNotNull(LSecond.UserInterface.Desktop.FocusedChild);
    Assert.AreEqual(string(LFirst.UserInterface.Desktop.FocusedChild.Name),
      string(LSecond.UserInterface.Desktop.FocusedChild.Name));
    Assert.AreEqual(LFirst.UserInterface.Context.CursorX, LSecond.UserInterface.Context.CursorX);
  finally
    LStream.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGuiSaveGame.UnoStreamTroncatoDaUnErroreDedicato;
var
  LWorld: TGuiWindowWorld;
  LStream, LCut: TMemoryStream;
  LCount: Integer;
  LRaised: Boolean;
begin
  LWorld := TGuiWindowWorld.Create;
  LStream := TMemoryStream.Create;
  LCut := TMemoryStream.Create;
  try
    LWorld.Load(SAVE_GUI);
    SaveTo(LWorld.UserInterface, LStream);
    for LCount in [0, 3, 40, Integer(LStream.Size div 2), Integer(LStream.Size - 1)] do
    begin
      LCut.Clear;
      LCut.WriteBuffer(LStream.Memory^, LCount);
      LCut.Position := 0;
      LRaised := False;
      try
        LoadFrom(LWorld.UserInterface, LCut);
      except
        on E: EGuiSaveException do
          LRaised := True;
      end;
      Assert.IsTrue(LRaised, 'a stream of ' + IntToStr(LCount) + ' bytes');
    end;
  finally
    LCut.Free;
    LStream.Free;
    LWorld.Free;
  end;
end;

procedure TTestGuiSaveGame.UnaLunghezzaNegativaODiTroppoDaUnErrore;
var
  LStream: TMemoryStream;
  LWriter: TGuiSaveWriter;
  LReader: TGuiSaveReader;
  LRaised: Boolean;
begin
  LStream := TMemoryStream.Create;
  try
    LWriter := TGuiSaveWriter.Create(LStream);
    try
      LWriter.WriteInt(-5);
      LWriter.WriteInt(1000);
    finally
      LWriter.Free;
    end;
    LStream.Position := 0;
    LReader := TGuiSaveReader.Create(LStream);
    try
      LRaised := False;
      try
        LReader.ReadString;
      except
        on E: EGuiSaveException do
          LRaised := True;
      end;
      Assert.IsTrue(LRaised, 'negative length');
      LRaised := False;
      try
        LReader.ReadString;
      except
        on E: EGuiSaveException do
          LRaised := True;
      end;
      Assert.IsTrue(LRaised, 'a length that goes past the end');
    finally
      LReader.Free;
    end;
  finally
    LStream.Free;
  end;
end;

procedure TTestGuiSaveGame.UnaTransizioneDiUnaFinestraCheNonCe;
var
  LFirst, LSecond: TGuiWindowWorld;
  LStream: TMemoryStream;
begin
  LFirst := TGuiWindowWorld.Create;
  LSecond := TGuiWindowWorld.Create;
  LStream := TMemoryStream.Create;
  try
    LFirst.Load(SAVE_GUI);
    LFirst.UserInterface.Activate(True, 10);
    LFirst.UserInterface.RunFrame(300);
    SaveTo(LFirst.UserInterface, LStream);
    // the second gui is another one without a transition to move: the registers do not match
    LSecond.Load('windowDef Desktop { rect 0, 0, 640, 480 }');
    try
      LoadFrom(LSecond.UserInterface, LStream);
      Assert.Pass('read without an error');
    except
      on E: EGuiSaveException do
        Assert.Pass('the registers of another gui are an error');
    end;
  finally
    LStream.Free;
    LSecond.Free;
    LFirst.Free;
  end;
end;

procedure TTestGuiSaveGame.IlFuzzingDelloStreamNonDaAccessViolation;
var
  LWorld, LTarget: TGuiWindowWorld;
  LStream, LBad: TMemoryStream;
  LSeed, LIndex: Integer;
  LRandom: Cardinal;
  LBytes: PByte;

  function Next(const ARange: Integer): Integer;
  begin
    LRandom := LRandom * 1664525 + 1013904223;
    Result := Integer((LRandom shr 8) mod Cardinal(ARange));
  end;

begin
  LWorld := TGuiWindowWorld.Create;
  LStream := TMemoryStream.Create;
  LBad := TMemoryStream.Create;
  try
    LWorld.Load(SAVE_GUI);
    LWorld.UserInterface.Activate(True, 10);
    LWorld.UserInterface.RunFrame(300);
    SaveTo(LWorld.UserInterface, LStream);
    for LSeed := 1 to 200 do
    begin
      LRandom := Cardinal(LSeed) * 2654435761;
      LBad.Clear;
      LBad.WriteBuffer(LStream.Memory^, LStream.Size);
      LBytes := LBad.Memory;
      for LIndex := 0 to Next(6) do
        LBytes[Next(Integer(LBad.Size))] := Byte(Next(256));
      LBad.Position := 0;
      LTarget := TGuiWindowWorld.Create;
      try
        LTarget.Load(SAVE_GUI);
        try
          LoadFrom(LTarget.UserInterface, LBad);
          LTarget.UserInterface.RunFrame(500);
          LTarget.UserInterface.Redraw(500);
        except
          on E: EAccessViolation do
            Assert.Fail(Format('seed %d: access violation', [LSeed]));
          on E: ERangeError do
            Assert.Fail(Format('seed %d: range error', [LSeed]));
          on E: EInvalidPointer do
            Assert.Fail(Format('seed %d: invalid pointer', [LSeed]));
          on E: EOutOfMemory do
            Assert.Fail(Format('seed %d: out of memory', [LSeed]));
          on E: EListError do
            Assert.Fail(Format('seed %d: list error', [LSeed]));
          on E: Exception do
            ;
        end;
      finally
        LTarget.Free;
      end;
    end;
  finally
    LBad.Free;
    LStream.Free;
    LWorld.Free;
  end;
end;

procedure TTestGuiSaveGame.ISeiTipiDiDatiTraStringheENumeriSiLeggonoCosiComeSiScrivono;
var
  LStream: TMemoryStream;
  LWriter: TGuiSaveWriter;
  LReader: TGuiSaveReader;
begin
  LStream := TMemoryStream.Create;
  try
    LWriter := TGuiSaveWriter.Create(LStream);
    try
      LWriter.WriteInt(-123456);
      LWriter.WriteFloat(1.5);
      LWriter.WriteBool(True);
      LWriter.WriteString('abc');
      LWriter.WriteString('');
    finally
      LWriter.Free;
    end;
    LStream.Position := 0;
    LReader := TGuiSaveReader.Create(LStream);
    try
      Assert.AreEqual(-123456, LReader.ReadInt);
      Assert.AreEqual(Single(1.5), LReader.ReadFloat);
      Assert.IsTrue(LReader.ReadBool);
      Assert.AreEqual('abc', string(LReader.ReadString));
      Assert.AreEqual('', string(LReader.ReadString));
    finally
      LReader.Free;
    end;
  finally
    LStream.Free;
  end;
end;

type
  TFakeBindings = class(TInterfacedObject, IGuiKeyBindings)
    function KeysFromBinding(const ABinding: AnsiString): AnsiString;
  end;

function TFakeBindings.KeysFromBinding(const ABinding: AnsiString): AnsiString;
begin
  Result := 'KEY ' + UpperCase(ABinding);
end;

procedure TTestGuiSaveGame.IlNomeDeiTastiDelBindVieneDalleAssociazioni;
var
  LWorld: TGuiWindowWorld;
begin
  LWorld := TGuiWindowWorld.Create;
  try
    LWorld.Load('windowDef Desktop { bindDef b { rect 1,1,1,1 bind "_attack" } }');
    LWorld.UserInterface.SetKeyBindingNames;
    Assert.AreEqual('', string(LWorld.UserInterface.GetStateString('_attack')), 'no bindings given: nothing is set');
    LWorld.UserInterface.Context.KeyBindings := TFakeBindings.Create;
    LWorld.UserInterface.SetKeyBindingNames;
    Assert.AreEqual('KEY _ATTACK', string(LWorld.UserInterface.GetStateString('_attack')));
  finally
    LWorld.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGuiSaveGame);

end.
