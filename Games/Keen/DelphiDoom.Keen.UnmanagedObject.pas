{******************************************************************************}
{                                                                              }
{  DelphiDoom: keen library - an object that implements interfaces and is freed  }
{  by its owner, not by the count of its references                             }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Keen.UnmanagedObject;

interface

type
  /// <summary>
  ///   The base of the objects that an owner creates and frees with Free and that are also given to others as
  ///   interfaces: the interfaces do not count, so a reference that goes away never frees the object
  /// </summary>
  TKeenUnmanagedObject = class(TObject, IInterface)
  protected
    function QueryInterface(const AIID: TGUID; out AObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

implementation

{ TKeenUnmanagedObject }

function TKeenUnmanagedObject.QueryInterface(const AIID: TGUID; out AObject): HResult;
begin
  if GetInterface(AIID, AObject) then
    Result := 0
  else
    Result := HResult($80004002);
end;

function TKeenUnmanagedObject._AddRef: Integer;
begin
  Result := -1;
end;

function TKeenUnmanagedObject._Release: Integer;
begin
  Result := -1;
end;

end.
