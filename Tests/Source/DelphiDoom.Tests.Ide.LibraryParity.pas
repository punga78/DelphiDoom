{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - the library panels, old and new      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.LibraryParity;

interface

uses
  System.SysUtils,
  System.Classes,
  DUnitX.TestFramework,
  DelphiDoom.Ide.Intf,
  DelphiDoom.Tests.Ide.FakeGameLibrary;

type
  /// <summary>
  ///   The old panels (TFrame_Constants, ..., TFrame_Mobjinfo) were run on the real ddc_*.dll of
  ///   each game and their lists and trees were written to Tests\Data\Ide\Library\*.frames.golden.txt
  ///   (the count and a hash of the lines, the first line and the last). The catalogs of the library,
  ///   fed with the same lines (the other files of the folder), must give the same
  /// </summary>
  [TestFixture]
  [Category('ide')]
  TTestIdeLibraryParity = class(TObject)
  strict private
    FLibrary: TFakeIdeGameLibrary;
    FLibraryIntf: IIdeGameLibrary;
    procedure CheckGame(const AGame: string);
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerDoom;
    [Test]
    procedure DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerHeretic;
    [Test]
    procedure DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerHexen;
    [Test]
    procedure DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerStrife;
  end;

implementation

uses
  DelphiDoom.Tests.Ide.TestData,
  DelphiDoom.Tests.Ide.LibraryDump;

{ TTestIdeLibraryParity }

procedure TTestIdeLibraryParity.Setup;
begin
  FLibrary := TFakeIdeGameLibrary.Create;
  FLibraryIntf := FLibrary;
end;

procedure TTestIdeLibraryParity.TearDown;
begin
  FLibraryIntf := nil;
end;

procedure TTestIdeLibraryParity.CheckGame(const AGame: string);
var
  LDump: TStringList;
begin
  FLibrary.LoadGameFromFiles(AGame);
  LDump := TLibraryDump.Run(FLibraryIntf, AGame);
  try
    Assert.AreEqual('', TIdeTestData.Compare('Library\' + AGame + '.frames.golden.txt', LDump));
  finally
    LDump.Free;
  end;
end;

procedure TTestIdeLibraryParity.DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerDoom;
begin
  CheckGame('doom');
end;

procedure TTestIdeLibraryParity.DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerHeretic;
begin
  CheckGame('heretic');
end;

procedure TTestIdeLibraryParity.DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerHexen;
begin
  CheckGame('hexen');
end;

procedure TTestIdeLibraryParity.DovrebbeDareLeStesseListeEAlberiDeiPannelliVecchiPerStrife;
begin
  CheckGame('strife');
end;

end.
