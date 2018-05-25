workflow sailfish_quant{
    File index_archive
    String lib_type
    Array[File] reads_1
    Array[File] reads_2
    String out_dir
    Int ncpu
    Boolean useVBOpt=false
    # following are mutually exclusive
    Int? numBootstraps
    Int? numGibbsSamples
    Int? memGB

    call sailfish { input:
        index_archive = index_archive,
        lib_type = lib_type,
        reads_1 = reads_1,
        reads_2 = reads_2,
        out_dir = out_dir,
        ncpu = ncpu,
        memGB = memGB,
        numBootstraps = numBootstraps,
        numGibbsSamples = numGibbsSamples,
        useVBOpt = useVBOpt
    }
}


    task sailfish {
        File index_archive
        String lib_type
        Array[File] reads_1
        Array[File] reads_2
        String out_dir
        Int ncpu
        Int? memGB
        Boolean useVBOpt
        Int? numBootstraps
        Int? numGibbsSamples

        command {
            tar -xzvf ${index_archive} 
            sailfish quant \
                ${"-i " + "sailfish_gencodeV24_k31"} \
                ${"-l " + lib_type} \
                ${"-p " + ncpu} \
                -1 ${sep=' ' reads_1} \
                -2 ${sep=' ' reads_2} \
                ${if useVBOpt then "--useVBOpt" else ""} \
                ${"--numBootstraps " + numBootstraps} \
                ${"--numGibbsSamples " + numGibbsSamples} \
                ${"-o " + out_dir}
        }

        output {
            File quants = glob("${out_dir}/*.sf")[0]
            File info = glob("${out_dir}/*.json")[0]

        }

        runtime {
            docker: "quay.io/encode-dcc/sailfish:latest"
            cpu: select_first([ncpu,4])
            memory: "${select_first([memGB,8])} GB"
        }        
    }