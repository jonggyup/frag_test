#!/bin/bash
#nvme1n1p1 sdc1 sde1 sdf1
startbase_dir=./results

for dev in ram0 nvme1n1p1 sdc1 sdf1 sda1
do
	case $dev in
		nvme1n1p1)
			size=1024
			base_dir=$startbase_dir/NVMe
			;;
		sdc1)
			size=400
			base_dir=$startbase_dir/SSD
			;;
		sdf1)
			size=100
			base_dir=$startbase_dir/HDD
			;;
		sda1)
			size=50
			base_dir=$startbase_dir/SDcard
			;;
		ram0)
			size=100
			base_dir=$startbase_dir/RamDisk
	esac
	mkdir $base_dir


	result_path=$base_dir/ori
	mkdir $result_path
	umount /mnt
	/home/jonggyu/mount.sh /dev/$dev /mnt 1

	dd if=/dev/zero of=/mnt/ori count=1 bs=${size}M oflag=direct,append conv=notrunc &> /dev/null
	/home/jonggyu/Scripts/cacheflush.sh

	for ra_size in 4 8 16 32 64 128 256 512 1024
	do

		/home/jonggyu/Scripts/cacheflush.sh

		./read_file /mnt/ori $ra_size > $result_path/read_perf_${ra_size}_0.result

	done

	fstrim /mnt

	rm /mnt/ori

	(perf stat fstrim /mnt) &> $result_path/trim_time_0.result


	for frag_unit in 4 8 16 32 64 128 256 512 1024 2048 4096
	do
		for distance in 4 8 16 32 64 128 256 512 1024
		do
			let counts=$size*1024/$frag_unit
			umount /mnt
			/home/jonggyu/mount.sh /dev/$dev /mnt 1
			result_path=$base_dir/$frag_unit
			mkdir $result_path

			touch /mnt/dummy
			touch 1


			while (( --counts >= 0 )); do
				dd if=/dev/zero of=/mnt/1 count=1 bs=${frag_unit}K oflag=direct,append conv=notrunc &> /dev/null
				dd if=/dev/zero of=/mnt/dummy count=1 bs=${distance}K oflag=direct,append conv=notrunc &> /dev/null
			done

			ls -alh /mnt/ > $result_path/ls.result

			hdparm --fibmap /mnt/1 > $result_path/frag.frag
			hdparm --fibmap /mnt/dummy > $result_path/dummy.frag

			/home/jonggyu/Scripts/cacheflush.sh

			for ra_size in 4 8 16 32 64 128 256 512 1024 
			do

				/home/jonggyu/Scripts/cacheflush.sh

				./read_file /mnt/1 $ra_size > $result_path/read_perf_${ra_size}_${distance}.result

			done

			fstrim /mnt

			rm /mnt/1

			(perf stat fstrim /mnt) &> $result_path/trim_time_${distance}.result
		done
	done
done
