{******************************************************************************}
{                                                                              }
{  DelphiDoom: voxel library - the loader of voxel files                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Voxel.Loader;

interface

uses
  System.SysUtils,
  DelphiDoom.Logging.Intf,
  DelphiDoom.Voxel.Types,
  DelphiDoom.Voxel.Intf;

type
  /// <summary>
  ///   Finds the format of a file by its extension (capital letters: .DDMESH, .DDVOX, .KVX or
  ///   none, .VOX), asks the format for the bytes and decodes them. A file that is not there
  ///   gives nil without a word (the engine looks for voxels that are not always present); a
  ///   file that is not good gives nil and a warning.
  /// </summary>
  TVoxelLoader = class(TInterfacedObject, IVoxelLoader)
  strict private
    FFormats: TArray<IVoxelFormat>;
    FSource: IVoxelFileSource;
    FLog: ILog;
    function FormatOf(const AName: string): IVoxelFormat;
  public
    constructor Create(const AFormats: TArray<IVoxelFormat>; const ASource: IVoxelFileSource;
      const ALog: ILog);
    function IsSupported(const AName: string): Boolean;
    function Load(const AName: string): IVoxelModel;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

{ TVoxelLoader }

constructor TVoxelLoader.Create(const AFormats: TArray<IVoxelFormat>;
  const ASource: IVoxelFileSource; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  if not Assigned(ALog) then
    raise EArgumentNilException.Create('ALog');
  FFormats := AFormats;
  FSource := ASource;
  FLog := ALog;
end;

function TVoxelLoader.FormatOf(const AName: string): IVoxelFormat;
var
  LExtension: string;
  LFormat: IVoxelFormat;
begin
  // only a..z are made capital, as the old strupper
  LExtension := TScannerStrings.UpperAscii(ExtractFileExt(AName));
  for LFormat in FFormats do
    if LFormat.Handles(LExtension) then
      Exit(LFormat);
  Result := nil;
end;

function TVoxelLoader.IsSupported(const AName: string): Boolean;
begin
  Result := Assigned(FormatOf(AName));
end;

function TVoxelLoader.Load(const AName: string): IVoxelModel;
var
  LFormat: IVoxelFormat;
  LBytes: TBytes;
begin
  Result := nil;
  LFormat := FormatOf(AName);
  if not Assigned(LFormat) then
    Exit;
  if not LFormat.Locate(FSource, AName, LBytes) then
    Exit;
  try
    Result := LFormat.Decode(LBytes);
  except
    on E: EVoxelException do
    begin
      FLog.Warning(Format(SVoxelLoaderFailed, [AName, E.Message]));
      Result := nil;
    end;
  end;
end;

end.
