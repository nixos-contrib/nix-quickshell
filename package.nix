{
  lib,
  stdenvNoCC,
  makeWrapper,
  quickshell,
  xinput,
  xdotool,
  iproute2,
}:

# The shell: the QML next to the command, which runs Quickshell on it
stdenvNoCC.mkDerivation {
  pname = "nix-quickshell";
  version = "0.4.0"; # x-release-please-version

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Theme.qml
      ./palette.json
      ./shell.qml
      ./assets
      ./modules
      ./bin/nix-quickshell
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/nix-quickshell $out/bin
    cp -r Theme.qml shell.qml assets modules palette.json $out/share/nix-quickshell/
    install -Dm755 bin/nix-quickshell $out/bin/nix-quickshell
    wrapProgram $out/bin/nix-quickshell \
      --set-default NIX_QUICKSHELL_PATH $out/share/nix-quickshell \
      --set-default NIX_QUICKSHELL_BIN $out/bin/nix-quickshell \
      --prefix PATH : ${lib.makeBinPath [ quickshell xinput xdotool iproute2 ]}

    runHook postInstall
  '';

  meta = {
    description = "A small desktop shell for NixOS on X11, in QML for Quickshell";
    license = lib.licenses.gpl3Plus;
    mainProgram = "nix-quickshell";
    platforms = lib.platforms.linux;
  };
}
