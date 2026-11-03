{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of TGlbspProvider                                         }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Glbsp.Provider;

interface

uses
  System.SysUtils, DUnitX.TestFramework;

type
  [TestFixture]
  [Category('glbsp')]
  TTestGlbspProvider = class(TObject)
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestClientWorksWithoutTheDll;
    [Test]
    procedure TestClientIsShared;
    [Test]
    procedure TestUseReplacesTheImplementation;
    [Test]
    procedure TestReleaseThenClientCreatesANewOne;
    [Test]
    procedure TestMissingWadRaises;
  end;

implementation

uses
  DelphiDoom.Glbsp.Intf, DelphiDoom.Glbsp.Engine, DelphiDoom.Glbsp.Provider;

{ TTestGlbspProvider }

procedure TTestGlbspProvider.Setup;
begin
  TGlbspProvider.Release;
end;

procedure TTestGlbspProvider.TearDown;
begin
  TGlbspProvider.Release;
end;

procedure TTestGlbspProvider.TestClientWorksWithoutTheDll;
begin
  // The program of glbsp is embedded: its size is the one of the executable
  Assert.AreEqual(Cardinal(57404), TGlbspProvider.Client.ExecutableSize);
end;

procedure TTestGlbspProvider.TestClientIsShared;
begin
  Assert.AreSame(TObject(TGlbspProvider.Client), TObject(TGlbspProvider.Client));
end;

procedure TTestGlbspProvider.TestUseReplacesTheImplementation;
begin
  TGlbspProvider.Client;
  // The old client is freed by Use: a new one works on the engine passed in
  TGlbspProvider.Use(TGlbspEngine.Create);
  Assert.AreEqual(Cardinal(57404), TGlbspProvider.Client.ExecutableSize);
end;

procedure TTestGlbspProvider.TestReleaseThenClientCreatesANewOne;
begin
  TGlbspProvider.Client;
  TGlbspProvider.Release;
  Assert.AreEqual(Cardinal(57404), TGlbspProvider.Client.ExecutableSize);
end;

procedure TTestGlbspProvider.TestMissingWadRaises;
begin
  Assert.WillRaise(
    procedure
    begin
      TGlbspProvider.Client.BuildNodes('no_such_dir_ddglbsp\missing.wad',
        'no_such_dir_ddglbsp\missing.gwa');
    end, EGlbspException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGlbspProvider);

end.
