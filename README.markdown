# autocap

A now unmaintained but possibly still useful collection of old capistrano tasks for deploying Rails applications. Basically my capistrano junk drawer.

You might need to have the `load 'config/deploy'` line before the `Dir['vendor/plugins/*/recipes/*.rb'].each { |plugin| load(plugin) }` line in your Capfile.

Copyright (c) 2007 William Melody, released under the MIT license
