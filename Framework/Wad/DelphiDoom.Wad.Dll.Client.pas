{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - the library through the DLL                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.Client;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf;

type
  /// <summary>
  ///   What TWadFactory is, but through an IWadDll: the objects it gives are the interfaces
  ///   of the library (IWadSource, IWadDirectory, IWadBuilder ...), so the code that uses the
  ///   library works the same on the DLL, on the engine linked in the executable or on a fake
  ///   IWadDll in the tests. The IWadDll is given by the constructor
  /// </summary>
  /// <remarks>
  ///   The sources and the directories of one client work together; those of a client and
  ///   those of the classes of the library do not mix
  /// </remarks>
  TWadDllClient = class
  private
    FDll: IWadDll;
  public
    constructor Create(const ADll: IWadDll);
    function OpenPath(const APath: string): IWadSource;
    function OpenBytes(const AName: string; const ABytes: TBytes): IWadSource;
    function CreateDirectory: IWadDirectory;
    function CreateFinder(const ADirectory: IWadDirectory): IWadFinder;
    function CreateReader(const ADirectory: IWadDirectory): ILumpReader;
    function CreateBuilder(AKind: TWadKind = TWadKind.PWad): IWadBuilder;
  end;

implementation

uses
  DelphiDoom.Wad.Dll.ClientCheck, DelphiDoom.Wad.Dll.ClientSource,
  DelphiDoom.Wad.Dll.ClientDirectory, DelphiDoom.Wad.Dll.ClientBuilder;

{ TWadDllClient }

constructor TWadDllClient.Create(const ADll: IWadDll);
begin
  inherited Create;
  if ADll = nil then
    raise EArgumentNilException.Create('ADll');
  FDll := ADll;
end;

function TWadDllClient.OpenPath(const APath: string): IWadSource;
var
  LPath: UTF8String;
  LSource: IWadDllSource;
begin
  LPath := UTF8String(APath);
  TWadDllClientCheck.Check(FDll, FDll.OpenPath(PAnsiChar(LPath), LSource));
  Result := TWadDllClientSource.Create(FDll, LSource);
end;

function TWadDllClient.OpenBytes(const AName: string; const ABytes: TBytes): IWadSource;
var
  LName: UTF8String;
  LSource: IWadDllSource;
begin
  LName := UTF8String(AName);
  if Length(ABytes) = 0 then
    raise EWadException.CreateFmt('%s is empty', [AName]);
  TWadDllClientCheck.Check(FDll, FDll.OpenMemory(PAnsiChar(LName), @ABytes[0], Cardinal(Length(ABytes)),
    LSource));
  Result := TWadDllClientSource.Create(FDll, LSource);
end;

function TWadDllClient.CreateDirectory: IWadDirectory;
var
  LDirectory: IWadDllDirectory;
begin
  TWadDllClientCheck.Check(FDll, FDll.CreateDirectory(LDirectory));
  Result := TWadDllClientDirectory.Create(FDll, LDirectory);
end;

function TWadDllClient.CreateFinder(const ADirectory: IWadDirectory): IWadFinder;
begin
  if not Supports(ADirectory, IWadFinder, Result) then
    raise EWadException.Create('The directory does not search by name');
end;

function TWadDllClient.CreateReader(const ADirectory: IWadDirectory): ILumpReader;
begin
  if not Supports(ADirectory, ILumpReader, Result) then
    raise EWadException.Create('The directory does not read lumps');
end;

function TWadDllClient.CreateBuilder(AKind: TWadKind): IWadBuilder;
var
  LBuilder: IWadDllBuilder;
begin
  TWadDllClientCheck.Check(FDll, FDll.CreateBuilder(Ord(AKind), LBuilder));
  Result := TWadDllClientBuilder.Create(FDll, LBuilder);
end;

end.
