SCRIPT_DIR=$(
    cd $(dirname $0)/..
    pwd
)
timeout=600 options='-c ./config/solver/muval_parallel_exc_eps2_tb_ar.json -p muclp' $SCRIPT_DIR/run_bench_for_multicore.sh benchmarks/muCLP/popl2023mod/*.hes benchmarks/muCLP/popl2023mod/*/*/*.hes | LC_ALL=C sort