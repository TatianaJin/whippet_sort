# Benchmark Goal
The objective is to compare the time costs between Arrow's parquet file reading operation and DuckDB's sorting operation.

# Dataset
The benchmark focuses on a single table, lineitem.parquet, chosen for its substantial number of rows and attributes, which aligns closely with OLAP workloads. This approach simplifies the comparison by avoiding the complexities of join operations. However, merging multiple tables into a larger dataset could be considered for future tests.

# Test Design

**Configuration**  

The benchmark includes several warm-up rounds to mitigate the impact of cold starts. Tests are repeated a specified number of times (controlled by a configurable variable), and results are determined by calculating the average time taken. This method was validated through preliminary experiments, showing the average time typically falls around the 50th percentile. Median times are also recorded and available for reference.

**Configurable Parameters**

| Parameter | Description | Default Value |
| --------- | ----------- | -------------- |
| -s,--scale| TPCH scale  |  1        |
| -w,--wamup | Number of warmup rounds| 2|
| -i,--iterations| Number of iterations per test| 20 |
| -f,--output | Output file name for benchmark | duckdb_bench_res_{scale}.json|

## Arrow Read

Following code is used for parquet reading time measurement.

```
def arrow_read(file_name):
    parquet_table = pq.read_table(file_name)
    return parquet_table
```

## DuckDB Sort

Following code is used for duckdb sorting measurement:

```
def duckdb_sort(sort_query, conn):
    res = conn.execute(sort_query)
    return res
```
An in-memory connection is utilized for DuckDB to preclude I/O overhead, and the table is preloaded accordingly. Input queries are prepared in advance.

## Prepared Query

Sorting tests are conducted based on number, string, and mixed criteria. Sorting keys vary from 1 to 4 to assess the impact of additional sorting keys. The selection of attributes for sorting, especially for multiple key scenarios (e.g., `ORDER BY A, B`), is designed to ensure meaningful sorting by choosing attributes with many repeated values for A to necessitate sorting on B. Attributes are selected based on the description found in [TPCH Standard Specification](https://www.tpc.org/tpc_documents_current_versions/pdf/tpc-h_v2.17.1.pdf).

# Current Result (warmup = 2,iteration = 100, scale = 1)

The benchmark, with parameters set to `warmup = 2`, `iteration = 100`, and `scale = 1`, demonstrates that parquet reading consumes a significant portion of time compared to DuckDB sorting. Although this ratio decreases as the number of sorting keys increases, the minimum observed ratio of Read/Sort time is still substantial at 11%, with most scenarios showing a ratio above 30%. Partial tests conducted on a `scale = 2` dataset yielded comparable results. An additional experiment, measuring the time DuckDB takes to import a parquet file using `CREATE TABLE test AS SELECT * FROM 'filename'`, showed times closely aligned with Arrow's reading performance.