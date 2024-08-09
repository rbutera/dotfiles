{
  description = "Global Packages with Clipboard Manager";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs }: 
    let
      system = "x86_64-linux"; # Adjust this if needed
      pkgs = import nixpkgs {
        system = system; 
        config.allowUnfree = true;
      };
    in
    {
      defaultPackage.${system} = pkgs.buildEnv {
        name = "global-packages";
        paths = with pkgs; [
          go
          wl-clipboard  # Clipboard manager for Wayland
          clipman       # Additional clipboard manager
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
          yabridge
          yabridgectl
          fastfetch
          
        ];
      };
    };
}
