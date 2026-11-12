{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the factory                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.Factory;

interface

uses
  System.IOUtils,
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Clock.Intf,
  DelphiDoom.Clock.ManualClock,
  DelphiDoom.Parity.Factory,
  DelphiDoom.Parity.FrameHashWriter,
  DelphiDoom.Parity.Intf,
  DelphiDoom.Parity.Types,
  DelphiDoom.Tests.Parity.Fakes;

type
  [TestFixture]
  [Category('parity')]
  TTestParityFactory = class(TObject)
  public
    [Test]
    procedure DovrebbeCreareUnLogSuFile;
    [Test]
    procedure DovrebbeCreareUnScrittoreDelloStatoChePubblicaLeRighe;
    [Test]
    procedure DovrebbeCreareUnScrittoreDeiFotogrammi;
    [Test]
    procedure DovrebbeCreareUnPilotaDalleOpzioni;
    [Test]
    procedure DovrebbeCreareUnOrologioInterruttore;
    [Test]
    procedure IRecordDelleOpzioniEDelPilotaDovrebberoPartireVuoti;
  end;

implementation

procedure TTestParityFactory.DovrebbeCreareUnLogSuFile;
var
  LFileName: string;
  LLog: IParityLog;
begin
  LFileName := TPath.Combine(TPath.GetTempPath, 'parity_factory_test.txt');
  LLog := TParityFactory.CreateFileLog(LFileName);
  LLog.WriteLine('x');
  LLog := nil;
  Assert.AreEqual(2, Integer(TFile.GetSize(LFileName)));
  TFile.Delete(LFileName);
end;

procedure TTestParityFactory.DovrebbeCreareUnScrittoreDelloStatoChePubblicaLeRighe;
var
  LLog: TFakeParityLog;
  LLogRef: IParityLog;
  LSink: IParityStateSink;
begin
  LLog := TFakeParityLog.Create;
  LLogRef := LLog;
  LSink := TParityFactory.CreateStateWriter(LLogRef, False, 0, 0);
  LSink.RegisterCategory('a', ['f']);
  LSink.BeginTic(3);
  LSink.EndTic;
  Assert.AreEqual(1, LLog.Lines.Count);
  Assert.IsTrue(LLog.Lines[0].StartsWith('T 3 '));
end;

procedure TTestParityFactory.DovrebbeCreareUnScrittoreDeiFotogrammi;
var
  LLog: TFakeParityLog;
  LLogRef: IParityLog;
  LWriter: TFrameHashWriter;
  LPixels: array[0..3] of Byte;
  LLayout: TParityFrameLayout;
begin
  LLog := TFakeParityLog.Create;
  LLogRef := LLog;
  LWriter := TParityFactory.CreateFrameWriter(LLogRef);
  try
    LLayout := Default(TParityFrameLayout);
    LLayout.Width := 2;
    LLayout.Height := 2;
    FillChar(LPixels, SizeOf(LPixels), 0);
    LWriter.WriteFrame(8, LLayout, @LPixels[0], 1, 0);
    Assert.AreEqual(1, LLog.Lines.Count);
    Assert.IsTrue(LLog.Lines[0].StartsWith('F 8 '));
  finally
    LWriter.Free;
  end;
end;

procedure TTestParityFactory.DovrebbeCreareUnPilotaDalleOpzioni;
var
  LOptions: TParityOptions;
  LPilot: IParityPilot;
begin
  LOptions := Default(TParityOptions);
  LOptions.AutoDemo := True;
  LOptions.AutoDemoSeed := 5;
  LOptions.AutoDemoTics := 10;
  LPilot := TParityFactory.CreatePilot(LOptions);
  Assert.IsFalse(LPilot.IsFinished(9));
  Assert.IsTrue(LPilot.IsFinished(10));
end;

procedure TTestParityFactory.DovrebbeCreareUnOrologioInterruttore;
var
  LSwitch: TFakeParitySwitch;
  LSwitchRef: IParitySwitch;
  LClock: IClock;
begin
  LSwitch := TFakeParitySwitch.Create;
  LSwitchRef := LSwitch;
  LClock := TParityFactory.CreateSwitchClock(TManualClock.Create, LSwitchRef, 35);
  LSwitch.Active := True;
  Assert.AreEqual(0, LClock.Steps(35));
end;

procedure TTestParityFactory.IRecordDelleOpzioniEDelPilotaDovrebberoPartireVuoti;
var
  LCommand: TParityPilotCommand;
  LView: TParityPilotView;
begin
  LCommand := Default(TParityPilotCommand);
  LView := Default(TParityPilotView);
  Assert.AreEqual(0, LCommand.Forward);
  Assert.IsFalse(LCommand.Fire);
  Assert.IsFalse(LView.Alive);
end;

end.
