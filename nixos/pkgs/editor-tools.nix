{ pkgs }:
{
  notebookKernel = pkgs.writeShellApplication {
    name = "notebook-kernel";
    text = ''exec ${pkgs.python3}/bin/python3 ${./notebook-kernel.py} "$@"'';
  };
}
