{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = [
    (pkgs.python3.withPackages (ps: with ps; [
      libvirt
    ]))
    
    # pkgs.grim
    # pkgs.ydotool
  ];
}