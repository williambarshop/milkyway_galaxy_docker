rm -rf build_dir ;
mkdir build_dir ;
cp * build_dir ;
now=$(date);
#cp Dockerfile build_dir/Dockerfile ;
sed -i "s/commit_rev/$now/g" build_dir/Dockerfile ;
sed -i "s/CI_job_ID/$now/g" build_dir/Dockerfile ;
sed -i "s/DATE-REPLACE/$now/g" build_dir/Dockerfile ;

sudo docker build -t wbarshop/milkyway_galaxy:linux build_dir/ --no-cache=false ;
rm -rf build_dir
