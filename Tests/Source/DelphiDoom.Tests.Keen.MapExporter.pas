{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - a map saved as a picture             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.MapExporter;

interface

uses
  System.SysUtils, System.Classes, DUnitX.TestFramework, DelphiDoom.Keen.Types, DelphiDoom.Keen.Intf,
  DelphiDoom.Platform.Intf, DelphiDoom.Tests.Keen.Builders;

type
  [TestFixture]
  [Category('keen')]
  TTestKeenMapExporter = class(TObject)
  private
    FGame: TTestGame;
    FData: IKeenGameData;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure DovrebbeScrivereLaMappaNelFile;
    [Test]
    procedure DovrebbeDareAlCodificatoreLImmagineDellaMappa;
    [Test]
    procedure DovrebbeRifiutareUnaMappaCheNonCe;
    [Test]
    procedure DovrebbeSegnalareUnFileCheNonSiScrive;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Keen.Factory, DelphiDoom.Keen.MapExporter;

type
  /// <summary>A file store that keeps what it is given, and can refuse to write</summary>
  TFakeFiles = class(TInterfacedObject, IFileStore)
  public
    LastName: string;
    LastBytes: TBytes;
    Refuse: Boolean;
    function Exists(const AName: string): Boolean;
    function Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
    function Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
    function Read(const AName: string): TBytes;
    function Delete(const AName: string): Boolean;
    function EnsureDirectory(const APath: string): Boolean;
  end;

  /// <summary>An encoder that remembers the size of the image it got and gives 3 bytes</summary>
  TFakeEncoder = class(TInterfacedObject, IKeenImageEncoder)
  public
    Width: Integer;
    Height: Integer;
    function Encode(const AImage: TKeenChunkyImage): TBytes;
  end;

{ TFakeFiles }

function TFakeFiles.Exists(const AName: string): Boolean;
begin
  Result := AName = LastName;
end;

function TFakeFiles.Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
begin
  Result := not Refuse;
  if Result then
  begin
    LastName := AName;
    SetLength(LastBytes, ALength);
    Move(ASource^, LastBytes[0], ALength);
  end;
end;

function TFakeFiles.Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
begin
  Result := 0;
end;

function TFakeFiles.Read(const AName: string): TBytes;
begin
  Result := LastBytes;
end;

function TFakeFiles.Delete(const AName: string): Boolean;
begin
  Result := False;
end;

function TFakeFiles.EnsureDirectory(const APath: string): Boolean;
begin
  Result := True;
end;

{ TFakeEncoder }

function TFakeEncoder.Encode(const AImage: TKeenChunkyImage): TBytes;
begin
  Width := AImage.Width;
  Height := AImage.Height;
  Result := TBytes.Create(1, 2, 3);
end;

{ TTestKeenMapExporter }

procedure TTestKeenMapExporter.Setup;
begin
  FGame := TTestGame.Create(6);
  FData := TKeenFactory.OpenGameData(FGame.Files);
end;

procedure TTestKeenMapExporter.TearDown;
begin
  FData := nil;
  FGame.Free;
end;

procedure TTestKeenMapExporter.DovrebbeScrivereLaMappaNelFile;
var
  LFiles: TFakeFiles;
  LFilesIntf: IFileStore;
  LExporter: IKeenMapExporter;
begin
  LFiles := TFakeFiles.Create;
  LFilesIntf := LFiles;
  LExporter := TKeenMapExporter.Create(FData, TKeenFactory.CreateMapRenderer, TFakeEncoder.Create, LFilesIntf);
  LExporter.SaveMapPicture(0, 'C:\out\map0.png');
  Assert.AreEqual('C:\out\map0.png', LFiles.LastName);
  Assert.AreEqual<Integer>(3, Length(LFiles.LastBytes));
end;

procedure TTestKeenMapExporter.DovrebbeDareAlCodificatoreLImmagineDellaMappa;
var
  LEncoder: TFakeEncoder;
  LEncoderIntf: IKeenImageEncoder;
begin
  LEncoder := TFakeEncoder.Create;
  LEncoderIntf := LEncoder;
  TKeenMapExporter.Create(FData, TKeenFactory.CreateMapRenderer, LEncoderIntf, TFakeFiles.Create)
    .SaveMapPicture(FGame.MapSlot[1], 'x.png');
  Assert.AreEqual(FGame.MapWidth[1] * 16, LEncoder.Width);
  Assert.AreEqual(FGame.MapHeight[1] * 16, LEncoder.Height);
end;

procedure TTestKeenMapExporter.DovrebbeRifiutareUnaMappaCheNonCe;
var
  LExporter: IKeenMapExporter;
begin
  LExporter := TKeenMapExporter.Create(FData, TKeenFactory.CreateMapRenderer, TFakeEncoder.Create, TFakeFiles.Create);
  Assert.WillRaise(procedure begin LExporter.SaveMapPicture(2, 'x.png'); end, EKeenDataException);
end;

procedure TTestKeenMapExporter.DovrebbeSegnalareUnFileCheNonSiScrive;
var
  LFiles: TFakeFiles;
  LFilesIntf: IFileStore;
  LExporter: IKeenMapExporter;
begin
  LFiles := TFakeFiles.Create;
  LFilesIntf := LFiles;
  LFiles.Refuse := True;
  LExporter := TKeenMapExporter.Create(FData, TKeenFactory.CreateMapRenderer, TFakeEncoder.Create, LFilesIntf);
  Assert.WillRaise(procedure begin LExporter.SaveMapPicture(0, 'x.png'); end, EKeenException);
end;

procedure TTestKeenMapExporter.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(procedure begin TKeenMapExporter.Create(nil, TKeenFactory.CreateMapRenderer, TFakeEncoder.Create, TFakeFiles.Create); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenMapExporter.Create(FData, nil, TFakeEncoder.Create, TFakeFiles.Create); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenMapExporter.Create(FData, TKeenFactory.CreateMapRenderer, nil, TFakeFiles.Create); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TKeenMapExporter.Create(FData, TKeenFactory.CreateMapRenderer, TFakeEncoder.Create, nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestKeenMapExporter);

end.
