{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  nodejs,
}:

let
  source = builtins.fromJSON (builtins.readFile ./sources.json);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "hyai";
  version = source.version;

  src = fetchurl {
    inherit (source) url sha256;
  };

  nativeBuildInputs = [
    makeWrapper
    nodejs
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    tarballVersion=$(node -p "require('./package.json').version")
    if [ "$tarballVersion" != "${finalAttrs.version}" ]; then
      echo "hyai: the pin records ${finalAttrs.version} but the tarball contains $tarballVersion" >&2
      exit 1
    fi

    mkdir -p $out/lib/hyai
    cp -r bin src package.json $out/lib/hyai/
    cp LICENSE README.md CHANGELOG.md THIRD_PARTY_NOTICES.md $out/lib/hyai/
    chmod +x $out/lib/hyai/bin/hyai.js
    patchShebangs $out/lib/hyai/bin

    makeWrapper $out/lib/hyai/bin/hyai.js $out/bin/hyai \
      --prefix PATH : ${lib.makeBinPath [ nodejs ]}

    runHook postInstall
  '';

  meta = {
    description = "HostYourAI command line: a coding agent in your terminal on EU-served open-weights models";
    homepage = "https://hostyourai.com";
    changelog = "https://hostyourai.com/code/changelog";
    license = lib.licenses.mit;
    mainProgram = "hyai";
    platforms = lib.platforms.unix;
    sourceProvenance = [ lib.sourceTypes.fromSource ];
  };
})
