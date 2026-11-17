{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Quake III host library - the file system calls      }
{  (FS_FOpenFileByMode, FS_Read2, FS_Write, FS_FCloseFile, FS_Seek,             }
{  FS_GetFileList) with files and a writer in memory                            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Q3Host.Files;

interface

uses
  DUnitX.TestFramework, DelphiDoom.Qvm.Intf, DelphiDoom.Wad.Fs.Intf, DelphiDoom.Wad.Fs.Write.Intf,
  DelphiDoom.Q3Host.Types, DelphiDoom.Q3Host.Intf, DelphiDoom.Tests.Q3Host.Services;

type
  [TestFixture]
  [Category('Q3Host')]
  TTestQ3FileSyscalls = class
  strict private
    FFiles: IGameFileSystem;
    FWriterObject: TQ3FakeGameWriter;
    FWriter: IGameFileWriter;
    FHost: IQ3SyscallHost;
    FMachine: IQvmMachine;
    function CreateHost(AModule: TQ3Module; AWithWriter: Boolean): IQ3SyscallHost;
    function Call(const AValues: array of Integer): Integer;
    procedure Put(AAddress: Integer; const AText: AnsiString);
    function Open(const AName: AnsiString; AMode: Integer; out AHandle: Integer): Integer;
    function ReadText(AHandle, ALength: Integer): AnsiString;
  public
    [Setup]
    procedure Setup;
    [Test]
    procedure UnFileInLetturaDovrebbeDareLaLunghezzaEUnaManiglia;
    [Test]
    procedure UnFileCheNonCeDovrebbeDareMenoUnoEManigliaZero;
    [Test]
    procedure LaLetturaDovrebbeAndareAvantiEFermarsiAllaFine;
    [Test]
    procedure IlSeekDiUnFileSuDiscoDovrebbeSeguireLOrigine;
    [Test]
    procedure UnaManigliaNullaDovrebbeNonFareNiente;
    [Test]
    procedure UnPuntatoreNulloInLetturaDovrebbeDireSeIlFileCe;
    [Test]
    procedure LeManiglieDovrebberoFinireEDarsiDopoLaChiusura;
    [Test]
    procedure LaScritturaEdAppendDovrebberoArrivareAlWriter;
    [Test]
    procedure SenzaWriterLaScritturaDovrebbeDareMenoUno;
    [Test]
    procedure UnModoNonValidoDovrebbeEssereUnErrore;
    [Test]
    procedure LaListaDeiFileDovrebbeEssereImpacchettataComeFsGetFileList;
    [Test]
    procedure LaListaDovrebbeFermarsiQuandoIlBufferEPieno;
    [Test]
    procedure ModlistDovrebbeDareZeroEIlBufferVuoto;
    [Test]
    procedure CgameNonDovrebbeAvereLaListaDeiFile;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Qvm.Types, DelphiDoom.Qvm.Factory, DelphiDoom.Q3Host.Opcodes, DelphiDoom.Q3Host.Factory,
  DelphiDoom.Q3Host.Services.Intf, DelphiDoom.Q3Host.GameFiles, DelphiDoom.Tests.Qvm.Programs,
  DelphiDoom.Tests.Qvm.Support, DelphiDoom.Tests.Q3Host.Support;

const
  NAME_ADDRESS = 1000;
  HANDLE_ADDRESS = 1200;
  BUFFER_ADDRESS = 3000;

function BytesOf(const AText: AnsiString): TBytes;
begin
  SetLength(Result, Length(AText));
  if Length(AText) > 0 then
    Move(AText[1], Result[0], Length(AText));
end;

function TTestQ3FileSyscalls.CreateHost(AModule: TQ3Module; AWithWriter: Boolean): IQ3SyscallHost;
var
  LServices: TQ3HostServices;
  LWriter: IGameFileWriter;
begin
  LWriter := nil;
  if AWithWriter then
    LWriter := FWriter;
  LServices := Default(TQ3HostServices);
  LServices.Files := TQ3GameHostFiles.Create(FFiles, LWriter);
  Result :=TQ3HostFactory.CreateHostWithServices(AModule, TQ3RecordingConsole.Create(nil), TQ3FixedTime.Create(0),
    LServices);
end;

procedure TTestQ3FileSyscalls.Setup;
var
  LFiles: TQ3FakeGameFileSystem;
  LText: Integer;
begin
  LFiles := TQ3FakeGameFileSystem.Create;
  FFiles := LFiles;
  FWriterObject := TQ3FakeGameWriter.Create;
  FWriter := FWriterObject;
  LFiles.Add('data.txt', BytesOf('0123456789'));
  LFiles.Add('maps/a.bsp', BytesOf('A'));
  LFiles.Add('maps/b.bsp', BytesOf('B'));
  LFiles.Add('maps/c.txt', BytesOf('C'));
  FHost := CreateHost(TQ3Module.Game, True);
  FMachine := TQvmFactory.CreateMachine('files', TQvmPrograms.AnySystemCall(LText), FHost);
end;

function TTestQ3FileSyscalls.Call(const AValues: array of Integer): Integer;
begin
  Result := TQ3TestCalls.Invoke(FHost, FMachine, AValues);
end;

procedure TTestQ3FileSyscalls.Put(AAddress: Integer; const AText: AnsiString);
begin
  FMachine.Memory.WriteString(AAddress, AText, Length(AText) + 1);
end;

function TTestQ3FileSyscalls.Open(const AName: AnsiString; AMode: Integer; out AHandle: Integer): Integer;
begin
  Put(NAME_ADDRESS, AName);
  Result := Call([G_FS_FOPEN_FILE, NAME_ADDRESS, HANDLE_ADDRESS, AMode]);
  AHandle := FMachine.Memory.ReadInt32(HANDLE_ADDRESS);
end;

function TTestQ3FileSyscalls.ReadText(AHandle, ALength: Integer): AnsiString;
begin
  FMachine.Memory.Fill(BUFFER_ADDRESS, 0, 64);
  Call([G_FS_READ, BUFFER_ADDRESS, ALength, AHandle]);
  Result := FMachine.Memory.ReadString(BUFFER_ADDRESS);
end;

procedure TTestQ3FileSyscalls.UnFileInLetturaDovrebbeDareLaLunghezzaEUnaManiglia;
var
  LHandle: Integer;
begin
  Assert.AreEqual(10, Open('data.txt', 0, LHandle));
  Assert.IsTrue(LHandle > 0);
  Assert.AreEqual('0123456789', string(ReadText(LHandle, 10)));
  Call([G_FS_FCLOSE_FILE, LHandle]);
end;

procedure TTestQ3FileSyscalls.UnFileCheNonCeDovrebbeDareMenoUnoEManigliaZero;
var
  LHandle: Integer;
begin
  FMachine.Memory.WriteInt32(HANDLE_ADDRESS, 55);
  Assert.AreEqual(-1, Open('missing.txt', 0, LHandle));
  Assert.AreEqual(0, LHandle);
end;

procedure TTestQ3FileSyscalls.LaLetturaDovrebbeAndareAvantiEFermarsiAllaFine;
var
  LHandle: Integer;
begin
  Open('data.txt', 0, LHandle);
  Assert.AreEqual('0123', string(ReadText(LHandle, 4)));
  Assert.AreEqual('4567', string(ReadText(LHandle, 4)));
  // only what is left is written; the rest of the buffer is as it was (zeroes here)
  Assert.AreEqual('89', string(ReadText(LHandle, 4)));
  Assert.AreEqual('', string(ReadText(LHandle, 4)));
end;

procedure TTestQ3FileSyscalls.IlSeekDiUnFileSuDiscoDovrebbeSeguireLOrigine;
var
  LHandle: Integer;
begin
  Open('data.txt', 0, LHandle);
  // FS_SEEK_CUR 0, FS_SEEK_END 1, FS_SEEK_SET 2
  Assert.AreEqual(0, Call([G_FS_SEEK, LHandle, 4, 2]));
  Assert.AreEqual('456', string(ReadText(LHandle, 3)));
  Assert.AreEqual(0, Call([G_FS_SEEK, LHandle, 1, 0]));
  Assert.AreEqual('89', string(ReadText(LHandle, 3)));
  Assert.AreEqual(0, Call([G_FS_SEEK, LHandle, -2, 1]));
  Assert.AreEqual('89', string(ReadText(LHandle, 3)));
  // fseek refuses a position before the start; one past the end is allowed
  Assert.AreEqual(-1, Call([G_FS_SEEK, LHandle, -1, 2]));
  Assert.AreEqual(0, Call([G_FS_SEEK, LHandle, 100, 2]));
  Assert.AreEqual('', string(ReadText(LHandle, 3)));
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_FS_SEEK, LHandle, 0, 7]);
    end, EQ3HostException));
