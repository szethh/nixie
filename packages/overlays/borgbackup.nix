final: prev: {
  borgbackup = prev.borgbackup.overrideAttrs (oldAttrs: rec {
    disabledTests =
      oldAttrs.disabledTests
      ++ prev.lib.optionals prev.stdenv.isDarwin [
        # "borg.testsuite.archiver.ArchiverTestCase::test_overwrite"
        # "borg.testsuite.archiver.ArchiverTestCase::test_can_read_repo_even_if_nonce_is_deleted"
        # "borg.testsuite.archiver.ArchiverTestCase::test_sparse_file"
        # "borg.testsuite.archiver.RemoteArchiverTestCase::test_overwrite"
        "test_overwrite"
        "test_can_read_repo_even_if_nonce_is_deleted"
        "test_sparse_file"
        # https://nixos.org/manual/nixpkgs/stable/#using-pytestcheckhook
        # we can also use class names
        "XattrTestCase"
      ];
  });
}

# final: prev:
# # Within the overlay we use a recursive set, though I think we can use `final` as well.
# rec {
#   # nix-shell -p python.pkgs.borgbackup
#   python = prev.python.override {
#     # Careful, we're using a different final and prev here!
#     packageOverrides = self: super: {
#       borgbackup = super.borgbackup.overrideAttrs (oldAttrs: rec {
#         # Disable the check or add other modifications
#         doCheck = false; # Disable the check phase entirely

#         # Alternatively, modify the `postCheck` hooks as you did before
#         postCheckHooks = oldAttrs.postCheckHooks or [ ] ++ [
#           ''
#             echo "Post-check hook executing"
#             echo "Python interpreter: @pythonCheckInterpreter@"
#             echo "Pytest arguments: $args"
#           ''
#         ];

#         disabledTests =
#           oldAttrs.disabledTests or [ ]
#           ++ super.lib.optionals super.stdenv.isDarwin [
#             "ArchiverTestCase::test_overwrite"
#             "ArchiverTestCase::test_can_read_repo_even_if_nonce_is_deleted"
#             "ArchiverTestCase::test_sparse_file"
#             "RemoteArchiverTestCase::test_overwrite"
#           ];
#       });
#     };
#   };
#   # nix-shell -p pythonPackages.borgbackup
#   pythonPackages = python.pkgs;

#   # nix-shell -p borgbackup
#   borgbackup = pythonPackages.borgbackup;
# }
