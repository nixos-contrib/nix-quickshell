{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  xinput,
  xdotool,
}:

# The shell: the QML next to the command, which runs Quickshell on it
stdenvNoCC.mkDerivation {
  pname = "nshell";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Clock.qml
      ./Theme.qml
      ./flavours
      ./shell.qml
      ./assets
      ./modules
      ./bin/nshell
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/nshell $out/bin
    cp -r Clock.qml Theme.qml shell.qml assets modules flavours $out/share/nshell/
    install -Dm755 bin/nshell $out/bin/nshell
    wrapProgram $out/bin/nshell \
      --set-default NSHELL_PATH $out/share/nshell \
      --set-default NSHELL_BIN $out/bin/nshell \
      --prefix PATH : ${lib.makeBinPath [ quickshell xinput xdotool ]}

    runHook postInstall
  '';

  meta = {
    description = "A small desktop shell for NixOS on X11, in QML for Quickshell";
    license = lib.licenses.gpl3Plus;
    mainProgram = "nshell";
    platforms = lib.platforms.linux;
  };
}
