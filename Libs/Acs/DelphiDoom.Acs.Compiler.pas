{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - the compiler                            }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.Compiler;

interface

uses
  System.SysUtils, DelphiDoom.Acs.Intf, DelphiDoom.Logging.Intf;

type
  /// <summary>
  ///   ACC 1.10: the text of a script becomes the object code of Hexen (the BEHAVIOR lump).
  ///   Every call starts from nothing: nothing is kept between two scripts. It tells what it did
  ///   to the log, as the old compiler did to the console
  /// </summary>
  TAcsCompiler = class(TInterfacedObject, IAcsCompiler)
  private
    FProvider: IAcsSourceProvider;
    FLog: ILog;
    procedure Say(const AText: string);
  public
    /// <param name="AProvider">Gives the files that the script includes</param>
    /// <param name="ALog">May be nil</param>
    constructor Create(const AProvider: IAcsSourceProvider; const ALog: ILog);
    function Compile(const ASourceName: string; const ASource: TBytes): TBytes;
  end;

implementation

uses
  DelphiDoom.Acs.Types, DelphiDoom.Acs.Diagnostics, DelphiDoom.Acs.SymbolTable,
  DelphiDoom.Acs.StringTable, DelphiDoom.Acs.ObjectWriter, DelphiDoom.Acs.Tokenizer,
  DelphiDoom.Acs.Parser;

const
  SBanner = #13#10'ACC Version 1.10 by Ben Gokey'#13#10 +
    'Copyright (c) 1995 Raven Software, Corp.'#13#10;
  SByteOrder = 'Host byte order: LITTLE endian'#13#10;

function OneOrMany(ACount: Integer; const AIfOne, AIfMany: string): string;
begin
  if ACount = 1 then
    Result := AIfOne
  else
    Result := AIfMany;
end;

{ TAcsCompiler }

constructor TAcsCompiler.Create(const AProvider: IAcsSourceProvider; const ALog: ILog);
begin
  inherited Create;
  FProvider := AProvider;
  FLog := ALog;
end;

procedure TAcsCompiler.Say(const AText: string);
begin
  if Assigned(FLog) then
    FLog.Info(AText);
end;

function TAcsCompiler.Compile(const ASourceName: string; const ASource: TBytes): TBytes;
var
  LDiagnostics: TAcsDiagnostics;
  LSymbols: TAcsSymbolTable;
  LStrings: TAcsStringTable;
  LWriter: TAcsObjectWriter;
  LTokenizer: TAcsTokenizer;
  LPosition: IAcsSourcePosition;
  LParser: TAcsParser;
begin
  LDiagnostics := TAcsDiagnostics.Create;
  LSymbols := TAcsSymbolTable.Create;
  LStrings := TAcsStringTable.Create(LDiagnostics);
  LWriter := TAcsObjectWriter.Create(LDiagnostics);
  LTokenizer := TAcsTokenizer.Create(LDiagnostics, LSymbols, FProvider);
  // the tokenizer lives as long as this reference does
  LPosition := LTokenizer;
  LParser := TAcsParser.Create(LDiagnostics, LSymbols, LStrings, LWriter, LTokenizer);
  try
    Say(SBanner);
    Say(SByteOrder);
    LDiagnostics.Position := LPosition;

    LTokenizer.Open(ASourceName, ASource);
    LParser.Parse;

    LStrings.WriteStrings(LWriter);
    LWriter.WriteLong(LongWord(LWriter.Address), 4);
    LWriter.AppendScriptTable;
    LStrings.WriteList(LWriter);
    Result := LWriter.ToBytes;

    Say(Format(#13#10'''%s'':'#13#10'  %d %s (%d included),', [ASourceName, LTokenizer.Line,
      OneOrMany(LTokenizer.Line, 'line', 'lines'), LTokenizer.IncludedLines]));
    Say(Format(' %d %s (%d open), %d functions'#13#10, [LParser.ScriptCount,
      OneOrMany(LParser.ScriptCount, 'script', 'scripts'), LParser.OpenScriptCount, 0]));
    Say(Format('  %d world %s, %d map %s'#13#10, [LParser.WorldVarCount,
      OneOrMany(LParser.WorldVarCount, 'variable', 'variables'), LParser.MapVarCount,
      OneOrMany(LParser.MapVarCount, 'variable', 'variables')]));
    Say(Format('  object ''%s'': %d bytes'#13#10, [ChangeFileExt(ASourceName, '.o'),
      LWriter.Address]));
  finally
    LDiagnostics.Position := nil;
    LParser.Free;
    LPosition := nil;
    LWriter.Free;
    LStrings.Free;
    LSymbols.Free;
    LDiagnostics.Free;
  end;
end;

end.