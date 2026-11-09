{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the xcom formats library - the image exporter           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{  (no code of OpenXcom in this unit)                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Xcom.ImageExporter;

interface

uses
  System.SysUtils, DUnitX.TestFramework, DelphiDoom.Xcom.Types, DelphiDoom.Xcom.Image, DelphiDoom.Xcom.Intf,
  DelphiDoom.Platform.Intf;

type
  /// <summary>A file store that keeps what it is given, or refuses it</summary>
  TFakeFileStore = class(TInterfacedObject, IFileStore)
  public
    WrittenName: string;
    WrittenBytes: TBytes;
    Accept: Boolean;
    constructor Create;
    function Exists(const AName: string): Boolean;
    function Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
    function Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
    function Read(const AName: string): TBytes;
    function Delete(const AName: string): Boolean;
    function EnsureDirectory(const APath: string): Boolean;
  end;

  /// <summary>An encoder that gives always the same bytes</summary>
  TFakeEncoder = class(TInterfacedObject, IXcomImageEncoder)
  public
    LastTransparent: Boolean;
    function Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
  end;

  [TestFixture]
  [Category('xcom')]
  TTestXcomImageExporter = class(TObject)
  public
    [Test]
    procedure DovrebbeScrivereNelFileILByteDellEncoder;
    [Test]
    procedure DovrebbeDireAllEncoderSeLoZeroETrasparente;
    [Test]
    procedure DovrebbeRifiutareUnFileCheNonSiScrive;
    [Test]
    procedure DovrebbeVolereLeSueParti;
  end;

implementation

uses
  DelphiDoom.Xcom.ImageExporter;

{ TFakeFileStore }

constructor TFakeFileStore.Create;
begin
  inherited Create;
  Accept := True;
end;

function TFakeFileStore.Exists(const AName: string): Boolean;
begin
  Result := False;
end;

function TFakeFileStore.Write(const AName: string; ASource: Pointer; ALength: Integer): Boolean;
begin
  Result := Accept;
  if not Accept then
    Exit;
  WrittenName := AName;
  SetLength(WrittenBytes, ALength);
  Move(ASource^, WrittenBytes[0], ALength);
end;

function TFakeFileStore.Append(const AName: string; ASource: Pointer; ALength: Integer): Integer;
begin
  Result := 0;
end;

function TFakeFileStore.Read(const AName: string): TBytes;
begin
  Result := nil;
end;

function TFakeFileStore.Delete(const AName: string): Boolean;
begin
  Result := False;
end;

function TFakeFileStore.EnsureDirectory(const APath: string): Boolean;
begin
  Result := False;
end;

{ TFakeEncoder }

function TFakeEncoder.Encode(const AImage: TXcomImage; ATransparentZero: Boolean): TBytes;
begin
  LastTransparent := ATransparentZero;
  Result := [1, 2, 3];
end;

{ TTestXcomImageExporter }

procedure TTestXcomImageExporter.DovrebbeScrivereNelFileILByteDellEncoder;
var
  LStore: TFakeFileStore;
  LStoreIntf: IFileStore;
  LExporter: TXcomImageExporter;
begin
  LStore := TFakeFileStore.Create;
  LStoreIntf := LStore;
  LExporter := TXcomImageExporter.Create(TFakeEncoder.Create, LStoreIntf);
  try
    LExporter.Save(TXcomImage.Create(1, 1), 'out.png', False);
    Assert.AreEqual('out.png', LStore.WrittenName);
    Assert.AreEqual(3, Integer(Length(LStore.WrittenBytes)));
    Assert.AreEqual(2, Integer(LStore.WrittenBytes[1]));
  finally
    LExporter.Free;
  end;
end;

procedure TTestXcomImageExporter.DovrebbeDireAllEncoderSeLoZeroETrasparente;
var
  LEncoder: TFakeEncoder;
  LEncoderIntf: IXcomImageEncoder;
  LExporter: TXcomImageExporter;
begin
  LEncoder := TFakeEncoder.Create;
  LEncoderIntf := LEncoder;
  LExporter := TXcomImageExporter.Create(LEncoderIntf, TFakeFileStore.Create);
  try
    LExporter.Save(TXcomImage.Create(1, 1), 'out.png', True);
    Assert.IsTrue(LEncoder.LastTransparent);
  finally
    LExporter.Free;
  end;
end;

procedure TTestXcomImageExporter.DovrebbeRifiutareUnFileCheNonSiScrive;
var
  LStore: TFakeFileStore;
  LStoreIntf: IFileStore;
  LExporter: TXcomImageExporter;
begin
  LStore := TFakeFileStore.Create;
  LStoreIntf := LStore;
  LStore.Accept := False;
  LExporter := TXcomImageExporter.Create(TFakeEncoder.Create, LStoreIntf);
  try
    Assert.WillRaise(procedure begin LExporter.Save(TXcomImage.Create(1, 1), 'out.png', False); end, EXcomException);
  finally
    LExporter.Free;
  end;
end;

procedure TTestXcomImageExporter.DovrebbeVolereLeSueParti;
begin
  Assert.WillRaise(procedure begin TXcomImageExporter.Create(nil, TFakeFileStore.Create); end, EArgumentNilException);
  Assert.WillRaise(procedure begin TXcomImageExporter.Create(TFakeEncoder.Create, nil); end, EArgumentNilException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXcomImageExporter);

end.
