unit UUse;
interface
function UseGlobal(v: Integer): Integer;
function UseClass(v: Integer): Integer;
implementation
uses UState;
function UseGlobal(v: Integer): Integer;
begin
  Result := GlobalA + GlobalArr[3] + v;
  GlobalA := v;
end;
function UseClass(v: Integer): Integer;
begin
  Result := TSt.A + TSt.Arr[3] + v;
  TSt.A := v;
end;
end.
