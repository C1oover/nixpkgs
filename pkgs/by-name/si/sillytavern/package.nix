{ lib
, buildNpmPackage
, fetchFromGitHub
, makeWrapper
, pkgs
}:

let 
wrapperScript = pkgs.writeShellScriptBin "sillytavern-wrapper" ''
  _name="sillytavern"
  _BUILDLIBPREFIX="$(dirname "$(readlink -f "$0")")/../lib/sillytavern"
  _SHAREPREFIX="$(dirname "$(readlink -f "$0")")/../share/sillytavern"
  _config_dir="$HOME/.config/$_name"
  _yellow_color_code="\33[2K\r\033[1;33m%s\033[0m\n\33[2K\r\033[1;33m%s\033[0m\n"
  export NODE_PATH="$_BUILDLIBPREFIX/node_modules"

  echo "Entering SillyTavern..."
  cd "$_SHAREPREFIX"
  echo "Starting SillyTavern..."

  ${pkgs.nodejs}/bin/node ./server.js --dataRoot $config_dir

'';

in 

buildNpmPackage rec {
  pname = "sillytavern";
  version = "1.12.0";
  src = fetchFromGitHub {
    owner = "SillyTavern";
    repo = "SillyTavern";
    rev = "${version}";
    hash = "sha256-ErTDqn/PhoempJvOIcPHTcT2jEpCJxnRbUW/4tos94M=";
  };

  npmDepsHash = "sha256-InOI5A6NuuMpadH5KIJUDPisvN2gjXxZonpo0Y/V8RA=";

  desktopFile = ./sillytavern.desktop;

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  # Heavily inspired on https://mpr.makedeb.org/pkgbase/sillytavern/git/tree/PKGBUILD

  installPhase = ''
        runHook preInstall

    # Cleanup
        rm -Rf node_modules/onnxruntime-node/bin/napi-v3/{darwin,win32}

    # Creating Directories
        mkdir -p $out/{bin,share/{${pname},doc/${pname},applications,icons/hicolor/72x72/apps},lib/${pname}}

    # doc
        cp LICENSE $out/share/doc/${pname}/license
        cp SECURITY.md $out/share/doc/${pname}/security
        mv .github/readme* $out/share/doc/${pname}/

    # Install
        install -Dm755 ${wrapperScript}/bin/* $out/bin/sillytavern
        mv node_modules $out/lib/${pname}

    # Icon and desktop file
        cp public/img/apple-icon-72x72.png $out/share/icons/hicolor/72x72/apps/${pname}.png
        install -Dm644 ${desktopFile} $out/share/applications/${pname}.desktop
        mv * $out/share/${pname}

    # Name here and at configuration folder can't be equal otherwise it will conflict and make the config folder unwritable (for the files/folder with the same name)
        mv $out/share/${pname}/public $out/share/${pname}/publicc
        mv $out/share/${pname}/default $out/share/${pname}/defaultt

        runHook postInstall
  '';

  meta = with lib; {
    description = "LLM Frontend for Power Users.";
    longDescription = ''
      SillyTavern is a user interface you can install on your computer (and Android phones) that allows you to interact with
      text generation AIs and chat/roleplay with characters you or the community create.
    '';
    downloadPage = "https://github.com/SillyTavern/SillyTavern/releases";
    homepage = "https://docs.sillytavern.app/";
    mainProgram = "sillytavern";
    license = licenses.agpl3;
    maintainers = [ maintainers.aikooo7 ];
  };
}