{******************************************************************************}
{                                                                              }
{  DelphiDoom: texture definitions library - the lump FLATINFO                 }
{  Copyright (C) 2004-2023 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.TextureDefs.FlatInfoParser;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.TextureDefs.Intf, DelphiDoom.TextureDefs.Types;

type
  /// <summary>
  ///   FLATINFO is a list of "FLAT name SIZE n". The parser does what the old R_ParseFlatInfoText
  ///   did, word by word: an unknown flat is a warning and only that word is skipped, so a
  ///   following "SIZE 128" is read as unknown words; a flat without SIZE gives the word back;
  ///   a size that is not 128 .. 4096 is 64x64. Problems are warnings, never exceptions
  /// </summary>
  TTextureDefsFlatInfoParser = class(TInterfacedObject, ITextureDefsFlatInfoParser)
  strict private
    FLog: ILog;
  public
    /// <param name="ALog">May be nil</param>
    constructor Create(const ALog: ILog);
    function Parse(const AText: string; const ACatalog: ITextureDefsFlatCatalog): TArray<TTextureDefsFlatSize>;
  end;

implementation

uses
  DelphiDoom.Scanner.Scanner, DelphiDoom.TextureDefs.FlatSizes, DelphiDoom.TextureDefs.Names;

const
  SUnknownFlat = 'R_ParseFlatInfo(): Unknown flat "%s"'#13#10;
  SUnknownToken = 'R_ParseFlatInfo(): Unknown token "%s"'#13#10;

{ TTextureDefsFlatInfoParser }

constructor TTextureDefsFlatInfoParser.Create(const ALog: ILog);
begin
  inherited Create;
  FLog := ALog;
end;

function TTextureDefsFlatInfoParser.Parse(const AText: string;
  const ACatalog: ITextureDefsFlatCatalog): TArray<TTextureDefsFlatSize>;
var
  LScanner: TScriptScanner;
  LToken: string;
  LFlatName: string;
  LIndex: Integer;
  LEntry: TTextureDefsFlatSize;
  LCount: Integer;
begin
  Result := nil;
  LCount := 0;
  LScanner := TScriptScanner.Create(AText, FLog);
  try
    while LScanner.GetString do
    begin
      LToken := TTextureDefsNames.UpperAscii(LScanner.AsString);
      if LToken = 'FLAT' then
      begin
        LScanner.MustGetString;
        LToken := TTextureDefsNames.UpperAscii(LScanner.AsString);
        LIndex := ACatalog.LastIndexOf(LToken);
        if LIndex < 0 then
        begin
          if Assigned(FLog) then
            FLog.Warning(Format(SUnknownFlat, [LToken]));
          Continue;
        end;
        LFlatName := LToken;

        LScanner.MustGetString;
        LToken := TTextureDefsNames.UpperAscii(LScanner.AsString);
        if LToken = 'SIZE' then
        begin
          LScanner.MustGetInteger;
          LEntry.FlatIndex := LIndex;
          LEntry.FlatName := LFlatName;
          LEntry.SizeCode := TTextureDefsFlatSizes.CodeFromSize(LScanner.AsInteger);
          SetLength(Result, LCount + 1);
          Result[LCount] := LEntry;
          Inc(LCount);
        end
        else
        begin
          LScanner.UnGet;
          Continue;
        end;
      end
      else if Assigned(FLog) then
        FLog.Warning(Format(SUnknownToken, [LToken]));
    end;
  finally
    LScanner.Free;
  end;
end;

end.
