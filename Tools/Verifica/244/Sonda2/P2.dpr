program P2;
{$APPTYPE CONSOLE}
uses UState, UUse, UUseG;
begin
  Writeln(UseGlobal(1) + UseClass(2) + UseGlobalG(3) + UseClassG(4));
end.
