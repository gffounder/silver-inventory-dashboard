import pathlib
from db import exec_sql, get_conn

def run_sql_file(path: str):
    sql = pathlib.Path(path).read_text(encoding="utf-8")
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(sql)
        conn.commit()

if __name__ == "__main__":
    run_sql_file("/app/sql/001_schema.sql")
    run_sql_file("/app/sql/002_seed_metrics.sql")
    print("DB bootstrapped.")
