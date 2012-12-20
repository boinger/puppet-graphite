class graphite::install inherits graphite::params {

  anchor { 'graphite::install::begin': }
  anchor { 'graphite::install::end': }

  class { 'graphite::install::redhat':
    require => Anchor['graphite::install::begin'],
    before  => Anchor['graphite::install::end'],
  }
}