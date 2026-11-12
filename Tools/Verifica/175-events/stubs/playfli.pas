unit playfli;
// stub of the harness: the film is not played, its name is kept for the line that follows
interface
var
  LastMovie: string;
  LastOffset: integer;
function DoPlayFLI(const afname: string; const offset: integer): boolean;
implementation
function DoPlayFLI(const afname: string; const offset: integer): boolean;
begin
  LastMovie := afname;
  LastOffset := offset;
  Result := true;
end;
end.
