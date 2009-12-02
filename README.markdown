# autocap

A now unmaintained but possibly still useful collection of old capistrano tasks for deploying Rails applications. Basically my capistrano junk drawer.

In Capfile

    Dir['path/to/autocap/lib/recipes/*.rb'].each { |file| load(file) }

Copyright (c) 2007 William Melody, released under the MIT license
