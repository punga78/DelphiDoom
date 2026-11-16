{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - source: one file as one lump                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Source.SingleFile;

interface

uses
  System.SysUtils, System.Classes, DelphiDoom.Wad.Types, DelphiDoom.Wad.Source.Base;

type
  /// <summary>
  ///   A file that is not a container: one lump named after the file (base
  ///   name without extension, 8 characters)
  /// </summary>
  TSingleFileSource = class(TWadStreamSource)
  public
    constructor Create(const AFileName: string; AStream: TStream; AOwnsStream: Boolean);
  end;

implementation

uses
  DelphiDoom.Wad.Name;

{ TSingleFileSource }

constructor TSingleFileSource.Create(const AFileName: string; AStream: TStream;
  AOwnsStream: Boolean);
var
  LEntries: TArray<TWadEntry>;
begin
  inherited Create(AFileName, TWadSourceKind.SingleFile, AStream, AOwnsStream);
  SetLength(LEntries, 1);
  LEntries[0].Name := TWadLumpName.FromFileName(AFileName);
  LEntries[0].Offset := 0;
  LEntries[0].Size := AStream.Size;
  SetEntries(LEntries);
end;

end.
