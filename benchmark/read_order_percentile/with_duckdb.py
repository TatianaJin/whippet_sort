#!/usr/bin/env python3
import json
import os
import time
from argparse import ArgumentParser

import duckdb
import matplotlib.pyplot as plt
import numpy as np
import pyarrow.parquet as pq

workdir = "/workspace/whippet_docker"


def parse_args():
    parser = ArgumentParser(
        description="Calculate the proportion of the time required \
                     to read a Parquet file to the time required for sorting"
    )
    parser.add_argument("-s", "--scale", type=int, choices=range(1, 8), default=1)
    parser.add_argument("-w", "--warmup", type=int, default=2)
    parser.add_argument("-i", "--iterations", type=int, default=20)
    parser.add_argument("-f", "--output", type=str, default=None)
    args = parser.parse_args()
    # Set default output filename if not specified
    if args.output is None:
        args.output = f"duckdb_bench_res_{args.scale}.json"
    return args


# Append the percentage of the average time to the result dictionary
def add_percentage(read_avg, sort_res):
    for res in sort_res:
        res["Read/Sort Ratio"] = read_avg / res["avg"]
    return


# Calculate the percentile of the value in the array
def _calculate_percentile(arr, value):
    arr.sort()
    index = np.searchsorted(arr, value)
    percentile = index / len(arr)
    return percentile


# Benchmark code for arrow read
def arrow_read(file_name):
    parquet_table = pq.read_table(file_name)
    return parquet_table


# Prepare for duckdb table, eliminate the IO overhead
def duckdb_preapre(scale, table_src_name):
    # Check existence of the table
    file_path = f"{workdir}/data/tpch/s{scale}/{table_src_name}"
    if not os.path.exists(file_path):
        print(f"File {file_path} does not exist.")
        exit(-1)
    con = duckdb.connect()
    query = f"CREATE TABLE lineitem AS SELECT * FROM read_parquet('{file_path}')"
    con.execute(query)
    return con


# Benchmark code for duckdb sort
def duckdb_sort(sort_query, conn):
    res = conn.execute(sort_query)
    return res


def benchmark(discription, attr_num, benchmark_func, warmup, iterations, *args):
    # Warmup phase
    for i in range(warmup):
        benchmark_func(*args)

    times = []
    for i in range(iterations):
        start = time.perf_counter() * 1000
        res = benchmark_func(*args)
        end = time.perf_counter() * 1000
        times.append(end - start)

    times = np.array(times)
    min_time = np.min(times)
    max_time = np.max(times)
    avg_time = np.mean(times)
    median_time = np.median(times)
    std_time = np.std(times)

    # Calculate the percentiles for the average
    avg_percentile = _calculate_percentile(times, median_time)

    print(f"Benchmark {discription} finished. Avg time: {avg_time} ms.")
    # Return a dictionary
    return {
        "Description": discription,
        "Number of Attributes": attr_num,
        "min": min_time,
        "max": max_time,
        "avg": avg_time,
        "median": median_time,
        "std": std_time,
        "avg_percentile": avg_percentile,
    }


def mix_bench(warmup, itr, con):
    query_two_items = "SELECT * FROM lineitem ORDER BY L_LINENUMBER,L_SHIPINSTRUCT"
    query_three_items = (
        "SELECT * FROM lineitem ORDER BY L_LINENUMBER,L_SHIPINSTRUCT,L_SHIPMODE"
    )
    query_four_items = "SELECT * FROM lineitem ORDER BY L_LINENUMBER,L_SHIPINSTRUCT,L_SHIPMODE,L_DISCOUNT"
    res_2 = benchmark(
        "Mix Test With 1 number attribute and 1 string attribute",
        2,
        duckdb_sort,
        warmup,
        itr,
        query_two_items,
        con,
    )
    res_3 = benchmark(
        "Mix Test With 1 number attribute and 2 string attribute",
        3,
        duckdb_sort,
        warmup,
        itr,
        query_three_items,
        con,
    )
    res_4 = benchmark(
        "Mix Test With 2 number attribute and 2 string attribute",
        4,
        duckdb_sort,
        warmup,
        itr,
        query_four_items,
        con,
    )
    return [res_2, res_3, res_4]


