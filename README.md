# fmu.nim
The purpose of this library is enable the creation of FMU files that can be later used in many compatible simulation packages such as OpenModelica, Matlab, Dymola, ...

This library is heavily based on [fmusdk](https://github.com/qtronic/fmusdk).

## Status
This is in a very alpha stage, but right now is capable of creating `inc.so` in almost pure Nim. The it embeds that library within an FMU. The folder structure and XML file is taken from the C version.

### How to test it?
Go to the `examples` folder.

The following command will generate `inc.so` and embed it into `inc.fmu`:
```
$ nim c -r inc
```

Then test it:
```
$ fmuCheck.linux64 ./inc.fmu
```
or:
```
$ ./fmusim_me inc.fmu 5 0.1
```
> this will simulate during 5seconds using 0.1 second steps. it will create the file `results.csv`.



# Old
Just run:
```sh
$ cd src
$ ./build.sh
```

