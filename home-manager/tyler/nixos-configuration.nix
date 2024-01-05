{ pkgs, ... }:
{
  users.users.tyler = {
    isNormalUser = true;
    uid = 1000;
    home = "/home/tyler";
    extraGroups = [ "docker" "wheel" ];
    shell = pkgs.fish;
    hashedPassword = "$6$xIEZ74r.btymIs9V$tQ9s/j6RDK4SLxUNSZkoQFcgyhG04gtxslZ2.HajWFAqxJaI0mG3qSmW1U7L4P6D92xJFGxVoQWrLNwleQ5uS0";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIB879rBrdjSqrAT87XsDylAiZ/8TkQsiuFEaW/+JDjER tyler"
    ];
  };
}
