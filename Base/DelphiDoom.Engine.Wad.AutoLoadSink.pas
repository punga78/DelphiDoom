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
  DelphiDoom.Scanner.AutoLoad.Intf;

type
  /// <summary>PAK_AddFile of the engine: files and directories, as the command line does</summary>
  TEngineAutoLoadSink = class(TInterfacedObject, IAutoLoadFileSink)
  public
    procedure AddFile(const AFileName: string);
  end;

implementation

uses
  w_pak;

{ TEngineAutoLoadSink }

procedure TEngineAutoLoadSink.AddFile(const AFileName: string);
begin
  PAK_AddFile(AFileName);
end;

end.
