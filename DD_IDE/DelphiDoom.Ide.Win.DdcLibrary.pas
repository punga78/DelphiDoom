{******************************************************************************}
{                                                                              }
{  DD_IDE: the ddc_*.dll of the games for the ide library                      }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.Win.DdcLibrary;

interface

uses
  System.SysUtils,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   The script compiler and the lists of the compiler library of a game, which live in
  ///   ddc_doom.dll, ddc_heretic.dll, ddc_hexen.dll and ddc_strife.dll (the same ones the
  ///   command line compiler ddc.exe uses, through SCRIPT\ddc_base). Between Open and Close the dll
  ///   stays loaded, so that the many calls that follow do not load it again
  /// </summary>
  TDdcIdeLibrary = class(TInterfacedObject, IIdeScriptCompiler, IIdeGameLibrary)
  public
    function Compile(const AGame, ASource: string; out APCode, AMessages: string): Boolean;
    function Disassemble(const AGame, APCode: string): string;
    procedure Open(const AGame: string);
    procedure Close;
    function TryGetLines(const AData: TIdeLibraryData; const AGame: string;
      out ALines: TArray<string>): Boolean;
    function TryGetUnitFunctions(const AGame: string;
      out AUnits: TArray<TIdeUnitDeclarations>): Boolean;
  end;

implementation

uses
  System.Classes,
  ddc_base;

const
  EXPORT_PREFIXES: array[TIdeLibraryData] of string = (
    'dd_getconstants_',
    'dd_getvariables_',
    'dd_gettypes_',
    'dd_getclasses_',
    'dd_getevents_',
    'dd_getactordeffunctions_',
    'dd_getmobjinfocsv_',
    'dd_getstatescsv_',
    'dd_getspritescsv_');

{ TDdcIdeLibrary }

function TDdcIdeLibrary.Compile(const AGame, ASource: string; out APCode, AMessages: string): Boolean;
begin
  APCode := '';
  AMessages := '';
  Result := dll_compile(AGame, ASource, APCode, AMessages);
end;

function TDdcIdeLibrary.Disassemble(const AGame, APCode: string): string;
begin
  Result := dll_getdisassembly(AGame, APCode);
end;

procedure TDdcIdeLibrary.Open(const AGame: string);
begin
  dll_loadlibrary(AGame);
end;

procedure TDdcIdeLibrary.Close;
begin
  dll_freelibrary;
end;

function TDdcIdeLibrary.TryGetLines(const AData: TIdeLibraryData; const AGame: string;
  out ALines: TArray<string>): Boolean;
var
  LList: TStringList;
begin
  LList := dll_getpcharfunc(AGame, EXPORT_PREFIXES[AData]);
  Result := LList <> nil;
  if not Result then
  begin
    ALines := nil;
    Exit;
  end;
  try
    ALines := LList.ToStringArray;
  finally
    LList.Free;
  end;
end;

function TDdcIdeLibrary.TryGetUnitFunctions(const AGame: string;
  out AUnits: TArray<TIdeUnitDeclarations>): Boolean;
var
  LUnits: TStringList;
  LIndex: Integer;
  LDeclarations: TStringList;
begin
  LUnits := dll_getuntisfuncdeclarations(AGame);
  Result := LUnits <> nil;
  if not Result then
  begin
    AUnits := nil;
    Exit;
  end;
  try
    SetLength(AUnits, LUnits.Count);
    for LIndex := 0 to LUnits.Count - 1 do
    begin
      LDeclarations := LUnits.Objects[LIndex] as TStringList;
      AUnits[LIndex].UnitName := LUnits[LIndex];
      AUnits[LIndex].Declarations := LDeclarations.ToStringArray;
      LDeclarations.Free;
    end;
  finally
    LUnits.Free;
  end;
end;

end.
