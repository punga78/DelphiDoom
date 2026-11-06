{******************************************************************************}
{                                                                              }
{  DelphiDoom: engine - where the UMAPINFO texts come from                     }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.MapInfo.TextSource;

{$IFNDEF HEXEN}

interface

uses
  DelphiDoom.MapInfo.Intf;

type
  /// <summary>
  ///   The texts of a map info lump from the WADs (the lumps of that name, joined) and from the
  ///   PAK file system, and the script preprocessor of the engine (#define, #include ...) that
  ///   cleans each of them
  /// </summary>
  TEngineMapInfoTextSource = class(TInterfacedObject, IMapInfoTextSource, IMapInfoTextFilter)
  public
    function WadLumpTexts(const AUpperName: string): TArray<string>;
    function PakTexts(const AFileName: string): TArray<string>;
    function Filter(const AText: string): string;
  end;

implementation

uses
  d_delphi,
  sc_utils,
  w_pak,
  w_wad;

var
  // PAK_StringIterator takes a plain procedure: what it gives is kept here until it returns
  GCollectedTexts: TArray<string>;

procedure CollectText(const AText: string);
begin
  SetLength(GCollectedTexts, Length(GCollectedTexts) + 1);
  GCollectedTexts[High(GCollectedTexts)] := AText;
end;

{ TEngineMapInfoTextSource }

function TEngineMapInfoTextSource.WadLumpTexts(const AUpperName: string): TArray<string>;
var
  LIndex: Integer;
  LText: string;
begin
  // all the lumps of that name make one text
  LText := '';
  for LIndex := 0 to W_NumLumps - 1 do
    if char8tostring(W_GetNameForNum(LIndex)) = AUpperName then
    begin
      if LText = '' then
        LText := W_TextLumpNum(LIndex)
      else
        LText := LText + #13#10 + W_TextLumpNum(LIndex);
    end;
  if LText = '' then
    Result := nil
  else
    Result := TArray<string>.Create(LText);
end;

function TEngineMapInfoTextSource.PakTexts(const AFileName: string): TArray<string>;
begin
  GCollectedTexts := nil;
  PAK_StringIterator(AFileName, @CollectText);
  Result := GCollectedTexts;
  GCollectedTexts := nil;
end;

function TEngineMapInfoTextSource.Filter(const AText: string): string;
begin
  Result := SC_Preprocess(AText, False);
end;

{$ELSE}

interface

implementation

{$ENDIF}

end.
