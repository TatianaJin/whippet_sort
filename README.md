# Whippet Sort

## Get Started

### 1. Get the sources

```bash
git clone --recurse-submodules https://github.com/TatianaJin/whippet_sort.git
cd whippet_sort
```

### 2. Build the docker image

Build a docker image and launch the docker container. Normally, the `mount_path` is the `whippet_sort` folder or its parent folder.

```bash
docker build . -t <your_image_name>
./run_docker.sh <mount_path> <your_image_name>
```

### 3. Install the dependency libraries

TODO(tatiana): directly install the pre-built binaries in the `Dockerfile`.

For now, you can temporarily use `./build_third_party.sh all` to build the dependencies.

### 4. Generate data

Use the script `gen_tpc_data.py` to generate the data for benchmarking. Run `./gen_tpc_data.py -h` to see the usage.

TODO(tatiana): scripts to generate TPC-DS data in parquet format

## Contribution Guideline

### Formatting

#### Python

Use `black` as the python code formatter and `isort` for sorting imports.

#### C++

TODO(tatiana): We use `cpplint`, `clang-format`, and `clang-tidy` to lint the codes and keep good coding styles.

