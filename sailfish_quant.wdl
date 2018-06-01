workflow sailfish_quant{
    File index_archive
    String index_archive_dirname
    String lib_type
    File reads_1
    File reads_2
    String out_dir
    Int? ncpu
    Boolean useVBOpt=false
    # following two are mutually exclusive
    Int? numBootstraps
    Int? numGibbsSamples
    Int? memGB
    String? sailfish_disks


    call unzip_reads { input:
        reads_1 = reads_1,
        reads_2 = reads_2
    }
    call sailfish { input:
        index_archive = index_archive,
        index_archive_dirname = index_archive_dirname,
        lib_type = lib_type,
        read_1 = unzip_reads.R1,
        read_2 = unzip_reads.R2,
        out_dir = out_dir,
        ncpu = ncpu,
        memGB = memGB,
        numBootstraps = numBootstraps,
        numGibbsSamples = numGibbsSamples,
        useVBOpt = useVBOpt,
        sailfish_disks = sailfish_disks
    }
}


    task sailfish {
        File index_archive
        String index_archive_dirname
        String lib_type
        File read_1
        File read_2
        String out_dir
        Int? ncpu
        Int? memGB
        Boolean useVBOpt
        Int? numBootstraps
        Int? numGibbsSamples
        String? sailfish_disks

        command {
            tar -xzvf ${index_archive} 
            sailfish quant \
                ${"-i " + index_archive_dirname} \
                ${"-l " + lib_type} \
                ${"-p " + ncpu} \
                -1 ${read_1} \
                -2 ${read_2} \
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
            disks: select_first([sailfish_disks, "local-disk 100 HDD"])
        }        
    }

    task unzip_reads {
        File reads_1
        File reads_2

        command {
            pigz -p 8 -cd ${reads_1} > R1.fastq
            pigz -p 8 -cd ${reads_2} > R2.fastq
        }

        output {
            File R1 = glob("R1.fastq")[0]
            File R2 = glob("R2.fastq")[0]
        }

        runtime {
        docker: "quay.io/encode-dcc/ubuntu_with_pigz:latest"
        cpu: 8
        memory: "52 GB"
        disks: "local-disk 200 SSD"
        }
    }