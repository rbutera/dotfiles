{
  description = "Home Manager Configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, home-manager }:
    let
      system = "x86_64-linux"; # Adjust this if needed
      pkgs = import nixpkgs { inherit system; config = { allowUnfree = true; };};
    in
    {
      homeConfigurations.rai = home-manager.lib.homeManagerConfiguration {

      inherit pkgs;

        modules = [
          {
            home.username = "rai";
            home.homeDirectory = "/home/rai";
            home.stateVersion = "23.05";

            home.packages = with pkgs; [
              go
              wl-clipboard
              clipman
              ack
              aria2
              bat
              bfg-repo-cleaner
              boost
              broot
              caddy
              cairo
              ctags
              fb303
              fbthrift
              fd
              findutils
              fizz
              folly
              fzf
              fzy
              gettext
              gh
              git-filter-repo
              git-lfs
              git-secret
              glib
              glow
              gnupg
              gnutls
              gobject-introspection
              guile
              harfbuzz
              htop
              httpie
              jq
              krb5
              leptonica
              libass
              libbluray
              librsvg
              libssh2
              lua
              mkcert
              mono
              ncdu
              openssl
              p11-kit
              p7zip
              pandoc
              peco
              perl
              pyenv
              readline
              ripgrep
              todoist
              shellcheck
              sphinx
              starship
              stylua
              tesseract
              tldr
              tmux
              trash-cli
              tree
              unbound
              vapoursynth
              wangle
              tfswitch
              watchman
              libwebp
              wget
              wimlib
              wireguard-tools
              zlib
              xz
              yarn
              zsh-completions
              zsh
              virtualenv
              SDL2
              delta
              gitflow
              terraform
              postgresql
              eza
              go
              asdf-vm
              rename
              ntfs3g
              fastfetch
              fuse
              # floorp
            ];
          }
        ];
      };
    };
}