def number_bench(warmup, itr, con):
    query_one_item_1 = "SELECT * FROM lineitem ORDER BY L_SUPPKEY"
    query_two_item = "SELECT * FROM lineitem ORDER BY L_LINENUMBER, L_RECEIPTDATE"
    query_three_item = "SELECT * FROM lineitem ORDER BY L_LINENUMBER, L_DISCOUNT, L_TAX"
    query_four_item = "SELECT * FROM lineitem ORDER BY L_LINENUMBER, L_DISCOUNT, L_QUANTITY, L_EXTENDEDPRICE"
    res1 = benchmark(
        "Number Test With 1 attribute",
        1,
        duckdb_sort,
        warmup,
        itr,
        query_one_item_1,
        con,
    )
    res2 = benchmark(
        "Number Test With 2 attributes",
        2,
        duckdb_sort,
        warmup,
        itr,
        query_two_item,
        con,
    )
    res3 = benchmark(
        "Number Test With 3 attributes",
        3,
        duckdb_sort,
        warmup,
        itr,
        query_three_item,
        con,
    )
    res4 = benchmark(
        "Number Test With 4 attributes",
        4,
        duckdb_sort,
        warmup,
        itr,
        query_four_item,
        con,
    )
    return [res1, res2, res3, res4]


def string_bench(warmup, itr, con):
    query_one_item_fixed = "SELECT * FROM lineitem ORDER BY L_SHIPMODE"
    query_two_item = "SELECT * FROM lineitem ORDER BY L_SHIPMODE, L_SHIPINSTRUCT"
    query_three_item = (
        "SELECT * FROM lineitem ORDER BY L_SHIPMODE, L_SHIPINSTRUCT, L_RETURNFLAG"
    )
    query_four_item = "SELECT * FROM lineitem ORDER BY L_SHIPMODE, L_SHIPINSTRUCT, L_RETURNFLAG, L_COMMENT"
    res1 = benchmark(
        "String Test With 1 attribute",
        1,
        duckdb_sort,
        warmup,
        itr,
        query_one_item_fixed,
        con,
    )
    res2 = benchmark(
        "String Test With 2 attributes",
        2,
        duckdb_sort,
        warmup,
        itr,
        query_two_item,
        con,
    )
    res3 = benchmark(
        "String Test With 3 attributes",
        3,
        duckdb_sort,
        warmup,
        itr,
        query_three_item,
        con,
    )
    res4 = benchmark(
        "String Test With 4 attributes",
        4,
        duckdb_sort,
        warmup,
        itr,
        query_four_item,
        con,
    )
    return [res1, res2, res3, res4]


# Draw graphs
def plot_res(res, file_name=None):
    # Check existence of ratio attribute
    for r in res:
        if "Read/Sort Ratio" not in r:
            print(
                "The result does not contain the ratio attribute,use add_percentage() first."
            )
            return
    attr_counts = []
    ratios = []
    # Clear previous plot
    plt.clf()
    for r in res:
        attr_counts.append(r["Number of Attributes"])
        ratios.append(r["Read/Sort Ratio"])

    plt.bar(attr_counts, ratios)
    for i in range(len(attr_counts)):
        plt.text(
            attr_counts[i],
            ratios[i],
            f"{ratios[i]:.2f}",
            ha="center",
            va="bottom",
            fontsize=7,
        )

    plt.xlabel("Number of Attributes")
    plt.ylabel("Read/Sort Ratio")
    if file_name is not None:
        plt.savefig(file_name)


if __name__ == "__main__":
    args = parse_args()
    scale = args.scale
    data_dir = f"{workdir}/data/tpch/s{scale}"
    # Check the existence of the data directory
    if not os.path.exists(data_dir):
        print(
            f"Data directory {data_dir} does not exist.Use gen_tpc_data.py to generate the data first."
        )
        exit(-1)
    # This table contains most records and attributes
    file_name = f"{data_dir}/lineitem.parquet"
    output_file = args.output
    con = duckdb_preapre(scale, table_src_name="lineitem.parquet")
    # Increase priority
    os.nice(-20)

    # Benchmarks
    read_time = benchmark(
        "Arrow Read Benchmark", 0, arrow_read, args.warmup, args.iterations, file_name
    )
    number_res = number_bench(args.warmup, args.iterations, con)
    string_res = string_bench(args.warmup, args.iterations, con)
    mix_res = mix_bench(args.warmup, args.iterations, con)
    add_percentage(read_time["avg"], number_res)
    add_percentage(read_time["avg"], string_res)
    add_percentage(read_time["avg"], mix_res)
    # Generate plot graph
    plot_res(number_res, f"number_sort_ratio_{scale}.png")
    plot_res(string_res, f"string_sort_ratio_{scale}.png")
    plot_res(mix_res, f"mix_sort_ratio_{scale}.png")
    # Write the result to a json file
    with open(output_file, "w") as f:
        json.dump(
            {
                "Read Time": read_time,
                "Number Sort": number_res,
                "String Sort": string_res,
                "Mix Sort": mix_res,
            },
            f,
            indent=4,
        )
    con.close()
