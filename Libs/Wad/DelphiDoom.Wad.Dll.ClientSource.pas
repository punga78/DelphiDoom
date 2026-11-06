{******************************************************************************}
{                                                                              }
{  DelphiDoom: WAD library - a source of the DLL seen as IWadSource            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Wad.Dll.ClientSource;

interface

uses
  System.SysUtils, DelphiDoom.Wad.Types, DelphiDoom.Wad.Intf, DelphiDoom.Wad.Dll.Intf;

type
  /// <summary>
  ///   IWadSource on top of an IWadDllSource: the entries are read from the DLL when the
  ///   object is made; the bytes of a lump when they are asked for
  /// </summary>
  TWadDllClientSource = class(TInterfacedObject, IWadSource)
  private
    FDll: IWadDll;
    FSource: IWadDllSource;
    FName: string;
    FEntries: TArray<TWadEntry>;
  public
    constructor Create(const ADll: IWadDll; const ASource: IWadDllSource);
    /// <summary>The object of the DLL behind this one</summary>
    property DllSource: IWadDllSource read FSource;
    function GetName: string;
    function GetKind: TWadSourceKind;
    function GetCount: Integer;
    function GetEntry(AIndex: Integer): TWadEntry;
    function ReadEntry(AIndex: Integer): TBytes;
    procedure ReadEntryInto(AIndex: Integer; ADestination: Pointer);
  end;

implementation

uses
  DelphiDoom.Wad.Dll.ClientCheck;

{ TWadDllClientSource }

constructor TWadDllClientSource.Create(const ADll: IWadDll; const ASource: IWadDllSource);
var
  LIndex: Integer;
begin
  inherited Create;
  FDll := ADll;
  FSource := ASource;
  FName := TWadDllClientCheck.Text(FDll,
    function(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer
    begin
      Result := FSource.GetName(ABuffer, ABufferSize, ALength);
    end);
  SetLength(FEntries, FSource.GetCount);
  for LIndex := 0 to High(FEntries) do
  begin
    FEntries[LIndex].Name := TWadDllClientCheck.Text(FDll,
      function(ABuffer: PAnsiChar; ABufferSize: Cardinal; out ALength: Cardinal): Integer
      begin
        Result := FSource.GetEntryName(LIndex, ABuffer, ABufferSize, ALength);
      end);
    TWadDllClientCheck.Check(FDll, FSource.GetEntryInfo(LIndex, FEntries[LIndex].Offset,
      FEntries[LIndex].Size));
  end;
end;

function TWadDllClientSource.GetName: string;
begin
  Result := FName;
end;

function TWadDllClientSource.GetKind: TWadSourceKind;
begin
  Result := TWadSourceKind(FSource.GetKind);
end;

function TWadDllClientSource.GetCount: Integer;
begin
  Result := Length(FEntries);
end;

function TWadDllClientSource.GetEntry(AIndex: Integer): TWadEntry;
begin
  if (AIndex < 0) or (AIndex >= Length(FEntries)) then
    raise EWadException.CreateFmt('Lump %d does not exist in %s (it has %d)',
      [AIndex, FName, Length(FEntries)]);
  Result := FEntries[AIndex];
end;

function TWadDllClientSource.ReadEntry(AIndex: Integer): TBytes;
begin
  SetLength(Result, GetEntry(AIndex).Size);
  if Length(Result) > 0 then
    ReadEntryInto(AIndex, @Result[0]);
end;

procedure TWadDllClientSource.ReadEntryInto(AIndex: Integer; ADestination: Pointer);
begin
  TWadDllClientCheck.Check(FDll,
    FSource.ReadEntry(AIndex, ADestination, Cardinal(GetEntry(AIndex).Size)));
end;

end.
