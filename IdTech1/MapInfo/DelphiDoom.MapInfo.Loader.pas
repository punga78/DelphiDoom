{******************************************************************************}
{                                                                              }
{  DelphiDoom: UMAPINFO library - the loader of the lumps                     }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.MapInfo.Loader;

interface

uses
  DelphiDoom.MapInfo.Intf;

type
  /// <summary>
  ///   Reads the UMAPINFO (or UMAPDEF) of the loaded files into a catalog, as the old
  ///   U_ParseMapInfo did: the WAD lumps are one text, joined by a line break, then each
  ///   PAK/PK3 entry is a text of its own
  /// </summary>
  TMapInfoLoader = class(TInterfacedObject, IMapInfoLoader)
  private
    FSource: IMapInfoTextSource;
    FFilter: IMapInfoTextFilter;
    FParser: IMapInfoParser;
    FCatalog: IMapInfoCatalog;
    procedure ParseText(const AText: string; AIsDefault: Boolean);
  public
    /// <param name="AFilter">May be nil: the text goes to the parser as it is</param>
    constructor Create(const ASource: IMapInfoTextSource; const AFilter: IMapInfoTextFilter;
      const AParser: IMapInfoParser; const ACatalog: IMapInfoCatalog);
    procedure Load(const ALumpName: string; AIsDefault: Boolean);
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings, DelphiDoom.MapInfo.Types;

const
  SNeedsCollaborators = 'TMapInfoLoader needs a source, a parser and a catalog';

{ TMapInfoLoader }

constructor TMapInfoLoader.Create(const ASource: IMapInfoTextSource;
  const AFilter: IMapInfoTextFilter; const AParser: IMapInfoParser;
  const ACatalog: IMapInfoCatalog);
begin
  inherited Create;
  if not (Assigned(ASource) and Assigned(AParser) and Assigned(ACatalog)) then
    raise EArgumentNilException.Create(SNeedsCollaborators);
  FSource := ASource;
  FFilter := AFilter;
  FParser := AParser;
  FCatalog := ACatalog;
end;

procedure TMapInfoLoader.ParseText(const AText: string; AIsDefault: Boolean);
var
  LText: string;
  LEntry: TMapInfoEntry;
begin
  LText := AText;
  if Assigned(FFilter) then
    LText := FFilter.Filter(LText);
  for LEntry in FParser.Parse(LText) do
    FCatalog.AddParsed(LEntry, AIsDefault);
end;

procedure TMapInfoLoader.Load(const ALumpName: string; AIsDefault: Boolean);
var
  LText: string;
  LLumpText: string;
begin
  LText := '';
  for LLumpText in FSource.WadLumpTexts(TScannerStrings.UpperAscii(ALumpName)) do
    if LText = '' then
      LText := LLumpText
    else
      LText := LText + #13#10 + LLumpText;

  if LText <> '' then
    ParseText(LText, AIsDefault);

  // the PAK files are asked with the name as it was given
  for LText in FSource.PakTexts(ALumpName) do
    ParseText(LText, AIsDefault);
  for LText in FSource.PakTexts(ALumpName + '.txt') do
    ParseText(LText, AIsDefault);
end;

end.
