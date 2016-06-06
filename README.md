[![Build Status](https://travis-ci.org/sul-dlss/dor-rights-auth.svg?branch=master)](https://travis-ci.org/sul-dlss/dor-rights-auth)
[![Coverage Status](https://coveralls.io/repos/github/sul-dlss/dor-rights-auth/badge.svg?branch=master)](https://coveralls.io/github/sul-dlss/dor-rights-auth?branch=master)
[![Code Climate](https://codeclimate.com/github/sul-dlss/dor-rights-auth/badges/gpa.svg)](https://codeclimate.com/github/sul-dlss/dor-rights-auth)
[![Dependency Status](https://gemnasium.com/sul-dlss/dor-rights-auth.svg)](https://gemnasium.com/sul-dlss/dor-rights-auth)
[![Gem Version](https://badge.fury.io/rb/dor-rights-auth.svg)](https://badge.fury.io/rb/dor-rights-auth)

## DOR Rights Auth

Creates objects with the following structure after parsing rightsMetadata XML

```ruby
# Rights for an object or File
class EntityRights
  @world = Rights
  @group {
    :stanford => Rights
  }
  @agent {
    'app1' => Rights,
    'app2' => Rights
  }
  @location {
    :spec => Rights
  }
end

# Rights for the entire object, and all files
# This is the object used by apps (stacks and purl)
class Dor::RightsAuth
  @object_level = EntityRights
  @file {
    'file1' => EntityRights,
    'file2' => EntityRights
  }
end
```
