{
  description = "a metamodeling library in Elixir";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";

  outputs = { self, nixpkgs }: let
    overlay = prev: final: rec {
      beamPackages = prev.beam.packagesWith prev.beam.interpreters.erlang_27;
      elixir = beamPackages.elixir_1_18;
      erlang = prev.erlang_27;
      hex = beamPackages.hex;
      final.mix2nix = prev.mix2nix.overrideAttrs {
        nativeBuildInputs = [ final.elixir ];
        buildInputs = [ final.erlang ];
      };
    };

    forAllSystems = nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];

    nixpkgsFor = system:
      import nixpkgs {
        inherit system;
        overlays = [overlay];
      };
    in {
    packages = forAllSystems(system: let
      pkgs = nixpkgsFor system;

      in rec {
        default = pkgs.beamPackages.buildMix {
            name = "paradigm";
            src = ./.;
            version = "0.2.0";
            buildInputs = [ pkgs.elixir ];
	    buildPhase = ''
              runHook preBuild
              export HEX_HOME=".nix-hex";
              export MIX_HOME=".nix-mix";
              mix compile --no-deps-check
              runHook postBuild
	    '';
          };
      });

    devShells = forAllSystems (system: let
      pkgs = nixpkgsFor system;
    in {
      default = pkgs.callPackage ./shell.nix {};
    });
  };
}
