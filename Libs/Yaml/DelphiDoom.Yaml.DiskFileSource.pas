{******************************************************************************}
{                                                                              }
{  DelphiDoom: yaml library - reading the files from the disk                  }
{  Port of yaml-cpp 0.7.0 (MIT, Jesse Beder): see Libs\Yaml\README.md          }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Yaml.DiskFileSource;

interface

uses
  System.SysUtils,
  System.Classes,
  DelphiDoom.Yaml.Intf;

type
  /// <summary>IYamlFileSource over the files of the disk</summary>
  TYamlDiskFileSource = class(TInterfacedObject, IYamlFileSource)
  public
    function TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
  end;

implementation

function TYamlDiskFileSource.TryReadAllBytes(const AFileName: string; out ABytes: TBytes): Boolean;
var
  LStream: TFileStream;
begin
  ABytes := nil;
  if not FileExists(AFileName) then
    Exit(False);
  try
    LStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
    try
      SetLength(ABytes, LStream.Size);
      if Length(ABytes) > 0 then
        LStream.ReadBuffer(ABytes[0], Length(ABytes));
    finally
      LStream.Free;
    end;
    Result := True;
  except
    on EFOpenError do
      Result := False;
    on EReadError do
      Result := False;
  end;
end;

end.
