{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - the AUTOLOAD lumps                             }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.AutoLoad;

interface

uses
  System.SysUtils, DelphiDoom.Logging.Intf, DelphiDoom.Scanner.AutoLoad.Intf;

const
  AUTOLOAD_LUMP_NAME = 'AUTOLOAD';

type
  /// <summary>
  ///   Port of W_AutoLoadPakFiles: the lumps named AUTOLOAD list the files (PAK, PK3, WAD) that
  ///   the game adds when it starts
  /// </summary>
  TAutoLoadReader = class(TInterfacedObject, IAutoLoadReader)
  strict private
    FLumps: IAutoLoadLumps;
    FSink: IAutoLoadFileSink;
    FLog: ILog;
    procedure ParseLump(const AText: string);
  public
    /// <summary>ALog receives the warnings of the scanner; it may be nil</summary>
    constructor Create(const ALumps: IAutoLoadLumps; const ASink: IAutoLoadFileSink;
      const ALog: ILog);
    procedure Load;
  end;

implementation

uses
  DelphiDoom.Scanner.Scanner;

const
  SLumpsMissing = 'TAutoLoadReader: the lumps are nil';
  SSinkMissing = 'TAutoLoadReader: the file sink is nil';

{ TAutoLoadReader }

constructor TAutoLoadReader.Create(const ALumps: IAutoLoadLumps;
  const ASink: IAutoLoadFileSink; const ALog: ILog);
begin
  inherited Create;
  if not Assigned(ALumps) then
    raise EArgumentNilException.Create(SLumpsMissing);
  if not Assigned(ASink) then
    raise EArgumentNilException.Create(SSinkMissing);
  FLumps := ALumps;
  FSink := ASink;
  FLog := ALog;
end;

procedure TAutoLoadReader.ParseLump(const AText: string);
var
  LScanner: TScriptScanner;
begin
  LScanner := TScriptScanner.Create(AText, FLog);
  try
    while LScanner.GetString do
      FSink.AddFile(LScanner.AsString);
  finally
    LScanner.Free;
  end;
end;

procedure TAutoLoadReader.Load;
var
  LIndex: Integer;
  LCount: Integer;
begin
  // adding a file can add lumps: only the lumps that were there at the start are read
  LCount := FLumps.Count;
  for LIndex := 0 to LCount - 1 do
    if FLumps.NameOf(LIndex) = AUTOLOAD_LUMP_NAME then
      ParseLump(FLumps.TextOf(LIndex));
end;

end.