end;

procedure TTestQ3FileSyscalls.UnaManigliaNullaDovrebbeNonFareNiente;
begin
  FMachine.Memory.Fill(BUFFER_ADDRESS, $55, 8);
  Assert.AreEqual(0, Call([G_FS_READ, BUFFER_ADDRESS, 4, 0]));
  Assert.AreEqual($55, Integer(FMachine.Memory.ReadByte(BUFFER_ADDRESS)));
  Assert.AreEqual(0, Call([G_FS_WRITE, BUFFER_ADDRESS, 4, 0]));
  Call([G_FS_FCLOSE_FILE, 0]);
end;

procedure TTestQ3FileSyscalls.UnPuntatoreNulloInLetturaDovrebbeDireSeIlFileCe;
begin
  Put(NAME_ADDRESS, 'data.txt');
  Assert.AreEqual(1, Call([G_FS_FOPEN_FILE, NAME_ADDRESS, 0, 0]));
  Put(NAME_ADDRESS, 'nothing');
  Assert.AreEqual(0, Call([G_FS_FOPEN_FILE, NAME_ADDRESS, 0, 0]));
end;

procedure TTestQ3FileSyscalls.LeManiglieDovrebberoFinireEDarsiDopoLaChiusura;
var
  LIndex, LHandle, LFirst: Integer;
