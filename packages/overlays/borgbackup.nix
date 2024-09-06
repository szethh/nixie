# final: prev: {
#   disabledTests =
#     prev.disabledTests
#     ++ lib.optionals stdenv.isDarwin [
#       # https://github.com/NixOS/nixpkgs/issues/267536
#       "ArchiverTestCase::test_overwrite"
#       "ArchiverTestCase::test_can_read_repo_even_if_nonce_is_deleted"
#       "ArchiverTestCase::test_sparse_file"
#       "RemoteArchiverTestCase::test_overwrite"
#     ];
# }
# { lib, stdenv, ... }:
# {
#   borgbackup = prev.borgbackup.overrideAttrs (oldAttrs: rec {
#     # Add a postCheck hook to print the interpreter and args
#     postCheckHooks = oldAttrs.postCheckHooks or [ ] ++ [
#       (''
#         # Start of the shell script to run as a hook
#                echo "Post-check hook executing"
#                echo "Python interpreter: @pythonCheckInterpreter@"
#                echo "Pytest arguments: $args"
#       '')
#     ];

#     # Ensure you merge any other disabledTests you have
#     disabledTests =
#       oldAttrs.disabledTests
#       ++ lib.optionals stdenv.isDarwin [
#         "ArchiverTestCase::test_overwrite"
#         "ArchiverTestCase::test_can_read_repo_even_if_nonce_is_deleted"
#         "ArchiverTestCase::test_sparse_file"
#         "RemoteArchiverTestCase::test_overwrite"
#       ];
#   });
# }

final: prev:
# Within the overlay we use a recursive set, though I think we can use `final` as well.
rec {
  # nix-shell -p python.pkgs.borgbackup
  python = prev.python.override {
    # Careful, we're using a different final and prev here!
    packageOverrides = final: prev: { borgbackup = prev.buildPythonPackage rec { doCheck = false; }; };
  };
  # nix-shell -p pythonPackages.borgbackup
  pythonPackages = python.pkgs;

  # nix-shell -p borgbackup
  borgbackup = pythonPackages.buildPythonPackage rec { doCheck = false; };
}
