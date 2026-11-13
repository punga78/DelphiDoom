Harness of ode.golden.txt and curve.golden.txt (idODE and idCurve of idlib\math, Doom 3).
Not part of the repository build: copy neo\idlib to C:\harness\ode_curve\idlib, put precompiled.h and
driver.cpp there (from the .txt files), apply the one-word change to math\Ode.cpp described in
build.ps1.txt and run it. precompiled.h differs from the other harnesses in _alloca16, which zero fills the
memory (idCurve_NaturalCubicSpline::SetupClosed builds its matrix on uninitialised memory).
Lines: "name inputs | outputs", floats as #bits. "ode" and "curve" select the part to print.
