{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - a directory of the DLL seen as the library one    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.ClientDirectory;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf;

type
  /// <summary>
  ///   IWadDirectory, IWadFinder and ILumpReader on top of an IWadDllDirectory. The sources
  ///   added to it must come from the same client (TWadDllClientSource)
  /// </summary>
  TWadDllClientDirectory = class(TInterfacedObject, IWadDirectory, IWadFinder, ILumpReader)
  private
    FDll: IWadDll;
    FDirectory: IWadDllDirectory;
    FSources: TList<IWadSource>;
    function DllSourceOf(const ASource: IWadSource): IWadDllSource;
  public
    constructor Create(const ADll: IWadDll; const ADirectory: IWadDllDirectory);
    destructor Destroy; override;

    { IWadDirectory }
    function GetCount: Integer;
    function GetSourceCount: Integer;
    function GetSource(AIndex: Integer): IWadSource;
    procedure AddSource(const ASource: IWadSource);
    procedure Truncate(ASourceCount: Integer);
    procedure ReplaceSource(AIndex: Integer; const ASource: IWadSource);
    function LumpName(ALump: Integer): string;
    function LumpSize(ALump: Integer): Integer;
    function LumpOffset(ALump: Integer): Integer;
    function LumpFlags(ALump: Integer): Cardinal;
    function LumpSourceIndex(ALump: Integer): Integer;

    { IWadFinder }
    function CheckNumForName(const AName: string; AFlags: Cardinal = 0): Integer;
    function CheckFirstNumForName(const AName: string): Integer;
    function CheckNumForNameInRange(const AName: string; AFirst, ALast: Integer): Integer;
    function GetNumForName(const AName: string; AFlags: Cardinal = 0): Integer;
    function GetFirstNumForName(const AName: string): Integer;

    { ILumpReader }
    function ReadLump(ALump: Integer): TBytes;
    procedure ReadLumpInto(ALump: Integer; ADestination: Pointer);
    function TextLump(ALump: Integer): string;
  end;

implementation

uses
  DelphiDoom.Wad.Types, DelphiDoom.Wad.Dll.ClientCheck, DelphiDoom.Wad.Dll.ClientSource;

{ TWadDllClientDirectory }

constructor TWadDllClientDirectory.Create(const ADll: IWadDll; const ADirectory: IWadDllDirectory);
begin
  inherited Create;
  FDll := ADll;
  FDirectory := ADirectory;
  FSources := TList<IWadSource>.Create;
end;

destructor TWadDllClientDirectory.Destroy;
begin
  FSources.Free;
  inherited Destroy;
end;

function TWadDllClientDirectory.DllSourceOf(const ASource: IWadSource): IWadDllSource;
begin
  if ASource = nil then
    raise EWadException.Create('The source is nil');
  if not (ASource is TWadDllClientSource) then
    raise EWadException.Create('The source was not made by the WAD DLL client');
  Result := (ASource as TWadDllClientSource).DllSource;
end;

function TWadDllClientDirectory.GetCount: Integer;
begin
  Result := FDirectory.GetCount;
end;

function TWadDllClientDirectory.GetSourceCount: Integer;
begin
  Result := FDirectory.GetSourceCount;
end;

function TWadDllClientDirectory.GetSource(AIndex: Integer): IWadSource;
begin
  if (AIndex < 0) or (AIndex >= FSources.Count) then
    raise EWadException.CreateFmt('Source %d does not exist (there are %d)', [AIndex, FSources.Count]);
  Result := FSources[AIndex];
end;

procedure TWadDllClientDirectory.AddSource(const ASource: IWadSource);
begin
  TWadDllClientCheck.Check(FDll, FDirectory.AddSource(DllSourceOf(ASource)));
  FSources.Add(ASource);
end;

procedure TWadDllClientDirectory.Truncate(ASourceCount: Integer);
begin
  TWadDllClientCheck.Check(FDll, FDirectory.Truncate(ASourceCount));
  while FSources.Count > ASourceCount do
    FSources.Delete(FSources.Count - 1);
end;

procedure TWadDllClientDirectory.ReplaceSource(AIndex: Integer; const ASource: IWadSource);
begin
  TWadDllClientCheck.Check(FDll, FDirectory.ReplaceSource(AIndex, DllSourceOf(ASource)));
  FSources[AIndex] := ASource;
end;

function TWadDllClientDirectory.LumpName(ALump: Integer): string;
begin
  Result := TWadDllClientCheck.Text(FDll,
    function(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer
    begin
      Result := FDirectory.GetLumpName(ALump, ABuffer, ABufferSize, ALength);
    end);
end;

function TWadDllClientDirectory.LumpSize(ALump: Integer): Integer;
var
  LOffset, LSourceIndex: Integer;
  LFlags: Cardinal;
begin
  TWadDllClientCheck.Check(FDll, FDirectory.GetLumpInfo(ALump, LOffset, Result, LFlags, LSourceIndex));
end;

function TWadDllClientDirectory.LumpOffset(ALump: Integer): Integer;
var
  LSize, LSourceIndex: Integer;
  LFlags: Cardinal;
begin
  TWadDllClientCheck.Check(FDll, FDirectory.GetLumpInfo(ALump, Result, LSize, LFlags, LSourceIndex));
end;

function TWadDllClientDirectory.LumpFlags(ALump: Integer): Cardinal;
var
  LOffset, LSize, LSourceIndex: Integer;
begin
  TWadDllClientCheck.Check(FDll, FDirectory.GetLumpInfo(ALump, LOffset, LSize, Result, LSourceIndex));
end;

function TWadDllClientDirectory.LumpSourceIndex(ALump: Integer): Integer;
var
  LOffset, LSize: Integer;
  LFlags: Cardinal;
begin
  TWadDllClientCheck.Check(FDll, FDirectory.GetLumpInfo(ALump, LOffset, LSize, LFlags, Result));
end;

function TWadDllClientDirectory.CheckNumForName(const AName: string; AFlags: Cardinal): Integer;
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FDirectory.CheckNumForName(PAnsiChar(LName), AFlags, Result));
end;

function TWadDllClientDirectory.CheckFirstNumForName(const AName: string): Integer;
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FDirectory.CheckFirstNumForName(PAnsiChar(LName), Result));
end;

