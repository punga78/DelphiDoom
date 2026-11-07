{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the video library - the screen modes of Windows         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Video.WindowsDisplayModeSource;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Video.Types, DelphiDoom.Video.Intf;

type
  /// <summary>
  ///   EnumDisplaySettings only reads: the modes depend on the machine, so the tests look at
  ///   what is always true of them
  /// </summary>
  [TestFixture]
  [Category('video')]
  TTestVideoWindowsDisplayModeSource = class(TObject)
  public
    [Test]
    procedure DovrebbeElencareModiConMisurePositive;
    [Test]
    procedure DovrebbeDareGliStessiModiDueVolte;
    [Test]
    procedure DovrebbeTenereINumeriDelleModalitaSchermoIntero;
  end;

implementation

uses
  DelphiDoom.Video.Factory;

{ TTestVideoWindowsDisplayModeSource }

procedure TTestVideoWindowsDisplayModeSource.DovrebbeElencareModiConMisurePositive;
var
  LModes: TArray<TDisplayMode>;
  LMode: TDisplayMode;
begin
  LModes := TVideoFactory.CreateWindowsDisplayModeSource.ListModes;
  for LMode in LModes do
  begin
    Assert.IsTrue(LMode.Width > 0);
    Assert.IsTrue(LMode.Height > 0);
    Assert.IsTrue(LMode.BitsPerPixel > 0);
  end;
end;

procedure TTestVideoWindowsDisplayModeSource.DovrebbeDareGliStessiModiDueVolte;
var
  LSource: IDisplayModeSource;
  LFirst: TArray<TDisplayMode>;
  LSecond: TArray<TDisplayMode>;
  LIndex: Integer;
begin
  LSource := TVideoFactory.CreateWindowsDisplayModeSource;
  LFirst := LSource.ListModes;
  LSecond := LSource.ListModes;
  Assert.AreEqual(Length(LFirst), Length(LSecond));
  for LIndex := 0 to High(LFirst) do
  begin
    Assert.AreEqual(LFirst[LIndex].Width, LSecond[LIndex].Width);
    Assert.AreEqual(LFirst[LIndex].Height, LSecond[LIndex].Height);
    Assert.AreEqual(LFirst[LIndex].BitsPerPixel, LSecond[LIndex].BitsPerPixel);
  end;
end;

procedure TTestVideoWindowsDisplayModeSource.DovrebbeTenereINumeriDelleModalitaSchermoIntero;
begin
  // the numbers are written in the configuration files: they must not change
  Assert.AreEqual(0, FULLSCREEN_SHARED);
  Assert.AreEqual(1, FULLSCREEN_EXCLUSIVE);
  Assert.AreEqual(2, FULLSCREEN_OFF);
  Assert.AreEqual(3, NUMFULLSCREEN_MODES);
end;

end.
