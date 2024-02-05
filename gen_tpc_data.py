#!/usr/bin/env python3

import duckdb
import pyarrow.parquet as pq
import os
from argparse import ArgumentParser

root_dir = os.path.dirname(os.path.realpath(__file__))
data_dir = os.path.join(root_dir, "data")


def parse_args():
    parser = ArgumentParser(description="Generate TPC-H/TPC-DS data.")
    parser.add_argument("-s", "--scale-factor", type=int, required=True)
    parser.add_argument("-d", "--dataset", default="tpch", choices=["tpch", "tpcds"])
    return parser.parse_args()


def gen_tpch(args):
    scale_factor = args.scale_factor
    output_dir = os.path.join(data_dir, "tpch", f"s{scale_factor}")
    os.makedirs(output_dir)
    print(f"Generating TPC-H data with SF={scale_factor}, output dir is {output_dir}")
    con = duckdb.connect(database=":memory:")
    con.execute("INSTALL tpch; LOAD tpch")
    con.execute(f"CALL dbgen(sf={scale_factor})")
    for table in con.execute("show tables").fetchall():
        table_name = table[0]
        parquet_path = os.path.join(output_dir, f"{table_name}.parquet")
        print(f"write to {parquet_path}")
        res = con.query(f"SELECT * FROM {table_name}")
        pq.write_table(res.to_arrow_table(), parquet_path)


if __name__ == "__main__":
    args = parse_args()

    if args.dataset == "tpch":
        gen_tpch(args)