begin
  Open('data.txt', 0, LFirst);
  for LIndex := 2 to 63 do
  begin
    Open('data.txt', 0, LHandle);
    Assert.AreEqual(LIndex, LHandle);
  end;
  // none free is the Com_Error of FS_HandleForFile
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    var
      LExtra: Integer;
    begin
      Open('data.txt', 0, LExtra);
    end, EQ3HostException));
  Call([G_FS_FCLOSE_FILE, LFirst]);
  Open('data.txt', 0, LHandle);
  Assert.AreEqual(LFirst, LHandle);
end;

procedure TTestQ3FileSyscalls.LaScritturaEdAppendDovrebberoArrivareAlWriter;
var
  LHandle: Integer;
begin
  Assert.AreEqual(0, Open('out.txt', 1, LHandle));
  Assert.IsTrue(LHandle > 0);
  Put(BUFFER_ADDRESS, 'abc');
  Call([G_FS_WRITE, BUFFER_ADDRESS, 3, LHandle]);
  Call([G_FS_FCLOSE_FILE, LHandle]);
  Assert.AreEqual(Integer(3), Integer(Length(FWriterObject.Bytes('out.txt'))));
  Assert.AreEqual(0, Open('out.txt', 3, LHandle));
  Call([G_FS_WRITE, BUFFER_ADDRESS, 2, LHandle]);
  Assert.AreEqual(Integer(5), Integer(Length(FWriterObject.Bytes('out.txt'))));
  Assert.AreEqual('write out.txt', FWriterObject.Modes[0]);
  Assert.AreEqual('append-sync out.txt', FWriterObject.Modes[1]);
  // reading a file that is open for writing gives nothing
  Assert.AreEqual('', string(ReadText(LHandle, 4)));
end;

procedure TTestQ3FileSyscalls.SenzaWriterLaScritturaDovrebbeDareMenoUno;
var
  LHandle: Integer;
