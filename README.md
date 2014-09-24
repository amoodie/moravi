moravi
======

MOodie RApid VIzualization; bash script using The Generic Mapping Tools to quickly plot 3arc second SRTM data

This script is to be placed in the same directory as that which contains the raw unextracted and unexplored downloaded data -- i.e. exactly as it was downloaded. For example, if you want the complete pasted grid file in folder `your_dir`, then the file structure should look like:
 
```
+-- your_dir/
|   +-- moravi.sh
|   +-- Bulk Order *****/
```

Where `Bulk Order *****/` is the folder downloaded from Earth Explorer and Bulk Download Application.

Running:

To run the script, simply place it as described above and:
1. `cd` into `your_dir`
2. make the file executable with `chmod 755 moravi.sh`
3. and run with `./moravi.sh`