function TWadDllClientDirectory.CheckNumForNameInRange(const AName: string; AFirst,
  ALast: Integer): Integer;
var
  LName: UTF8String;
begin
  LName := UTF8String(AName);
  TWadDllClientCheck.Check(FDll, FDirectory.CheckNumForNameInRange(PAnsiChar(LName), AFirst, ALast, Result));
end;

function TWadDllClientDirectory.GetNumForName(const AName: string; AFlags: Cardinal): Integer;
begin
  Result := CheckNumForName(AName, AFlags);
  if Result = -1 then
    raise EWadException.CreateFmt('Lump "%s" not found', [AName]);
end;

function TWadDllClientDirectory.GetFirstNumForName(const AName: string): Integer;
begin
  Result := CheckFirstNumForName(AName);
  if Result = -1 then
    raise EWadException.CreateFmt('Lump "%s" not found', [AName]);
end;

function TWadDllClientDirectory.ReadLump(ALump: Integer): TBytes;
begin
  SetLength(Result, LumpSize(ALump));
  if Length(Result) > 0 then
    ReadLumpInto(ALump, @Result[0]);
end;

procedure TWadDllClientDirectory.ReadLumpInto(ALump: Integer; ADestination: Pointer);
begin
  TWadDllClientCheck.Check(FDll, FDirectory.ReadLump(ALump, ADestination, Cardinal(LumpSize(ALump))));
end;

function TWadDllClientDirectory.TextLump(ALump: Integer): string;
var
  LBytes: TBytes;
  LIndex: Integer;
begin
  LBytes := ReadLump(ALump);
  SetLength(Result, Length(LBytes));
  for LIndex := 0 to High(LBytes) do
    Result[LIndex + 1] := Char(LBytes[LIndex]);
end;

end.
