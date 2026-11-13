{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - file system of id Tech 4: loading a pak           }
{                                                                              }
{  Port of the file system of Doom 3 (id Software, GPL v3): LoadZipFile        }
{  (framework\FileSystem.cpp). Copyright (C) 1999-2011 id Software LLC, a      }
{  ZeniMax Media company. Unzip.cpp is not ported: the ZIP is read by          }
{  TZipFileSource (System.Zip).                                                }
{                                                                              }
{  Based on the Doom 3 GPL Source Code (id Software). This unit is derived     }
{  from it and is therefore available under the GNU General Public License,    }
{  version 3, with the additional terms of the Doom 3 Source Code License      }
{  (see Reference\doom3\README.txt and Libs\IdLib\README.md); the repository   }
{  as a whole is GPL v2 or later.                                              }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Fs.PackLoader;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Fs.Intf;

type
  /// <summary>
  ///   IGamePackLoader: opens the file through the injected disk and reads it with TZipFileSource. The
  ///   stream stays open as long as the pak lives. Not thread safe: a pak reads its ZIP one entry at a time
  /// </summary>
  TZipPackLoader = class(TInterfacedObject, IGamePackLoader)
  strict private
    FDisk: IGameDisk;
  public
    constructor Create(const ADisk: IGameDisk);
    function Load(const AFileName: string): IGamePack;
  end;

implementation

uses
  System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Zip.Intf, DelphiDoom.Wad.Source.Zip,
  DelphiDoom.Wad.Fs.Pack;

{ TZipPackLoader }

constructor TZipPackLoader.Create(const ADisk: IGameDisk);
begin
  inherited Create;
  FDisk := ADisk;
end;

function TZipPackLoader.Load(const AFileName: string): IGamePack;
var
  LStream: TStream;
  LLength: Int64;
  LArchive: IZipArchive;
begin
  Result := nil;
  LStream := FDisk.OpenRead(AFileName);
  if not Assigned(LStream) then
    Exit;
  LLength := LStream.Size;
  try
    // the source owns the stream from here on, also when the file is not a ZIP
    LArchive := TZipFileSource.Create(LStream, True, AFileName);
  except
    on EWadException do
      Exit;
  end;
  Result := TGamePack.Create(LArchive, LLength);
end;

end.
