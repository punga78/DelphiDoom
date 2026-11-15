{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the declaration manager - TDeclHuffmanFrequencies and  }
{  the listHuffmanFrequencies command                                          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Decl.HuffmanFrequencies;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Decl.Huffman.Frequencies;

type
  TCollectingLog = class(TInterfacedObject, IIdLibLog)
  public
    Text: string;
    procedure Printf(const AMessage: string);
    procedure Warning(const AMessage: string);
  end;

  [TestFixture]
  [Category('Decl')]
  TTestDeclHuffmanFrequencies = class
  public
    [Test]
    procedure DovrebbePartireDallaTabellaDelCpp;
    [Test]
    procedure ClearDovrebbeMettereTuttoAUno;
    [Test]
    procedure CountDovrebbeContareUnoPerByte;
    [Test]
    procedure ListDovrebbeStampareRapportoETabellaComeIlCpp;
    [Test]
    procedure ListDovrebbeCalcolareIlRapportoConLaDivisioneIntera;
    [Test]
    procedure ListDovrebbeEssereMutaSenzaLog;
    [Test]
    procedure UnSimboloFuoriDaiDuecentocinquantaseiDovrebbeRifiutare;
  end;

implementation

procedure TCollectingLog.Printf(const AMessage: string);
begin
  Text := Text + AMessage;
end;

procedure TCollectingLog.Warning(const AMessage: string);
begin
end;

procedure TTestDeclHuffmanFrequencies.DovrebbePartireDallaTabellaDelCpp;
var
  LFrequencies: TDeclHuffmanFrequencies;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  try
    // the first lines of huffmanFrequencies[] of DeclManager.cpp
    Assert.AreEqual(1, LFrequencies[0]);
    Assert.AreEqual($00078FB6, LFrequencies[9], 'tab');
    Assert.AreEqual($000352A7, LFrequencies[10], 'new line');
    Assert.AreEqual($0002795E, LFrequencies[13], 'carriage return');
    Assert.AreEqual($00049600, LFrequencies[32], 'space');
    Assert.AreEqual(1, LFrequencies[255]);
  finally
    LFrequencies.Free;
  end;
end;

procedure TTestDeclHuffmanFrequencies.ClearDovrebbeMettereTuttoAUno;
var
  LFrequencies: TDeclHuffmanFrequencies;
  LIndex: Integer;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  try
    LFrequencies.Clear;
    for LIndex := 0 to MAX_HUFFMAN_SYMBOLS - 1 do
    begin
      Assert.AreEqual(1, LFrequencies[LIndex]);
    end;
  finally
    LFrequencies.Free;
  end;
end;

procedure TTestDeclHuffmanFrequencies.CountDovrebbeContareUnoPerByte;
var
  LFrequencies: TDeclHuffmanFrequencies;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  try
    LFrequencies.Clear;
    LFrequencies.Count('abca' + AnsiChar(#255));
    Assert.AreEqual(3, LFrequencies[Ord('a')]);
    Assert.AreEqual(2, LFrequencies[Ord('b')]);
    Assert.AreEqual(2, LFrequencies[Ord('c')]);
    Assert.AreEqual(2, LFrequencies[255]);
    Assert.AreEqual(1, LFrequencies[Ord('d')]);
  finally
    LFrequencies.Free;
  end;
end;

procedure TTestDeclHuffmanFrequencies.ListDovrebbeStampareRapportoETabellaComeIlCpp;
var
  LFrequencies: TDeclHuffmanFrequencies;
  LLog: TCollectingLog;
  LLogIntf: IIdLibLog;
  LLines: TArray<string>;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  LLog := TCollectingLog.Create;
  LLogIntf := LLog;
  try
    LFrequencies.List(LLogIntf);
    LLines := LLog.Text.Split([#10]);
    Assert.AreEqual('// compression ratio = 100%', LLines[0]);
    Assert.AreEqual('static int huffmanFrequencies[] = {', LLines[1]);
    Assert.AreEqual(#9'0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001, 0x00000001,', LLines[2]);
    Assert.AreEqual(#9'0x00000001, 0x00078fb6, 0x000352a7, 0x00000002, 0x00000001, 0x0002795e, 0x00000001, 0x00000001,', LLines[3]);
    Assert.AreEqual('}', LLines[34]);
    Assert.AreEqual<Integer>(36, Length(LLines), '2 + 32 + 1 lines and the empty rest');
  finally
    LLogIntf := nil;
    LFrequencies.Free;
  end;
end;

procedure TTestDeclHuffmanFrequencies.ListDovrebbeCalcolareIlRapportoConLaDivisioneIntera;
var
  LFrequencies: TDeclHuffmanFrequencies;
  LLog: TCollectingLog;
  LLogIntf: IIdLibLog;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  LLog := TCollectingLog.Create;
  LLogIntf := LLog;
  try
    // 100 * 64 / 100 = 64: the shipped table says 64%
    LFrequencies.SetTotals(100, 64);
    LFrequencies.List(LLogIntf);
    Assert.IsTrue(LLog.Text.StartsWith('// compression ratio = 64%'#10));
    LLog.Text := '';
    // 100 * 2 / 3 = 66 (integer division as in the C++)
    LFrequencies.SetTotals(3, 2);
    LFrequencies.List(LLogIntf);
    Assert.IsTrue(LLog.Text.StartsWith('// compression ratio = 66%'#10));
  finally
    LLogIntf := nil;
    LFrequencies.Free;
  end;
end;

procedure TTestDeclHuffmanFrequencies.ListDovrebbeEssereMutaSenzaLog;
var
  LFrequencies: TDeclHuffmanFrequencies;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  try
    LFrequencies.List(nil);
    Assert.Pass;
  finally
    LFrequencies.Free;
  end;
end;

procedure TTestDeclHuffmanFrequencies.UnSimboloFuoriDaiDuecentocinquantaseiDovrebbeRifiutare;
var
  LFrequencies: TDeclHuffmanFrequencies;
begin
  LFrequencies := TDeclHuffmanFrequencies.Create;
  try
    Assert.WillRaise(
      procedure
      begin
        LFrequencies[256];
      end, EArgumentOutOfRangeException);
    Assert.WillRaise(
      procedure
      begin
        LFrequencies[-1];
      end, EArgumentOutOfRangeException);
  finally
    LFrequencies.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestDeclHuffmanFrequencies);

end.