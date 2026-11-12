{******************************************************************************}
{                                                                              }
{  DelphiDoom: Xcom32 - the shaders of the game for the display of the host     }
{  What OpenGL::set_shader read: a .OpenGL.shader file of the Shaders folder    }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Xcom.HostShaderLoader;

interface

uses
  System.SysUtils, DelphiDoom.XcomEngine.Intf, DelphiDoom.XcomEngine.Shader.Types,
  DelphiDoom.XcomEngine.ShaderFileReader, DelphiDoom.GameHost.Types, DelphiDoom.GameHost.Video.Intf;

type
  /// <summary>
  ///   IGameHostShaderLoader on the shader files of OpenXcom: the bytes come from the catalog by the path of the
  ///   option, the reader turns them into the two programs. A file that is not there is said in the log; a file
  ///   that cannot be read is said by the reader
  /// </summary>
  TXcomHostShaderLoader = class(TInterfacedObject, IGameHostShaderLoader)
  strict private
    FCatalog: IXcomShaderCatalog;
    FReader: TXcomShaderFileReader;
    FLog: IXcomLog;
  public
    /// <param name="AReader">Reads the shader files; owned (freed with the loader)</param>
    /// <param name="ALog">Where a missing file is said; nil for nowhere</param>
    constructor Create(const ACatalog: IXcomShaderCatalog; AReader: TXcomShaderFileReader;
      const ALog: IXcomLog = nil);
    destructor Destroy; override;
    function TryLoad(const APath: string; out ASource: TGameHostShaderSource): Boolean;
  end;

implementation

const
  SLogError = 'ERROR';
  SShaderNotFound = 'requested file not found: %s';

constructor TXcomHostShaderLoader.Create(const ACatalog: IXcomShaderCatalog; AReader: TXcomShaderFileReader;
  const ALog: IXcomLog);
begin
  // the reader is owned from here on, also when the construction fails
  FReader := AReader;
  inherited Create;
  if not Assigned(ACatalog) then
    raise EArgumentNilException.Create('ACatalog');
  if not Assigned(AReader) then
    raise EArgumentNilException.Create('AReader');
  FCatalog := ACatalog;
  FLog := ALog;
end;

destructor TXcomHostShaderLoader.Destroy;
begin
  FReader.Free;
  inherited Destroy;
end;

function TXcomHostShaderLoader.TryLoad(const APath: string; out ASource: TGameHostShaderSource): Boolean;
var
  LBytes: TBytes;
  LSource: TXcomShaderSource;
begin
  ASource := Default(TGameHostShaderSource);
  Result := False;
  if not FCatalog.TryRead(APath, LBytes) then
  begin
    if Assigned(FLog) then
      FLog.Write(SLogError, Format(SShaderNotFound, [APath]));
    Exit;
  end;
  if not FReader.TryRead(APath, LBytes, LSource) then
    Exit;
  ASource.IsGlsl := LSource.IsGlsl;
  ASource.Linear := LSource.Linear;
  ASource.Fragment := LSource.Fragment;
  ASource.Vertex := LSource.Vertex;
  Result := True;
end;

end.
