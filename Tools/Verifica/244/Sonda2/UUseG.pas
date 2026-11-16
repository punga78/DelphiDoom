unit UUseG;
{$IMPORTEDDATA OFF}
interface
function UseGlobalG(v: Integer): Integer;
function UseClassG(v: Integer): Integer;
implementation
uses UState;
function UseGlobalG(v: Integer): Integer;
begin
  Result := GlobalA + GlobalArr[3] + v;
  GlobalA := v;
end;
function UseClassG(v: Integer): Integer;
begin
  Result := TSt.A + TSt.Arr[3] + v;
  TSt.A := v;
end;
end.
