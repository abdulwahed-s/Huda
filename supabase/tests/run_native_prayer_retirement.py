#!/usr/bin/env python3
"""Test the handoff SQL in a temporary, localhost-only PostgreSQL cluster."""
import os
from pathlib import Path
import shutil
import socket
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[2]
configured = os.environ.get("HUDA_PG_BIN")
binary = shutil.which("initdb")
PG_BIN = Path(configured) if configured else Path(binary).parent if binary else Path("/opt/homebrew/opt/postgresql/bin")


def run(name, *arguments):
    subprocess.run([str(PG_BIN / name), *map(str, arguments)], check=True)


def main():
    if not (PG_BIN / "initdb").is_file():
        raise SystemExit("Install PostgreSQL or set HUDA_PG_BIN to its bin directory.")
    with socket.socket() as available:
        available.bind(("127.0.0.1", 0))
        port = available.getsockname()[1]
    output = ROOT / "output"
    output.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(prefix="prayer-sql-", dir=output) as directory:
        cluster = Path(directory)
        data = cluster / "data"
        started = False
        try:
            run("initdb", "-D", data, "--auth=trust", "--no-locale")
            run("pg_ctl", "-D", data, "-l", cluster / "server.log", "-o",
                f"-p {port} -h 127.0.0.1 -k {cluster}", "-w", "start")
            started = True
            for file in (
                "supabase/tests/prayer_push_local_schema.sql",
                "supabase/migrations/20260826183334_reliable_prayer_push_hardening.sql",
                "supabase/migrations/20260908120000_prayer_push_generation_fencing.sql",
                "supabase/migrations/20261011023000_native_prayer_push_retirement.sql",
                "supabase/tests/native_prayer_retirement.sql",
            ):
                run("psql", "-X", "-h", "127.0.0.1", "-p", port, "-d", "postgres",
                    "-v", "ON_ERROR_STOP=1", "-f", ROOT / file)
        finally:
            if started:
                run("pg_ctl", "-D", data, "-m", "fast", "-w", "stop")


if __name__ == "__main__":
    main()
