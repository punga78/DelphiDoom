{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the pointers of d_delphi at 64 bit (issue #44)          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Win64.CommonPointers;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, DUnitX.TestFramework;

type
  /// <summary>
  ///   Regressions of the port to 64 bit: a pointer kept in an Integer (or in a LongInt used as an
  ///   address) loses its high half, and the first use of it is an access violation.
  /// </summary>
  [TestFixture]
  [Category('win64')]
  TTestWin64CommonPointers = class(TObject)
  strict private
    FFileName: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;
    [Test]
    procedure DovrebbeScambiareStringhEOggettiDellaLista;
    [Test]
    procedure DovrebbeTenereIPuntatoriInteriNellaListaDiPuntatori;
    [Test]
    procedure DovrebbeLeggereDalBufferDelFileConCache;
    [Test]
    procedure DovrebbeLeggereUnBloccoDopoIlRiempimentoDelBuffer;
    [Test]
    procedure DovrebbeUsareUnTipoDellaListaDiStringheSottoDueGiga;
  end;

implementation

uses
  d_delphi;

procedure TTestWin64CommonPointers.Setup;
var
  LStream: TFileStream;
  LBytes: TBytes;
  LIndex: Integer;
begin
  FFileName := TPath.GetTempFileName;
  SetLength(LBytes, 4096);
  for LIndex := 0 to High(LBytes) do
    LBytes[LIndex] := Byte(LIndex * 7 + 3);
  LStream := TFileStream.Create(FFileName, fmCreate);
  try
    LStream.WriteBuffer(LBytes[0], Length(LBytes));
  finally
    LStream.Free;
  end;
end;

procedure TTestWin64CommonPointers.TearDown;
begin
  if FileExists(FFileName) then
    DeleteFile(FFileName);
end;

procedure TTestWin64CommonPointers.DovrebbeScambiareStringhEOggettiDellaLista;
var
  LList: TDStringList;
  LFirst, LSecond: TObject;
begin
  LFirst := TObject.Create;
  LSecond := TObject.Create;
  LList := TDStringList.Create;
  try
    LList.AddObject('uno', LFirst);
    LList.AddObject('due', LSecond);
    LList.Exchange(0, 1);
    Assert.AreEqual('due', LList[0]);
    Assert.AreEqual('uno', LList[1]);
    Assert.IsTrue(LList.Objects[0] = LSecond);
    Assert.IsTrue(LList.Objects[1] = LFirst);
  finally
    LList.Free;
    LFirst.Free;
    LSecond.Free;
  end;
end;

procedure TTestWin64CommonPointers.DovrebbeTenereIPuntatoriInteriNellaListaDiPuntatori;
var
  LList: TDPointerList;
  LValue: Pointer;
begin
  LList := TDPointerList.Create;
  try
    // an address above 4 GB at 64 bit: the high half must survive
{$IFDEF CPUX64}
    LValue := Pointer(NativeUInt($1FFFFFFF0));
{$ELSE}
    LValue := Pointer(NativeUInt($FFFFFFF0));
{$ENDIF}
    LList.Add(LValue);
    Assert.IsTrue(LList[0] = LValue);
  finally
    LList.Free;
  end;
end;

procedure TTestWin64CommonPointers.DovrebbeLeggereDalBufferDelFileConCache;
var
  LFile: TCachedFile;
  LFirst, LSecond: array[0..15] of Byte;
  LIndex: Integer;
begin
  LFile := TCachedFile.Create(FFileName, fOpenReadOnly);
  try
    // the first read fills the buffer, the second is served from the buffer
    LFile.Seek(0, 0);
    Assert.AreEqual(16, LFile.Read(LFirst, 16));
    Assert.AreEqual(16, LFile.Read(LSecond, 16));
    for LIndex := 0 to 15 do
    begin
      Assert.AreEqual(Integer(Byte(LIndex * 7 + 3)), Integer(LFirst[LIndex]));
      Assert.AreEqual(Integer(Byte((LIndex + 16) * 7 + 3)), Integer(LSecond[LIndex]));
    end;
  finally
    LFile.Free;
  end;
end;

procedure TTestWin64CommonPointers.DovrebbeLeggereUnBloccoDopoIlRiempimentoDelBuffer;
var
  LFile: TCachedFile;
  LBlock: array[0..31] of Byte;
  LIndex: Integer;
begin
  LFile := TCachedFile.Create(FFileName, fOpenReadOnly, 256);
  try
    Assert.AreEqual(32, LFile.Read(LBlock, 32));
    LFile.Seek(100, 0);
    Assert.AreEqual(32, LFile.Read(LBlock, 32));
    for LIndex := 0 to 31 do
      Assert.AreEqual(Integer(Byte((100 + LIndex) * 7 + 3)), Integer(LBlock[LIndex]));
  finally
    LFile.Free;
  end;
end;

procedure TTestWin64CommonPointers.DovrebbeUsareUnTipoDellaListaDiStringheSottoDueGiga;
begin
  // the type of the items array must be smaller than 2 GB at 64 bit, where an item takes 16 bytes
  Assert.IsTrue(Int64(SizeOf(TStringItem)) * Int64(MaxListSize + 1) < Int64(2) * 1024 * 1024 * 1024);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestWin64CommonPointers);

end.
