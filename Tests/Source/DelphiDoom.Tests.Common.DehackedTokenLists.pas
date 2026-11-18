{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the lists of names of the tables of DEHACKED (engine)  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Common.DehackedTokenLists;

interface

uses
  System.SysUtils, DUnitX.TestFramework, d_delphi, DelphiDoom.Engine.Dehacked.TokenLists;

type
  [TestFixture]
  [Category('dehacked')]
  TTestEngineDehackedTokenLists = class(TObject)
  public
    [Test]
    procedure DovrebbeAggiungereINomiNellOrdine;

    [Test]
    procedure DovrebbeAggiungereInCodaAQuelloCheLaListaHaGia;

    [Test]
    procedure DovrebbeLasciareVuotaLaListaSenzaNomi;

    [Test]
    procedure DovrebbeFallireSeLaListaENil;
  end;

implementation

procedure TTestEngineDehackedTokenLists.DovrebbeAggiungereINomiNellOrdine;
var
  LList: TDTextList;
begin
  LList := TDTextList.Create;
  try
    TEngineDehackedTokenLists.Fill(LList, TArray<string>.Create('ID #', 'INITIAL FRAME', 'HIT POINTS'));
    Assert.AreEqual(3, LList.Count);
    Assert.AreEqual('ID #', LList[0]);
    Assert.AreEqual('INITIAL FRAME', LList[1]);
    Assert.AreEqual('HIT POINTS', LList[2]);
    Assert.AreEqual(2, LList.IndexOf('HIT POINTS'));
  finally
    LList.Free;
  end;
end;

procedure TTestEngineDehackedTokenLists.DovrebbeAggiungereInCodaAQuelloCheLaListaHaGia;
var
  LList: TDTextList;
begin
  LList := TDTextList.Create;
  try
    LList.Add('FIRST');
    TEngineDehackedTokenLists.Fill(LList, TArray<string>.Create('SECOND'));
    Assert.AreEqual(2, LList.Count);
    Assert.AreEqual('SECOND', LList[1]);
  finally
    LList.Free;
  end;
end;

procedure TTestEngineDehackedTokenLists.DovrebbeLasciareVuotaLaListaSenzaNomi;
var
  LList: TDTextList;
begin
  LList := TDTextList.Create;
  try
    TEngineDehackedTokenLists.Fill(LList, nil);
    Assert.AreEqual(0, LList.Count);
  finally
    LList.Free;
  end;
end;

procedure TTestEngineDehackedTokenLists.DovrebbeFallireSeLaListaENil;
begin
  Assert.WillRaise(
    procedure
    begin
      TEngineDehackedTokenLists.Fill(nil, TArray<string>.Create('X'));
    end,
    EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestEngineDehackedTokenLists);

end.
