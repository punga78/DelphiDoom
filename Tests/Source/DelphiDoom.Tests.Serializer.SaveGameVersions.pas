{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the versions of the saved games                        }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.SaveGameVersions;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Serializer.SaveGameVersions;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerSaveGameVersions = class
  strict private
    FVersions: TSaveGameVersions;
    FField: array[0..15] of Byte;
    procedure SetField(const AText: AnsiString);
    function Resolve(const ALength: Integer; out AVersion, AHack: Integer;
      out ASaved: string): TSaveGameVersionStatus;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeRiconoscereLaVersioneCorrente;
    [Test]
    procedure DovrebbeRiconoscereUnaVersioneCompatibile;
    [Test]
    procedure DovrebbeDareIlHackDelFileDiStrife;
    [Test]
    procedure DovrebbeRifiutareUnaVersioneSconosciuta;
    [Test]
    procedure DovrebbeRifiutareUnFileTroppoCorto;
    [Test]
    procedure DovrebbeUsareLaPrimaVoceConLoStessoTesto;
    [Test]
    procedure DovrebbeEssereUgualeAllaVecchiaCatenaDiTest;
  end;

implementation

const
  CURRENT = 206;

{ TTestSerializerSaveGameVersions }

procedure TTestSerializerSaveGameVersions.Setup;
begin
  FVersions := TSaveGameVersions.Create(CURRENT);
  FVersions.AddCompatible('version 113', 113);
  FVersions.AddCompatible('version 204', 204);
  FVersions.AddCompatible('version 204', 999);
  FVersions.AddCompatible('version 001', CURRENT, 1);
  FillChar(FField, SizeOf(FField), Ord(' '));
end;

procedure TTestSerializerSaveGameVersions.TearDown;
begin
  FVersions.Free;
end;

procedure TTestSerializerSaveGameVersions.SetField(const AText: AnsiString);
begin
  FillChar(FField, SizeOf(FField), Ord(' '));
  Move(AText[1], FField[0], Length(AText));
end;

function TTestSerializerSaveGameVersions.Resolve(const ALength: Integer; out AVersion,
  AHack: Integer; out ASaved: string): TSaveGameVersionStatus;
begin
  Result := FVersions.Resolve(@FField[0], ALength, AVersion, AHack, ASaved);
end;

procedure TTestSerializerSaveGameVersions.DovrebbeRiconoscereLaVersioneCorrente;
var
  LVersion, LHack: Integer;
  LSaved: string;
begin
  SetField('version 206');
  Assert.AreEqual(Ord(sgvCurrent), Ord(Resolve(100, LVersion, LHack, LSaved)));
  Assert.AreEqual(CURRENT, LVersion);
  Assert.AreEqual(0, LHack);
end;

procedure TTestSerializerSaveGameVersions.DovrebbeRiconoscereUnaVersioneCompatibile;
var
  LVersion, LHack: Integer;
  LSaved: string;
begin
  SetField('version 113');
  Assert.AreEqual(Ord(sgvCompatible), Ord(Resolve(100, LVersion, LHack, LSaved)));
  Assert.AreEqual(113, LVersion);
  Assert.AreEqual('version 113', LSaved);
end;

procedure TTestSerializerSaveGameVersions.DovrebbeDareIlHackDelFileDiStrife;
var
  LVersion, LHack: Integer;
  LSaved: string;
begin
  SetField('version 001');
  Assert.AreEqual(Ord(sgvCompatible), Ord(Resolve(100, LVersion, LHack, LSaved)));
  Assert.AreEqual(CURRENT, LVersion);
  Assert.AreEqual(1, LHack);
end;

procedure TTestSerializerSaveGameVersions.DovrebbeRifiutareUnaVersioneSconosciuta;
var
  LVersion, LHack: Integer;
  LSaved: string;
begin
  SetField('version 777');
  Assert.AreEqual(Ord(sgvUnsupported), Ord(Resolve(100, LVersion, LHack, LSaved)));
  Assert.AreEqual('version 777', LSaved);
end;

procedure TTestSerializerSaveGameVersions.DovrebbeRifiutareUnFileTroppoCorto;
var
  LVersion, LHack: Integer;
  LSaved: string;
begin
  SetField('version 206');
  Assert.AreEqual(Ord(sgvTooShort), Ord(Resolve(10, LVersion, LHack, LSaved)));
  Assert.AreEqual(Ord(sgvCurrent), Ord(Resolve(11, LVersion, LHack, LSaved)));
end;

procedure TTestSerializerSaveGameVersions.DovrebbeUsareLaPrimaVoceConLoStessoTesto;
var
  LVersion, LHack: Integer;
  LSaved: string;
begin
  SetField('version 204');
  Resolve(100, LVersion, LHack, LSaved);
  Assert.AreEqual(204, LVersion);
end;

// The chain of tests of the old G_DoLoadGame of Doom, copied as it was, on every text of the form "version NNN"
procedure TTestSerializerSaveGameVersions.DovrebbeEssereUgualeAllaVecchiaCatenaDiTest;
var
  LNumber: Integer;
  LText: AnsiString;
  LOldVersion: Integer;
  LOldOk: Boolean;
  LVersion, LHack: Integer;
  LSaved: string;
  LStatus: TSaveGameVersionStatus;
begin
  for LNumber := 0 to 999 do
  begin
    LText := AnsiString(Format('version %.3d', [LNumber]));
    SetField(LText);
    LOldOk := True;
    LOldVersion := CURRENT;
    if LText <> 'version 206' then
    begin
      if LText = 'version 113' then
        LOldVersion := 113
      else if LText = 'version 204' then
        LOldVersion := 204
      else if LText = 'version 001' then
        LOldVersion := CURRENT
      else
        LOldOk := False;
    end;
    LStatus := Resolve(100, LVersion, LHack, LSaved);
    Assert.AreEqual(LOldOk, LStatus <> sgvUnsupported, string(LText));
    if LOldOk then
      Assert.AreEqual(LOldVersion, LVersion, string(LText));
  end;
end;

end.
