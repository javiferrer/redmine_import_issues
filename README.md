redmine_import_issues
==============================

This plugin allows users to import issues and time_entries

Features
--------

* Import issues and its custom fields values
* Update issues by Issue ID or Custom Value
* Import time entries
* Create journals on updated issues
* Works with Excel and ODS formats
* Save import templates for recurring imports


Compatibility
-------------

Developed and tested on redmine 2.x


Installation
------------

* Clone https://github.com/javiferrer/redmine_import_issues.git or download zip into  **redmine_dir/plugins/** folder
```
$ git clone https://github.com/javiferrer/redmine_import_issues.git
```
* From redmine root directory, run: 
```
$ bundle install
$ rake redmine:plugins:migrate RAILS_ENV=production
```
* Restart redmine

TODO
----

* Unit tests

Licence
-------

GNU General Public License Version 2
