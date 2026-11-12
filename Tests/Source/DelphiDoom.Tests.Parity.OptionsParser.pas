{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the parity library - the options                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Parity.OptionsParser;

interface

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DelphiDoom.Parity.OptionsParser,
  DelphiDoom.Parity.Types;

type
  [TestFixture]
  [Category('parity')]
  TTestParityOptionsParser = class(TObject)
  public
    [Test]
    procedure SenzaOpzioniNonDovrebbeEssereAttivo;
    [Test]
    procedure UnaListaVuotaNonDovrebbeEssereAttiva;
    [Test]
    procedure DovrebbeLeggereIlFileDelloStato;
    [Test]
    procedure DovrebbeLeggereIlDettaglioDelloStato;
    [Test]
    procedure DovrebbeLeggereIlFileDeiFotogrammi;
    [Test]
    procedure DovrebbeLeggereIlFotogrammaDaScaricare;
    [Test]
    procedure DovrebbeLeggereIlPilota;
    [Test]
    procedure IlSemeDovrebbeEssereUnNumeroA32Bit;
    [Test]
    procedure IlNomeDellOpzioneNonDovrebbeDipendereDalleMaiuscole;
    [Test]
    procedure DovrebbeIgnorareLeAltreOpzioni;
    [Test]
    procedure UnaOpzioneSenzaValoreDovrebbeDareEccezione;
    [Test]
    procedure UnaOpzioneSeguitaDaUnAltraOpzioneDovrebbeDareEccezione;
    [Test]
    procedure UnNumeroSbagliatoDovrebbeDareEccezione;
    [Test]
    procedure IlDettaglioSenzaLoStatoDovrebbeDareEccezione;
    [Test]
    procedure UnIntervalloAlContrarioDovrebbeDareEccezione;
    [Test]
    procedure ZeroTicDelPilotaDovrebbeDareEccezione;
    [Test]
    procedure UnTicDiScaricoNegativoDovrebbeDareEccezione;
    [Test]
    procedure LeOpzioniDovrebberoPoterEssereUsateInsieme;
  end;

implementation

procedure TTestParityOptionsParser.SenzaOpzioniNonDovrebbeEssereAttivo;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('DOOM32.EXE', '-IWAD', 'DOOM1.WAD'));
  Assert.IsFalse(LOptions.IsActive);
  Assert.AreEqual(-1, LOptions.FrameDumpTic);
end;

procedure TTestParityOptionsParser.UnaListaVuotaNonDovrebbeEssereAttiva;
begin
  Assert.IsFalse(TParityOptionsParser.Parse(nil).IsActive);
end;

procedure TTestParityOptionsParser.DovrebbeLeggereIlFileDelloStato;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-statehash', 'a.txt'));
  Assert.AreEqual('a.txt', LOptions.StateHashFile);
  Assert.IsTrue(LOptions.IsActive);
  Assert.IsFalse(LOptions.StateDetail);
end;

procedure TTestParityOptionsParser.DovrebbeLeggereIlDettaglioDelloStato;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(
    TArray<string>.Create('X.EXE', '-statehash', 'a.txt', '-statehash-detail', '100', '102'));
  Assert.IsTrue(LOptions.StateDetail);
  Assert.AreEqual(100, LOptions.StateDetailFirstTic);
  Assert.AreEqual(102, LOptions.StateDetailLastTic);
  Assert.AreEqual('a.txt', LOptions.StateHashFile);
end;

procedure TTestParityOptionsParser.DovrebbeLeggereIlFileDeiFotogrammi;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-framehash', 'f.txt'));
  Assert.AreEqual('f.txt', LOptions.FrameHashFile);
  Assert.IsTrue(LOptions.IsActive);
end;

procedure TTestParityOptionsParser.DovrebbeLeggereIlFotogrammaDaScaricare;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-framedump', '131', 'x.bmp'));
  Assert.AreEqual(131, LOptions.FrameDumpTic);
  Assert.AreEqual('x.bmp', LOptions.FrameDumpFile);
  Assert.IsTrue(LOptions.IsActive);
end;

procedure TTestParityOptionsParser.DovrebbeLeggereIlPilota;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-autodemo', '77', '3000'));
  Assert.IsTrue(LOptions.AutoDemo);
  Assert.AreEqual(Cardinal(77), LOptions.AutoDemoSeed);
  Assert.AreEqual(3000, LOptions.AutoDemoTics);
  Assert.IsTrue(LOptions.IsActive);
end;

procedure TTestParityOptionsParser.IlSemeDovrebbeEssereUnNumeroA32Bit;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-autodemo', '4294967295', '10'));
  Assert.AreEqual(Cardinal($FFFFFFFF), LOptions.AutoDemoSeed);
end;

procedure TTestParityOptionsParser.IlNomeDellOpzioneNonDovrebbeDipendereDalleMaiuscole;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-STATEHASH', 'A.TXT'));
  Assert.AreEqual('A.TXT', LOptions.StateHashFile);
end;

procedure TTestParityOptionsParser.DovrebbeIgnorareLeAltreOpzioni;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(
    TArray<string>.Create('X.EXE', '-warp', '1', '1', '-statehashing', 'z', '-nomusic'));
  Assert.IsFalse(LOptions.IsActive);
end;

procedure TTestParityOptionsParser.UnaOpzioneSenzaValoreDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-statehash'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.UnaOpzioneSeguitaDaUnAltraOpzioneDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-framehash', '-nomusic'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.UnNumeroSbagliatoDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-autodemo', 'ab', '10'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.IlDettaglioSenzaLoStatoDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-statehash-detail', '1', '2'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.UnIntervalloAlContrarioDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(
        TArray<string>.Create('X.EXE', '-statehash', 'a', '-statehash-detail', '9', '3'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.ZeroTicDelPilotaDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-autodemo', '1', '0'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.UnTicDiScaricoNegativoDovrebbeDareEccezione;
begin
  Assert.WillRaise(
    procedure
    begin
      TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-framedump', '-5', 'x.bmp'));
    end, EParityException);
end;

procedure TTestParityOptionsParser.LeOpzioniDovrebberoPoterEssereUsateInsieme;
var
  LOptions: TParityOptions;
begin
  LOptions := TParityOptionsParser.Parse(TArray<string>.Create('X.EXE', '-statehash', 's.txt', '-framehash',
    'f.txt', '-framedump', '5', 'x.bmp', '-autodemo', '3', '100'));
  Assert.AreEqual('s.txt', LOptions.StateHashFile);
  Assert.AreEqual('f.txt', LOptions.FrameHashFile);
  Assert.AreEqual(5, LOptions.FrameDumpTic);
  Assert.AreEqual(100, LOptions.AutoDemoTics);
end;

end.
