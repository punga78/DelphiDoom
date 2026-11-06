{******************************************************************************}
{                                                                              }
{  DelphiDoom: MUSINFO library - the loader                                   }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MusInfo.Loader;

interface

uses
  DelphiDoom.MusInfo.Intf;

type
  /// <summary>
  ///   What P_InitMusInfo did: takes the text of the MUSINFO lump, reads it and adds every
  ///   entry to the catalog. A second Load adds to what is there (entries with the same map
  ///   and id are replaced)
  /// </summary>
  TMusInfoLoader = class(TInterfacedObject, IMusInfoLoader)
  private
    FSource: IMusInfoTextSource;
    FParser: IMusInfoParser;
    FCatalog: IMusInfoCatalog;
  public
    constructor Create(const ASource: IMusInfoTextSource; const AParser: IMusInfoParser;
      const ACatalog: IMusInfoCatalog);
    procedure Load;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.MusInfo.Types;

const
  SNeedsCollaborators = 'TMusInfoLoader needs a source, a parser and a catalog';

{ TMusInfoLoader }

constructor TMusInfoLoader.Create(const ASource: IMusInfoTextSource; const AParser: IMusInfoParser;
  const ACatalog: IMusInfoCatalog);
begin
  inherited Create;
  if not (Assigned(ASource) and Assigned(AParser) and Assigned(ACatalog)) then
    raise EArgumentNilException.Create(SNeedsCollaborators);
  FSource := ASource;
  FParser := AParser;
  FCatalog := ACatalog;
end;

procedure TMusInfoLoader.Load;
var
  LText: string;
  LEntry: TMusInfoEntry;
begin
  if not FSource.TryGetText(MUSINFO_LUMP_NAME, LText) then
    Exit;
  for LEntry in FParser.Parse(LText) do
    FCatalog.Add(LEntry);
end;

end.
