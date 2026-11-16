{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - an object that can be seen through interfaces     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.UncountedObject;

interface

type
  /// <summary>
  ///   An object with an owner that frees it: handing it out as an interface must not count
  ///   references, or the first interface that goes out of scope would free it
  /// </summary>
  TGuiUncountedObject = class(TObject, IInterface)
  protected
    function QueryInterface(const AIid: TGUID; out AObject): HResult; stdcall;
    function _AddRef: Integer; stdcall;
    function _Release: Integer; stdcall;
  end;

implementation

function TGuiUncountedObject.QueryInterface(const AIid: TGUID; out AObject): HResult;
begin
  if GetInterface(AIid, AObject) then
    Result := 0
  else
    Result := HResult($80004002);
end;

function TGuiUncountedObject._AddRef: Integer;
begin
  Result := -1;
end;

function TGuiUncountedObject._Release: Integer;
begin
  Result := -1;
end;

end.
