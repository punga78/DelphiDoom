{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the war library - where DATA.WAR and the fonts are     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.War.AppDataLocator;

interface

uses
  System.SysUtils, System.Generics.Collections, DUnitX.TestFramework, DelphiDoom.War.App.DataLocator;

type
  /// <summary>The search of the data of the game, on a disk that the test makes up</summary>
  [TestFixture]
  [Category('war')]
  TTestWarAppDataLocator = class(TObject)
  strict private
    FFiles: TList<string>;
    function Exists: TWarFileExists;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeTrovareDataWarNellaCartella;
    [Test]
    procedure DovrebbeTrovareDataWarNellaCartellaData;
    [Test]
    procedure DovrebbePreferireLaPrimaCartellaCheLoHa;
    [Test]
    procedure DovrebbeDareVuotoSeDataWarNonCe;
    [Test]
    procedure DovrebbeElencareOgniPercorsoCercato;
    [Test]
    procedure DovrebbeTrovareIFontNellaCartellaONelleSottocartelle;
    [Test]
    procedure DovrebbeTrovareIFontInReferenceDiUnaCartellaSopra;
    [Test]
    procedure DovrebbeDistinguereIDueFont;
    [Test]
    procedure DovrebbeDareVuotoSeIFontNonCe;
  end;

implementation

{ TTestWarAppDataLocator }

procedure TTestWarAppDataLocator.Setup;
begin
  FFiles := TList<string>.Create;
end;

procedure TTestWarAppDataLocator.TearDown;
begin
  FFiles.Free;
end;

function TTestWarAppDataLocator.Exists: TWarFileExists;
var
  LFiles: TList<string>;
begin
  LFiles := FFiles;
  Result := function(const APath: string): Boolean
    begin
      Result := LFiles.Contains(APath);
    end;
end;

procedure TTestWarAppDataLocator.DovrebbeTrovareDataWarNellaCartella;
begin
  FFiles.Add('C:\Giochi\War\DATA.WAR');
  Assert.AreEqual('C:\Giochi\War\DATA.WAR', TWarDataLocator.FindDataWar(['C:\Giochi\War'], Exists()));
  Assert.AreEqual('C:\Giochi\War\DATA.WAR', TWarDataLocator.FindDataWar(['C:\Giochi\War\'], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbeTrovareDataWarNellaCartellaData;
begin
  FFiles.Add('C:\Giochi\War\DATA\DATA.WAR');
  Assert.AreEqual('C:\Giochi\War\DATA\DATA.WAR', TWarDataLocator.FindDataWar(['C:\Giochi\War'], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbePreferireLaPrimaCartellaCheLoHa;
begin
  FFiles.Add('D:\Due\DATA.WAR');
  FFiles.Add('C:\Uno\DATA\DATA.WAR');
  Assert.AreEqual('C:\Uno\DATA\DATA.WAR', TWarDataLocator.FindDataWar(['C:\Uno', 'D:\Due'], Exists()));
  Assert.AreEqual('D:\Due\DATA.WAR', TWarDataLocator.FindDataWar(['C:\Niente', 'D:\Due'], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbeDareVuotoSeDataWarNonCe;
begin
  Assert.AreEqual('', TWarDataLocator.FindDataWar(['C:\Niente'], Exists()));
  Assert.AreEqual('', TWarDataLocator.FindDataWar([], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbeElencareOgniPercorsoCercato;
var
  LPaths: TArray<string>;
begin
  LPaths := TWarDataLocator.DataWarCandidates(['A', 'B\']);
  Assert.AreEqual<Integer>(4, Length(LPaths));
  Assert.AreEqual('A\DATA.WAR', LPaths[0]);
  Assert.AreEqual('A\DATA\DATA.WAR', LPaths[1]);
  Assert.AreEqual('B\DATA.WAR', LPaths[2]);
  Assert.AreEqual('B\DATA\DATA.WAR', LPaths[3]);
end;

procedure TTestWarAppDataLocator.DovrebbeTrovareIFontNellaCartellaONelleSottocartelle;
begin
  FFiles.Add('C:\Dati\war1_font_1.png');
  FFiles.Add('C:\Dati\FONTS\war1_font_2.png');
  Assert.AreEqual('C:\Dati\war1_font_1.png', TWarDataLocator.FindFont(0, ['C:\Dati'], Exists()));
  Assert.AreEqual('C:\Dati\FONTS\war1_font_2.png', TWarDataLocator.FindFont(1, ['C:\Dati'], Exists()));
  FFiles.Add('C:\Altri\assets\war1_font_1.png');
  Assert.AreEqual('C:\Altri\assets\war1_font_1.png', TWarDataLocator.FindFont(0, ['C:\Altri'], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbeTrovareIFontInReferenceDiUnaCartellaSopra;
begin
  FFiles.Add('C:\Repo\Reference\war1\assets\war1_font_1.png');
  Assert.AreEqual('C:\Repo\Reference\war1\assets\war1_font_1.png',
    TWarDataLocator.FindFont(0, ['C:\Repo\Reference\_dati\warcraft'], Exists()));
  Assert.AreEqual('C:\Repo\Reference\war1\assets\war1_font_1.png',
    TWarDataLocator.FindFont(0, ['C:\Repo\bin\Win32\Release\War'], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbeDistinguereIDueFont;
begin
  FFiles.Add('C:\Dati\war1_font_2.png');
  Assert.AreEqual('', TWarDataLocator.FindFont(0, ['C:\Dati'], Exists()));
  Assert.AreEqual('C:\Dati\war1_font_2.png', TWarDataLocator.FindFont(1, ['C:\Dati'], Exists()));
end;

procedure TTestWarAppDataLocator.DovrebbeDareVuotoSeIFontNonCe;
begin
  Assert.AreEqual('', TWarDataLocator.FindFont(0, ['C:\Dati'], Exists()));
  Assert.AreEqual('', TWarDataLocator.FindFont(1, [], Exists()));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWarAppDataLocator);

end.
