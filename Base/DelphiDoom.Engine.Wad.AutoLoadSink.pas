{******************************************************************************}
{                                                                              }
{  DelphiDoom: adds the files named by the AUTOLOAD lumps                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Wad.AutoLoadSink;

interface

uses
  DelphiDoom.Scanner.AutoLoad.Intf,
  DelphiDoom.Pak.Intf;

type
  /// <summary>The PAK file system of the engine: files and directories, as the command line does</summary>
  TEngineAutoLoadSink = class(TInterfacedObject, IAutoLoadFileSink)
  strict private
    FContainers: IPakContainers;
  public
    /// <summary>Raises EArgumentNilException when AContainers is nil</summary>
    constructor Create(const AContainers: IPakContainers);
    procedure AddFile(const AFileName: string);
  end;

implementation

uses
  System.SysUtils;

const
  SContainersMissing = 'TEngineAutoLoadSink: the PAK file system is nil';

{ TEngineAutoLoadSink }

constructor TEngineAutoLoadSink.Create(const AContainers: IPakContainers);
begin
  inherited Create;
  if not Assigned(AContainers) then
    raise EArgumentNilException.Create(SContainersMissing);
  FContainers := AContainers;
end;

procedure TEngineAutoLoadSink.AddFile(const AFileName: string);
begin
  FContainers.AddFile(AFileName);
end;

end.
