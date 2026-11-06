{******************************************************************************}
{                                                                              }
{  DelphiDoom: ACS compiler library - files kept in memory                    }
{  Copyright (C) 1995 Raven Software, Corp. (original ACC 1.10)                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Acs.MemorySourceProvider;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Acs.Intf;

type
  /// <summary>The included files are a list of names and texts: for the tests and for the tools</summary>
  TAcsMemorySourceProvider = class(TInterfacedObject, IAcsSourceProvider)
  private
    FFiles: TDictionary<string, TBytes>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>A file with this name; the name is compared without looking at the case</summary>
    procedure Add(const AName: string; const AText: TBytes);
    function TryLoad(const AName: string; out AText: TBytes): Boolean;
  end;

implementation

{ TAcsMemorySourceProvider }

constructor TAcsMemorySourceProvider.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TAcsMemorySourceProvider.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

procedure TAcsMemorySourceProvider.Add(const AName: string; const AText: TBytes);
begin
  FFiles.AddOrSetValue(LowerCase(AName), AText);
end;

function TAcsMemorySourceProvider.TryLoad(const AName: string; out AText: TBytes): Boolean;
begin
  Result := FFiles.TryGetValue(LowerCase(AName), AText);
end;

end.