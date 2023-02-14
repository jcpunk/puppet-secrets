# Changelog

All notable changes to this project will be documented in this file.

## Release 1.2.2

**Features**

* Support facter dotted notation

## Release 1.2.1

**Features**

* Support non-legacy fact name swaps

## Release 1.2.0

**Features**

* Switched to the `binary_file` function wrapper for json serialization

## Release 1.1.1

**Features**

* Switched from 'puppet master' to 'puppet server'

## Release 1.1.0

**Features**

* Using a resource collector for notifications now

**Bugfixes**

* Filenames with `/./` in them now have that removed.

## Release 1.0.4

**Bugfixes**

* Missed a notify from 1.0.2

## Release 1.0.3

**Bugfixes**

* File accepts an Integer, so we should too

## Release 1.0.2

**Bugfixes**

* drop client notices on non-mandatory secrets.
  They were counting as "changed" resources

## Release 1.0.1

**Bugfixes**

* Fix defaults from data/common.yaml

## Release 1.0.0

**Features**

* Move secrets under /etc/puppetlabs/ by default

**Bugfixes**

* Fix typos in documentation

**Known Issues**

## Release 0.3.1

**Features**

Move to PDK

**Bugfixes**

**Known Issues**
