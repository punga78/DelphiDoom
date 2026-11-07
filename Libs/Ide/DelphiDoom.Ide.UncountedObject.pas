{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - an object that can be seen through interfaces     }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.UncountedObject;

interface

type
  /// <summary>
  ///   An object with an owner that frees it: handing it out as an interface must not count
  ///   references (as TComponent does), or the first interface that goes out of scope would free it
  /// </summary>
  TIdeUncountedObject = class(TObject, IInterface)
  protected
    function QueryInterface(const AIid: TGUID; out AObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

implementation

uses
  Winapi.Windows;

{ TIdeUncountedObject }

function TIdeUncountedObject.QueryInterface(const AIid: TGUID; out AObject): HResult;
begin
  if GetInterface(AIid, AObject) then
    Result := 0
  else
    Result := E_NOINTERFACE;
end;

function TIdeUncountedObject._AddRef: Integer;
begin
  Result := -1;
end;

function TIdeUncountedObject._Release: Integer;
begin
  Result := -1;
end;

end.
