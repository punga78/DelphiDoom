{******************************************************************************}
{                                                                              }
{  DelphiDoom: dynamic lights library - the loader of the lumps               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.DynLights.Loader;

interface

uses
  DelphiDoom.DynLights.Intf;

type
  /// <summary>
  ///   Reads the lumps of lights of the loaded files (the old SC_ParceDynamicLights): the WAD
  ///   lumps LIGHTDEF, then GLDEFS (if they are read as LIGHTDEF), then the entries of the PAK
  ///   and PK3 files named LIGHTDEF, LIGHTDEF.txt, GLDEFS and GLDEFS.txt. Each text is read on
  ///   its own
  /// </summary>
  TDynLightLoader = class(TInterfacedObject, IDynLightLoader)
  private
    FSource: IDynLightTextSource;
    FFilter: IDynLightTextFilter;
    FParser: IDynLightParser;
    procedure ParseText(const AText: string);
  public
    /// <param name="AFilter">May be nil: the text goes to the parser as it is</param>
    constructor Create(const ASource: IDynLightTextSource; const AFilter: IDynLightTextFilter;
      const AParser: IDynLightParser);
    function Load(AGldefsAsLightDef: Boolean): Boolean;
  end;

implementation

uses
  System.SysUtils;

const
  LIGHTS_LUMP_NAME = 'LIGHTDEF';
  GLDEFS_LUMP_NAME = 'GLDEFS';
  SNeedsCollaborators = 'TDynLightLoader needs a source and a parser';

{ TDynLightLoader }

constructor TDynLightLoader.Create(const ASource: IDynLightTextSource;
  const AFilter: IDynLightTextFilter; const AParser: IDynLightParser);
begin
  inherited Create;
  if not (Assigned(ASource) and Assigned(AParser)) then
    raise EArgumentNilException.Create(SNeedsCollaborators);
  FSource := ASource;
  FFilter := AFilter;
  FParser := AParser;
end;

procedure TDynLightLoader.ParseText(const AText: string);
begin
  if Assigned(FFilter) then
    FParser.Parse(FFilter.Filter(AText))
  else
    FParser.Parse(AText);
end;

function TDynLightLoader.Load(AGldefsAsLightDef: Boolean): Boolean;
var
  LText: string;
  LTexts: TArray<string>;
  LPakEntries: Integer;
begin
  Result := False;

  LTexts := FSource.WadLumpTexts(LIGHTS_LUMP_NAME);
  for LText in LTexts do
  begin
    Result := True;
    ParseText(LText);
  end;

  if AGldefsAsLightDef then
  begin
    LTexts := FSource.WadLumpTexts(GLDEFS_LUMP_NAME);
    for LText in LTexts do
    begin
      Result := True;
      ParseText(LText);
    end;
  end;

  // the PAK and PK3 files
  LPakEntries := 0;
  LTexts := FSource.PakTexts(LIGHTS_LUMP_NAME);
  for LText in LTexts do
  begin
    Inc(LPakEntries);
    ParseText(LText);
  end;
  LTexts := FSource.PakTexts(LIGHTS_LUMP_NAME + '.txt');
  for LText in LTexts do
  begin
    Inc(LPakEntries);
    ParseText(LText);
  end;

  if AGldefsAsLightDef then
  begin
    LTexts := FSource.PakTexts(GLDEFS_LUMP_NAME);
    for LText in LTexts do
    begin
      Inc(LPakEntries);
      ParseText(LText);
    end;
    LTexts := FSource.PakTexts(GLDEFS_LUMP_NAME + '.txt');
    for LText in LTexts do
    begin
      Inc(LPakEntries);
      ParseText(LText);
    end;
  end;

  Result := Result or (LPakEntries > 0);
end;

end.