begin
  FHost := CreateHost(TQ3Module.Game, False);
  FMachine := TQvmFactory.CreateMachine('files2', TQvmPrograms.AnySystemCall(LHandle), FHost);
  Assert.AreEqual(-1, Open('out.txt', 1, LHandle));
  Assert.AreEqual(0, LHandle);
end;

procedure TTestQ3FileSyscalls.UnModoNonValidoDovrebbeEssereUnErrore;
begin
  Put(NAME_ADDRESS, 'data.txt');
  Assert.IsTrue(TQ3TestCalls.Raises(
    procedure
    begin
      Call([G_FS_FOPEN_FILE, NAME_ADDRESS, HANDLE_ADDRESS, 9]);
    end, EQ3HostException));
end;

procedure TTestQ3FileSyscalls.LaListaDeiFileDovrebbeEssereImpacchettataComeFsGetFileList;
var
  LMemory: IQvmMemory;
begin
  LMemory := FMachine.Memory;
  Put(NAME_ADDRESS, 'maps');
  Put(NAME_ADDRESS + 16, '.bsp');
  LMemory.Fill(BUFFER_ADDRESS, $55, 40);
  Assert.AreEqual(2, Call([G_FS_GETFILELIST, NAME_ADDRESS, NAME_ADDRESS + 16, BUFFER_ADDRESS, 40]));
  // each name with its zero, one after the other
  Assert.AreEqual('a.bsp', string(LMemory.ReadString(BUFFER_ADDRESS)));
  Assert.AreEqual('b.bsp', string(LMemory.ReadString(BUFFER_ADDRESS + 6)));
  Assert.AreEqual($55, Integer(LMemory.ReadByte(BUFFER_ADDRESS + 12)));
end;

procedure TTestQ3FileSyscalls.LaListaDovrebbeFermarsiQuandoIlBufferEPieno;
begin
  Put(NAME_ADDRESS, 'maps');
  Put(NAME_ADDRESS + 16, '.bsp');
  // nTotal + nLen + 1 < bufsize: the first fits in 8 (0 + 6 + 1 < 8), the second does not (6 + 6 + 1)
  Assert.AreEqual(1, Call([G_FS_GETFILELIST, NAME_ADDRESS, NAME_ADDRESS + 16, BUFFER_ADDRESS, 8]));
  Assert.AreEqual('a.bsp', string(FMachine.Memory.ReadString(BUFFER_ADDRESS)));
  // exactly 7 does not fit even the first
  Assert.AreEqual(0, Call([G_FS_GETFILELIST, NAME_ADDRESS, NAME_ADDRESS + 16, BUFFER_ADDRESS, 7]));
end;

procedure TTestQ3FileSyscalls.ModlistDovrebbeDareZeroEIlBufferVuoto;
begin
  Put(NAME_ADDRESS, '$MODLIST');
  Put(NAME_ADDRESS + 16, '');
  FMachine.Memory.Fill(BUFFER_ADDRESS, $55, 8);
  Assert.AreEqual(0, Call([G_FS_GETFILELIST, NAME_ADDRESS, NAME_ADDRESS + 16, BUFFER_ADDRESS, 8]));
  Assert.AreEqual(0, Integer(FMachine.Memory.ReadByte(BUFFER_ADDRESS)));
end;

procedure TTestQ3FileSyscalls.CgameNonDovrebbeAvereLaListaDeiFile;
var
  LHost: IQ3SyscallHost;
begin
  LHost := CreateHost(TQ3Module.CGame, True);
  Assert.IsTrue(LHost.Registry.IsRegistered(CG_FS_FOPENFILE));
  Assert.IsTrue(LHost.Registry.IsRegistered(CG_FS_SEEK));
  // 12 common + open, read, write, close, seek
  Assert.AreEqual(12 + 5, LHost.Registry.RegisteredCount);
  LHost := CreateHost(TQ3Module.Ui, True);
  Assert.IsTrue(LHost.Registry.IsRegistered(UI_FS_GETFILELIST));
  Assert.AreEqual(12 + 6, LHost.Registry.RegisteredCount);
end;

end.
