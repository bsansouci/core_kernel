// Hack taken from http://krasimirtsonev.com/blog/article/Fun-playing-with-npm-dependencies-and-postinstall-script
var deps = ['OcamlCppo'], index = 0;
(function doWeHaveAllDeps() {
  if(index === deps.length) {
    var cppo = require('OcamlCppo');
    cppo('-n', 'src/core_int63.ml', '-o', 'src/core_int63.ml');
    cppo('-n', 'src/core_int63.mli', '-o', 'src/core_int63.mli');
    cppo('-n', 'src/core_random.ml', '-o', 'src/core_random.ml');
    cppo('-n', 'src/pool.ml', '-o', 'src/pool.ml');
    cppo('-n', 'src/pow_overflow_bounds.ml', '-o', 'src/pow_overflow_bounds.ml');
    cppo('-n', 'src/float.ml', '-o', 'src/float.ml');
    cppo('-n', 'src/time_ns.ml', '-o', 'src/time_ns.ml');
    cppo('-n', 'src/bigstring.ml', '-o', 'src/bigstring.ml');
    cppo('-n', 'src/binary_packing.ml', '-o', 'src/binary_packing.ml');
    return;
  } else if(isModuleExists(deps[index])) {
    index += 1;
    doWeHaveAllDeps();
  } else {
    setTimeout(doWeHaveAllDeps, 500);
  }
})();

function isModuleExists( name ) {
  try { return !!require.resolve(name); }
  catch(e) { return false }
}
