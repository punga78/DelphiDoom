{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the file names of the saved games                      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Serializer.SaveGameName;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Serializer.SaveGameName;

type
  [TestFixture]
  [Category('serializer')]
  TTestSerializerSaveGameName = class
  public
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiDoom;
    [Test]
    procedure DovrebbeEssereUgualeAlVecchioCodiceDiHeretic;
    [Test]
    procedure DovrebbeDareIlFileDiUnoSlot;
    [Test]
    procedure DovrebbeAggiungereLEstensioneSeManca;
    [Test]
    procedure DovrebbeLasciareUnNomeConEstensioneInQualsiasiCaso;
    [Test]
    procedure DovrebbeNonRompersiSeIlPercorsoHaUnaPercentuale;
  end;

implementation

uses
  System.SysUtils;

type
  TOldLoadSlot = (load0, load1, load2, load3, load4, load5, load_end);

const
  SAVEGAMENAME = 'doomsav';

function D_GetSavePath: string;
begin
  Result := 'C:\Games\DATA\SAVE\';
end;

function itoa(i: Integer): string;
begin
  Result := IntToStr(i);
end;

function strupper(const S: string): string;
var
  Ch: Char;
  L: Integer;
  Source, Dest: PChar;
begin
  L := Length(S);
  SetLength(Result, L);
  Source := Pointer(S);
  Dest := Pointer(Result);
  while L <> 0 do
  begin
    Ch := Source^;
    if (Ch >= 'a') and (Ch <= 'z') then
      Dec(Ch, 32);
    Dest^ := Ch;
    Inc(Source);
    Inc(Dest);
    Dec(L);
  end;
end;

procedure sprintf(var Result: string; const Format: string; const Args: array of const);
begin
  Result := System.SysUtils.Format(Format, Args);
end;

// The old G_GetSaveName of Doom and Heretic, copied as they were
{$I old_sn.inc}

const
  NAMES: array[0..13] of string = ('0', '3', '5', '6', '12', '', 'x', 'game.dsg', 'game.DSG',
    'game.Dsg', 'c:\a\b.dsg', 'abc', '.dsg', 'dsg');

{ TTestSerializerSaveGameName }

procedure TTestSerializerSaveGameName.DovrebbeEssereUgualeAlVecchioCodiceDiDoom;
var
  LName: string;
begin
  for LName in NAMES do
    Assert.AreEqual(OldDoomGetSaveName(LName),
      TSaveGameName.Resolve(LName, Ord(load_end), D_GetSavePath + SAVEGAMENAME), LName);
end;

procedure TTestSerializerSaveGameName.DovrebbeEssereUgualeAlVecchioCodiceDiHeretic;
var
  LName: string;
begin
  for LName in NAMES do
    Assert.AreEqual(OldHereticGetSaveName(LName),
      TSaveGameName.Resolve(LName, Ord(load_end), D_GetSavePath + SAVEGAMENAME), LName);
end;

procedure TTestSerializerSaveGameName.DovrebbeDareIlFileDiUnoSlot;
begin
  Assert.AreEqual('save\doomsav2.dsg', TSaveGameName.Resolve('2', 6, 'save\doomsav'));
end;

procedure TTestSerializerSaveGameName.DovrebbeAggiungereLEstensioneSeManca;
begin
  Assert.AreEqual('partita.DSG', TSaveGameName.Resolve('partita', 6, 'x'));
  // a number out of the slots is a name of file
  Assert.AreEqual('6.DSG', TSaveGameName.Resolve('6', 6, 'x'));
end;

procedure TTestSerializerSaveGameName.DovrebbeLasciareUnNomeConEstensioneInQualsiasiCaso;
begin
  Assert.AreEqual('partita.dsg', TSaveGameName.Resolve('partita.dsg', 6, 'x'));
  Assert.AreEqual('partita.DsG', TSaveGameName.Resolve('partita.DsG', 6, 'x'));
end;

// the old code gave the path to sprintf as the format: a % in the path broke it
procedure TTestSerializerSaveGameName.DovrebbeNonRompersiSeIlPercorsoHaUnaPercentuale;
begin
  Assert.AreEqual('C:\100%\doomsav1.dsg', TSaveGameName.Resolve('1', 6, 'C:\100%\doomsav'));
end;

end.
