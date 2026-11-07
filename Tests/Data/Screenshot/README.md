# Tests\Data\Screenshot

`encoders.golden.txt` ha una riga `nome=valore` per ogni caso: l'impronta FNV-1a a 64 bit del file TGA o PNG che il vecchio codice del motore (`M_DoScreenShotTGA`, `TPngFileWriter.SaveBgrx`, copiati come erano) scriveva sulle immagini sintetiche di `Tests\Source\DelphiDoom.Tests.Screenshot.Samples.pas` (software e OpenGL: `gl0`/`gl1`). Lo ha scritto un harness temporaneo, poi cancellato. Il JPG non ha un golden: il codificatore cambia (il vecchio passava dal `jpeg` della VCL), i test dichiarano una tolleranza.
