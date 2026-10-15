# Prompts for a web interface password and prints its argon2id hash, the
# format hifiberry-auth stores, for hifiberry.setup.webAuth.hashedPassword.
{ writers, python3Packages }:
writers.writePython3Bin "hash-password" { libraries = [ python3Packages.argon2-cffi ]; } ''
  import getpass
  import sys

  from argon2 import PasswordHasher

  if sys.stdin.isatty():
      password = getpass.getpass("Web interface password: ")
      if password != getpass.getpass("Again: "):
          sys.exit("The passwords do not match.")
  else:
      password = sys.stdin.readline().rstrip("\n")
  if not password:
      sys.exit("The password must not be empty.")
  print(PasswordHasher().hash(password))
''
